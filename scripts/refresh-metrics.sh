#!/usr/bin/env bash
# Runs every metrics query in docs/METRICS.md and writes one snapshot file for the Favorly Metrics dashboard.
# Each query is the ```sql block after a `<!-- dataset: <id> -->` line; the id names the dashboard's source.
# The queries only read. Against the hosted project they go through the Management API with your
# `supabase login` session (free on any plan); no database password is needed.
#
# Usage: scripts/refresh-metrics.sh [--local] [--out FILE]
#   --local  Query the local Supabase stack instead of the hosted project (for trying a new query)
#   --out    Where to write the snapshot (default: build/metrics/favorly-metrics.json, git-ignored)
#
# Then ask Claude to "refresh the metrics dashboard": it uploads the file and updates the page.
set -euo pipefail

cd "$(dirname "$0")/.."

target="--linked"
out="build/metrics/favorly-metrics.json"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --local) target="--local"; shift ;;
        --out) out="$2"; shift 2 ;;
        -h|--help) sed -n '2,11p' "$0"; exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

command -v supabase >/dev/null || { echo "Install the Supabase CLI first: brew install supabase/tap/supabase" >&2; exit 1; }
command -v python3 >/dev/null || { echo "python3 is required" >&2; exit 1; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# Split the doc into one file per dataset.
python3 -I - docs/METRICS.md "$work" <<'EOF'
import re, sys, pathlib
doc, work = pathlib.Path(sys.argv[1]).read_text(), pathlib.Path(sys.argv[2])
blocks = re.findall(r"<!-- dataset: ([a-z0-9-]+) -->\n```sql\n(.*?)\n```", doc, re.S)
if not blocks:
    sys.exit("No <!-- dataset: id --> blocks found in docs/METRICS.md")
for name, sql in blocks:
    (work / f"{name}.sql").write_text(sql + "\n")
print(f"{len(blocks)} queries", file=sys.stderr)
EOF

failed=0
for sql in "$work"/*.sql; do
    name=$(basename "$sql" .sql)
    if (cd backend && supabase db query "$target" --output-format json -f "$sql") >"$work/$name.json" 2>"$work/$name.err"; then
        echo "ok      $name" >&2
    else
        echo "FAILED  $name: $(grep -v -E 'new version|recommend updating|Initialising' "$work/$name.err" | head -n 3)" >&2
        rm -f "$work/$name.json"
        failed=$((failed + 1))
    fi
done

mkdir -p "$(dirname "$out")"
python3 -I - "$work" "$out" "$target" <<'EOF'
import datetime, json, re, sys, pathlib
work, out, target = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2]), sys.argv[3]
at = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%MZ")
where = "Hosted Supabase project favorly" if target == "--linked" else "Local Supabase stack"
number = re.compile(r"^-?\d+(\.\d+)?$")

def typed(value):
    # The API returns numeric columns as text; counts and rates become numbers again.
    if isinstance(value, str) and number.match(value):
        return float(value) if "." in value else int(value)
    return value

snapshot = {"snapshot": {"rows": [{"ran_at": at, "ran_on": where}], "meta": []}}
for result in sorted(work.glob("*.json")):
    name = result.stem
    rows = [{k: typed(v) for k, v in row.items()} for row in json.loads(result.read_text())["rows"]]
    snapshot[name] = {"rows": rows, "meta": [
        {"label": "Query", "value": (work / f"{name}.sql").read_text().strip(), "type": "code", "lang": "sql"},
        {"label": "Ran on", "value": f"{where}, SQL from docs/METRICS.md"},
        {"label": "Ran at", "value": at},
    ]}
out.write_text(json.dumps(snapshot))
print(f"Wrote {out} ({len(snapshot) - 1} datasets, {at})", file=sys.stderr)
EOF

if [[ $failed -gt 0 ]]; then
    echo "$failed queries failed and are left out of the snapshot." >&2
    exit 1
fi

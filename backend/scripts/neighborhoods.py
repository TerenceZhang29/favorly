#!/usr/bin/env python3
"""Writes the migration that loads NYC's neighborhood boundaries (phase 4G, "Verified neighborhood").

The source is NYC's 2020 Neighborhood Tabulation Areas from NYC Open Data (dataset 9nt8-h7nd). Their names
combine neighborhoods ("Upper East Side-Lenox Hill-Roosevelt Island"), so each is split into its parts. The
polygons are simplified so the migration stays small. Standard library only; rerunning it on the same download
writes the same file.

    python3 scripts/neighborhoods.py                 # downloads the data
    python3 scripts/neighborhoods.py nta.geojson     # or reads a saved copy

Run from backend/. It prints every area with its names, for a person to read once.
"""

import json
import re
import sys
import urllib.request

SOURCE = "https://data.cityofnewyork.us/resource/9nt8-h7nd.geojson?$limit=400"
OUTPUT = "supabase/migrations/20261104000010_neighborhood_data.sql"

# Names that really contain a hyphen, so they are not split.
HYPHENATED = ["Bedford-Stuyvesant", "Co-op City", "Green-Wood Cemetery"]
# NTA types left out: 5 is Rikers Island (a jail), 7 cemeteries.
SKIPPED_TYPES = {"5", "7"}
# About 20 m, in degrees of latitude.
TOLERANCE = 0.0002
DECIMALS = 5


def split_name(name):
    """'Upper East Side-Lenox Hill-Roosevelt Island' -> the three names; 'Astoria (North)' -> 'Astoria'."""
    protected = name
    for index, kept in enumerate(HYPHENATED):
        protected = protected.replace(kept, f"\0{index}\0")
    parts = []
    for part in protected.split("-"):
        for index, kept in enumerate(HYPHENATED):
            part = part.replace(f"\0{index}\0", kept)
        part = re.sub(r"\s*\([^)]*\)", "", part).strip()
        if part and part not in parts:
            parts.append(part)
    return parts


def distance_to_segment(point, start, end):
    (x, y), (x1, y1), (x2, y2) = point, start, end
    dx, dy = x2 - x1, y2 - y1
    if dx == 0 and dy == 0:
        return ((x - x1) ** 2 + (y - y1) ** 2) ** 0.5
    t = max(0.0, min(1.0, ((x - x1) * dx + (y - y1) * dy) / (dx * dx + dy * dy)))
    return ((x - x1 - t * dx) ** 2 + (y - y1 - t * dy) ** 2) ** 0.5


def simplify(points):
    """Douglas-Peucker, without recursion."""
    keep = [False] * len(points)
    keep[0] = keep[-1] = True
    stack = [(0, len(points) - 1)]
    while stack:
        first, last = stack.pop()
        farthest, index = 0.0, None
        for i in range(first + 1, last):
            d = distance_to_segment(points[i], points[first], points[last])
            if d > farthest:
                farthest, index = d, i
        if index is not None and farthest > TOLERANCE:
            keep[index] = True
            stack += [(first, index), (index, last)]
    return [p for p, k in zip(points, keep) if k]


def simplify_ring(ring):
    ring = simplify([(round(x, DECIMALS), round(y, DECIMALS)) for x, y in ring])
    return [list(p) for p in ring] if len(ring) >= 4 else None


def simplify_geometry(geometry):
    polygons = geometry["coordinates"] if geometry["type"] == "MultiPolygon" else [geometry["coordinates"]]
    result = []
    for polygon in polygons:
        outer = simplify_ring(polygon[0])
        if outer is None:
            continue  # a sliver smaller than the tolerance
        holes = [h for h in (simplify_ring(r) for r in polygon[1:]) if h is not None]
        result.append([outer] + holes)
    return {"type": "MultiPolygon", "coordinates": result}


def sql_text(value):
    return "'" + value.replace("'", "''") + "'"


def main():
    if len(sys.argv) > 1:
        with open(sys.argv[1], encoding="utf-8") as file:
            data = json.load(file)
    else:
        with urllib.request.urlopen(SOURCE) as response:
            data = json.load(response)

    features = sorted(data["features"], key=lambda f: f["properties"]["nta2020"])
    areas, names = [], []
    for feature in features:
        props = feature["properties"]
        if props["ntatype"] in SKIPPED_TYPES:
            continue
        geometry = json.dumps(simplify_geometry(feature["geometry"]), separators=(",", ":"))
        areas.append(
            f"({sql_text(props['nta2020'])}, {sql_text(props['boroname'])}, {int(props['ntatype'])}, "
            f"extensions.st_geomfromgeojson({sql_text(geometry)})::extensions.geography)"
        )
        parts = split_name(props["ntaname"])
        print(f"{props['nta2020']}  {props['ntaname']}  ->  {' | '.join(parts)}")
        names += [f"({sql_text(props['nta2020'])}, {sql_text(part)}, {i})" for i, part in enumerate(parts)]

    with open(OUTPUT, "w", encoding="utf-8") as file:
        file.write(
            "-- NYC's 2020 Neighborhood Tabulation Areas, from NYC Open Data (dataset 9nt8-h7nd), with their names\n"
            "-- split into neighborhoods. Written by backend/scripts/neighborhoods.py; edit the script, not this file.\n\n"
            "insert into private.neighborhood_areas (nta_code, borough, kind, area) values\n"
            + ",\n".join(areas)
            + ";\n\ninsert into private.neighborhood_names (nta_code, name, position) values\n"
            + ",\n".join(names)
            + ";\n"
        )
    print(f"{len(areas)} areas, {len(names)} names -> {OUTPUT}", file=sys.stderr)


if __name__ == "__main__":
    main()

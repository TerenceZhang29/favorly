import FavorlyCore

extension ReportReason {
    var title: String {
        switch self {
        case .spam: "Spam or a scam"
        case .inappropriate: "Offensive or inappropriate"
        case .unsafe: "Unsafe or threatening"
        case .other: "Something else"
        }
    }
}

import Foundation

public enum PreflightResult: Equatable, Sendable {
    case ready
    case warning(String)
    case error(String)

    public var isReady: Bool {
        if case .ready = self { return true }
        return false
    }

    public var message: String? {
        switch self {
        case .ready:
            return nil
        case .warning(let msg), .error(let msg):
            return msg
        }
    }
}

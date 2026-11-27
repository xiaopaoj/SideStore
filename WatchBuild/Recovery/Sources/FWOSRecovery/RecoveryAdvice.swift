import Foundation

/// Stable advice only. Never include account, device or pairing material in UI.
public enum FWOSRecoveryAdvice: String, Sendable {
    case unlockPhone, network, pairing, unknown

    public static func classify(message: String) -> Self {
        let value = message.lowercased()
        // Apple wraps temporary lock errors as RemotePairing errors too.
        if value.contains("fw_unlock_required") || value.contains("device has not been unlocked recently") ||
            (value.contains("com.apple.dt.remotepairingerror") && value.contains("1016")) {
            return .unlockPhone
        }
        if value.contains("pairverifyfailed") || value.contains("invalidhostid") ||
            value.contains("invalid pairing file") { return .pairing }
        if value.contains("connection refused") || value.contains("network is unreachable") ||
            value.contains("timed out") { return .network }
        return .unknown
    }

    public var instruction: String {
        switch self {
        case .unlockPhone:
            return "FW_UNLOCK_REQUIRED: iPhoneのロックをパスコードで解除し、SideStoreを開いたまま再試行してください。ペアリングファイルは削除しないでください。"
        case .network:
            return "Wi-FiとLocalDevVPNの接続を確認し、ロック解除後に再試行してください。改善しなければ接続設定とRemote Pairingのポートを確認してください。"
        case .pairing:
            return "ペアリングの確認に失敗しました。まずロック解除とVPN接続を確認してください。続く場合はSettingsのPairing Fileで新しいRemote Pairingファイルを読み込みます。Fairwayの削除は不要です。"
        case .unknown:
            return "接続を確認できませんでした。ロック解除とVPN接続を確認し、Health Checkとエラーログで原因を確認してください。現時点ではペアリング無効と断定できません。"
        }
    }

    public static func osChanged(previous: String?, current: String) -> Bool {
        guard let previous else { return false }
        return previous != current
    }
}

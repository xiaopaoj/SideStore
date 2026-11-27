// Personal experimental build; not an official SideStore release.
import SwiftUI
import SideSign

enum WatchSupportSettings {
    static let udidKey = "FairwayWatchSupportUDID"
    static var udid: String { UserDefaults.standard.string(forKey: udidKey) ?? "" }

    static func prepare(host: ALTApplication, hostProfile: ALTProvisioningProfile, certificate: ALTCertificate) async throws -> [String: ALTProvisioningProfile] {
        let watches = try WatchBundleSupport.applications(in: host)
        guard !watches.isEmpty else { return [:] }
        let udid = try WatchBundleSupport.validateUDID(Self.udid)
        let session = try await AuthManager.shared.getAuthenticatedSession()
        let team = try await AuthManager.shared.getAuthenticatedTeam()
        do { try await ALTAppleAPI.shared.registerWatch(name: "Fairway Watch", udid: udid, team: team, session: session) }
        catch { throw WatchSupportError.invalid("FWDIAG_WATCH_REGISTER: Watchの登録確認で失敗しました。") }
        var profiles: [String: ALTProvisioningProfile] = [:]
        for app in host.watchSigningBundles {
            let id = try WatchBundleSupport.identifier(app.bundleIdentifier, from: host.bundleIdentifier, to: hostProfile.bundleIdentifier)
            let profile = try await ALTAppleAPI.shared.watchProfile(bundleID: id, name: "Fairway Watch", team: team, session: session)
            try WatchBundleSupport.validate(profile, bundleID: id, teamID: team.identifier, udid: udid, allowIOSFamily: true)
            guard profile.certificates.contains(where: { $0.serialNumberHex == certificate.certificate.serialNumberHex }) else {
                throw WatchSupportError.invalid("Watch用プロファイルに現在の署名証明書が含まれていません。証明書は変更せず停止しました。")
            }
            profiles[id] = profile
        }
        return profiles
    }
}

struct WatchSupportSettingsView: View {
    @State private var udid = WatchSupportSettings.udid
    @State private var message = ""
    @State private var busy = false
    @State private var probeResult = ""
    var body: some View {
        SwiftUI.Form {
            Section("Watch対応・個人用試験版") {
                Text("既存のログインと証明書を利用します。無料アカウントでのWatch実機導入は検証中です。")
                TextField("WatchのUDID", text: $udid)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                SwiftUI.Button("Watchの登録を確認") { register() }.disabled(busy)
                if busy { ProgressView() }
                if !message.isEmpty { Text(message).font(.footnote) }
            }
            Section("Watchへの直接導入") {
                Text("登録を確認したWatchのロックを解除し、ペアリングを準備してください。Watchに確認が表示された場合は承認します。")
                SwiftUI.Button("Watchペアリングを準備") { prepareWatchPairing() }.disabled(busy)
            }
            Section("Watch通信の診断") {
                Text("Watchへの通信を確認します。アプリの導入・削除やペアリングの変更は行いません。")
                SwiftUI.Button("Watch通信を診断") { probe() }.disabled(busy)
                if !probeResult.isEmpty {
                    Text(probeResult).font(.system(.footnote, design: .monospaced)).textSelection(.enabled)
                }
            }
            Section("iOS更新後の接続確認") {
                Text("OS Recovery 20261125").font(.caption).foregroundColor(.secondary)
                NavigationLink("ペアリングファイルの管理") { PairingFileManagementView() }
                Text("iPhoneのロックを解除し、Wi-FiとLocalDevVPNを接続して確認します。接続先のポートを再検出します。手動指定したポートは維持します。")
                SwiftUI.Button("iPhoneの接続を確認") { checkPhone() }.disabled(busy)
                Text("SideStoreが開けない場合は、iPhoneの設定で開発者の信頼とDeveloper Modeを確認してください。署名が期限切れなら、同じApple Account・同じアプリIDでSideStoreだけを上書きします。Fairwayは削除しません。")
                Text("本当に無効になったペアリングは再作成が必要な場合があります。SettingsのPairing Fileから新しいRemote Pairingファイルを読み込みます。")
                Text("自動更新がロック中に失敗するときは、解除後に手動Refreshしてください。OSの制限を回避して必ず自動実行できるわけではありません。")
            }
            Section("使い方") {
                Text("WindowsのWatch情報ツールで表示されたWatchのUDIDを入力してください。値はこの端末だけに保存します。")
                Text("登録後、My Appsの＋からFairwayの元の完全版IPAを選択します。Watchには専用のプロファイルを取得し、Refresh時にも再署名します。")
                Text("ペアリングの準備後は、iPhoneへの導入に続いてWatchへ直接導入します。")
            }
        }.navigationTitle("Watch対応")
    }
    private func prepareWatchPairing() {
        busy = true
        message = ""
        Task { @MainActor in
            defer { busy = false }
            do {
                let normalized = try WatchBundleSupport.validateUDID(udid)
                guard normalized.caseInsensitiveCompare(WatchSupportSettings.udid) == .orderedSame else {
                    throw WatchSupportError.invalid("先にこのWatchの登録を確認してください。")
                }
                try await ensureMinimuxerReady()
                try await minimuxer.gateway.prepareWatchPairing(expectedUDID: normalized)
                message = "Watchのペアリングを保存しました。FairwayのIPAを導入できます。"
            } catch let error as WatchSupportError {
                message = error.localizedDescription
            } catch let error as NSError where error.domain == "FairwayWatchInstall" {
                message = error.localizedDescription
            } catch {
                message = "Watchペアリングを準備できませんでした。Remote PairingとVPN接続を確認してください。"
            }
        }
    }

    private func probe() {
        busy = true; probeResult = "通信を確認中…"
        Task { @MainActor in
            defer { busy = false }
            do {
                let normalized = try WatchBundleSupport.validateUDID(udid)
                try await ensureMinimuxerReady()
                probeResult = try await minimuxer.gateway.probeWatchConnection(expectedUDID: normalized)
            } catch {
                // Do not surface arbitrary FFI messages containing pairing data.
                probeResult = "WCP_SETUP_FAILED: Remote PairingとVPN接続、WatchのUDID設定を確認してください。"
            }
        }
    }
    private func checkPhone() {
        busy = true; message = "iPhoneの接続を確認中…"
        Task { @MainActor in
            defer { busy = false }
            do {
                try await fairwayCheckPhoneConnection()
                message = "iPhoneへの接続を確認しました。次にMy AppsでSideStore、Fairwayの順にRefreshし、Watchでも起動を確認してください。"
            } catch {
                message = SideSign.FWOSRecoveryAdvice.classify(message: String(describing: error)).instruction
            }
        }
    }
    private func register() {
        busy = true; message = ""
        Task { @MainActor in
            defer { busy = false }
            do {
                let normalized = try WatchBundleSupport.validateUDID(udid)
                let session = try await AuthManager.shared.getAuthenticatedSession()
                let team = try await AuthManager.shared.getAuthenticatedTeam()
                try await ALTAppleAPI.shared.registerWatch(name: "Fairway Watch", udid: normalized, team: team, session: session)
                UserDefaults.standard.set(normalized, forKey: WatchSupportSettings.udidKey)
                message = "Watch登録を確認しました。次にFairwayのIPAを導入してください。"
            } catch { message = error.localizedDescription }
        }
    }
}

import Foundation

/// 各ペインのURLと最後にアクティブだった(=音声ON)ペインをアプリ再起動後も復元する。
/// Android版はDataStoreだったが、iOS版は同等の役割をUserDefaultsで担う。
final class PaneStore {

    // デフォルトは常時配信されていることの多い公式チャンネルの例。
    // 実際に見たい番組のURLはアプリ上部のURL欄に貼り付けて使う想定。
    static let defaultUrls = [
        "https://www.youtube.com/watch?v=21X5lGlDOfg", // NASA Live
        "https://www.twitch.tv/monstercat",
        "https://www.youtube.com/watch?v=jfKfPfyJRdk", // lofi hip hop radio
        "https://www.twitch.tv/riotgames"
    ]

    private let defaults = UserDefaults.standard
    private let activePaneKey = "active_pane_id"
    private func urlKey(_ id: Int) -> String { "pane_url_\(id)" }

    func loadUrls() -> [String] {
        Self.defaultUrls.indices.map { id in
            defaults.string(forKey: urlKey(id)) ?? Self.defaultUrls[id]
        }
    }

    func saveUrl(paneId: Int, url: String) {
        defaults.set(url, forKey: urlKey(paneId))
    }

    func loadActivePane() -> Int {
        defaults.integer(forKey: activePaneKey) // 未設定時は0(デフォルト値)
    }

    func saveActivePane(_ paneId: Int) {
        defaults.set(paneId, forKey: activePaneKey)
    }
}

import SwiftUI
import WebKit

/// WKWebViewの実体とNotificationObserverを保持するCoordinator。
/// AndroidのStreamPane.kt内`webViewRef`に相当する役割。
final class StreamWebViewCoordinator: NSObject {
    var lastLoadedUrl: String?
    var backgroundObserver: NSObjectProtocol?
    var foregroundObserver: NSObjectProtocol?

    func removeObservers() {
        if let o = backgroundObserver { NotificationCenter.default.removeObserver(o) }
        if let o = foregroundObserver { NotificationCenter.default.removeObserver(o) }
        backgroundObserver = nil
        foregroundObserver = nil
    }

    deinit {
        removeObservers()
    }
}

/// 1ペイン分の動画表示領域。YouTube/TwitchはEmbedResolverが生成する公式埋め込みHTMLを、
/// それ以外(認識できないURL)は生ページをそのまま読み込む。
struct StreamWebView: UIViewRepresentable {
    let url: String
    let isActivePane: Bool
    /// URL解析結果を親(StreamPaneView)に伝え、フォールバック表示の注記に使う
    let onResolved: (EmbedTarget) -> Void

    func makeCoordinator() -> StreamWebViewCoordinator {
        StreamWebViewCoordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .black

        // --- Appのフォアグラウンド/バックグラウンドに連動して再生を一時停止/再開 ---
        // Android版の Activity ライフサイクル連動(WebView.onPause/onResume)に相当。
        // WKWebViewには直接のonPause APIが無いため、埋め込みHTML側に定義した
        // pausePane()/resumePane() をJS経由で呼び出す方式にしている。
        context.coordinator.backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification, object: nil, queue: .main
        ) { [weak webView] _ in
            webView?.evaluateJavaScript("window.pausePane && window.pausePane();")
        }
        context.coordinator.foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
        ) { [weak webView] _ in
            webView?.evaluateJavaScript("window.resumePane && window.resumePane();")
        }

        loadIfNeeded(into: webView, coordinator: context.coordinator, force: true)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        loadIfNeeded(into: webView, coordinator: context.coordinator, force: false)
        // アクティブ(音声ON)ペインが切り替わったら即座に反映
        webView.evaluateJavaScript("window.setPaneMuted && window.setPaneMuted(\(!isActivePane));")
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: StreamWebViewCoordinator) {
        webView.stopLoading()
        coordinator.removeObservers()
    }

    private func loadIfNeeded(into webView: WKWebView, coordinator: StreamWebViewCoordinator, force: Bool) {
        guard force || coordinator.lastLoadedUrl != url else { return }
        coordinator.lastLoadedUrl = url

        let target = EmbedResolver.resolve(url)
        // updateUIView実行中(=View更新サイクルの最中)に@Stateを直接書き換えると
        // SwiftUIの実行時警告(Modifying state during view update)につながるため、
        // 呼び出し元への通知は次のRunLoopに遅延させる。
        DispatchQueue.main.async {
            onResolved(target)
        }

        if let html = EmbedResolver.buildHtml(for: target, initiallyMuted: !isActivePane) {
            webView.loadHTMLString(
                html,
                baseURL: URL(string: "https://\(EmbedResolver.embedParentDomain)/")
            )
        } else if let realUrl = URL(string: url) {
            // YouTube/Twitchの個別動画・チャンネルURLとして解釈できなかった場合のフォールバック
            webView.load(URLRequest(url: realUrl))
        }
    }
}

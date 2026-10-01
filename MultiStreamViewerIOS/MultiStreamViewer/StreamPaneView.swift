import SwiftUI

/// 1ペイン分のUI: 上部の操作バー(音声ON/OFF表示・URL入力欄)+ WebView本体。
/// Android版 StreamPane.kt のComposable部分に相当。
struct StreamPaneView: View {
    let paneId: Int
    let isActivePane: Bool
    let onRequestActive: () -> Void
    let onUrlCommitted: (String) -> Void

    @State private var urlText: String
    @State private var loadedUrl: String
    @State private var isUnrecognized = false

    init(
        paneId: Int,
        initialUrl: String,
        isActivePane: Bool,
        onRequestActive: @escaping () -> Void,
        onUrlCommitted: @escaping (String) -> Void
    ) {
        self.paneId = paneId
        self.isActivePane = isActivePane
        self.onRequestActive = onRequestActive
        self.onUrlCommitted = onUrlCommitted
        _urlText = State(initialValue: initialUrl)
        _loadedUrl = State(initialValue: initialUrl)
    }

    private let activeColor = Color(red: 0.3, green: 0.7, blue: 0.3)
    private let inactiveColor = Color(red: 0.6, green: 0.6, blue: 0.6)
    private let barBackground = Color(red: 0.11, green: 0.11, blue: 0.11)

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Text(isActivePane ? "\u{266A} ON" : "\u{266A} off")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isActivePane ? activeColor : inactiveColor)
                    .onTapGesture { onRequestActive() }

                TextField("YouTube / Twitch のURL", text: $urlText)
                    .font(.system(size: 11))
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .submitLabel(.go)
                    .onSubmit {
                        loadedUrl = urlText
                        onUrlCommitted(urlText)
                    }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(barBackground)

            if isUnrecognized {
                Text("動画/チャンネルURLとして認識できなかったため簡易表示です")
                    .font(.system(size: 9))
                    .foregroundColor(Color(red: 1.0, green: 0.63, blue: 0.0))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                    .background(barBackground)
            }

            StreamWebView(
                url: loadedUrl,
                isActivePane: isActivePane,
                onResolved: { target in
                    isUnrecognized = (target == .unrecognized)
                }
            )
        }
        .overlay(
            Rectangle()
                .stroke(
                    isActivePane ? activeColor : Color(red: 0.27, green: 0.27, blue: 0.27),
                    lineWidth: isActivePane ? 2 : 1
                )
        )
    }
}

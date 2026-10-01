import SwiftUI

/// 2x2グリッド本体。Android版 MainActivity.kt の MultiStreamGridScreen に相当。
struct ContentView: View {
    private let paneStore = PaneStore()

    @State private var urls: [String] = PaneStore.defaultUrls
    @State private var activePaneId: Int = 0
    @State private var loaded = false

    var body: some View {
        Group {
            if loaded {
                VStack(spacing: 0) {
                    HStack {
                        Text("MultiStream Viewer (YouTube / Twitch)")
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(red: 0.07, green: 0.07, blue: 0.07))

                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            pane(0)
                            pane(1)
                        }
                        HStack(spacing: 0) {
                            pane(2)
                            pane(3)
                        }
                    }
                }
                .background(Color.black)
                .ignoresSafeArea(edges: .bottom)
            } else {
                Color.black
                    .ignoresSafeArea()
                    .onAppear(perform: loadInitialState)
            }
        }
    }

    @ViewBuilder
    private func pane(_ id: Int) -> some View {
        StreamPaneView(
            paneId: id,
            initialUrl: urls[id],
            isActivePane: activePaneId == id,
            onRequestActive: {
                activePaneId = id
                paneStore.saveActivePane(id)
            },
            onUrlCommitted: { newUrl in
                urls[id] = newUrl
                paneStore.saveUrl(paneId: id, url: newUrl)
            }
        )
    }

    private func loadInitialState() {
        urls = paneStore.loadUrls()
        activePaneId = paneStore.loadActivePane()
        loaded = true
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

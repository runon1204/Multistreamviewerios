# MultiStream Viewer (iOS版)

Android版と同じ設計(YouTube/Twitchの公式埋め込みAPI、排他ミュート制御、バックグラウンド時の一時停止、URL永続化)をSwiftUI + WKWebViewで移植したものです。

## 重要: この環境ではビルド確認ができていません

この作業環境にはmacOS/Xcodeがなく、ネットワークも遮断されているため、**実際にコンパイルが通るかどうかは検証できていません**。全ファイルは目視で構文確認済みですが、必ずビルドして動作確認してください。エラーが出た場合はメッセージを共有してもらえれば修正します。

## Android版との対応関係

| Android (Kotlin/Compose) | iOS (Swift/SwiftUI) | 役割 |
|---|---|---|
| `EmbedResolver.kt` | `EmbedResolver.swift` | URL解析・埋め込みHTML生成(ロジックはほぼそのまま移植) |
| `StreamPane.kt` | `StreamWebView.swift` + `StreamPaneView.swift` | WebView本体とUI |
| `PaneStore.kt`(DataStore) | `PaneStore.swift`(UserDefaults) | URL・アクティブペインの永続化 |
| `MainActivity.kt` | `ContentView.swift` + `MultiStreamViewerApp.swift` | 2x2グリッドとアプリのエントリーポイント |

## Mac無しで実機確認する方法(無料): GitHub Actions + Sideloadly

macOS/Xcodeを一切使わず、GitHub ActionsのmacOSランナー上で[XcodeGen](https://github.com/yonaskolb/XcodeGen)を使って自動的に`.xcodeproj`を生成してビルドし、生成された未署名の`.ipa`をWindows上の[Sideloadly](https://sideloadly.io/)でiPhoneにインストールする方法です。`project.yml`(XcodeGenの設定)と`.github/workflows/build-ios.yml`(ビルド用ワークフロー)は既にこのプロジェクトに含まれています。

**注意**: この手順は環境上(macOS/実機/GitHub Actions双方とも利用不可)実際に最後まで動作確認できていません。途中でエラーが出た場合は、そのログを共有してもらえれば一緒に切り分けます。

1. **GitHubにリポジトリを作成してpush**
   このフォルダ一式(`MultiStreamViewer/`、`project.yml`、`.github/`)をGitHubの新規リポジトリにpushします。**Public(公開)リポジトリ**にすると、GitHub ActionsのmacOSランナーが無料で使い放題になります(Privateだと無料枠の消費が早いです)。
2. **Actionsタブでワークフローを確認**
   pushすると自動的に`Build iOS (unsigned)`ワークフローが走ります(手動実行したい場合はActionsタブから`Run workflow`)。10〜20分程度かかることがあります。
3. **成功したら.ipaをダウンロード**
   ワークフロー実行結果画面の下部にある「Artifacts」から`MultiStreamViewer-unsigned-ipa`をダウンロードします(中身は未署名の`.ipa`)。
4. **Windowsに[Sideloadly](https://sideloadly.io/)をインストール**
   Appleの「iTunes」または「Apple Devices」アプリ(USBドライバ用)も必要になるので、Sideloadlyの案内に従ってインストールしてください。
5. **iPhoneを接続してSideloadlyでインストール**
   iPhoneをUSB接続し、Sideloadlyに無料のApple IDでサインインし、ダウンロードした`.ipa`をドラッグ&ドロップしてインストールします。
6. **iPhone側で信頼設定**
   初回起動時に「信頼されていないデベロッパ」の警告が出るので、iPhoneの「設定 > 一般 > VPNとデバイス管理」から該当のApple IDを信頼する設定にします。
7. **7日後に有効期限切れ**
   無料Apple IDでの署名は7日間で失効します。再度使いたい場合は、Sideloadlyで同じ`.ipa`を再インストールするだけで再署名されます(GitHub Actionsを再実行する必要はありません)。

有料(年額99ドル)のApple Developer Programに加入すると有効期限が1年になり、TestFlightでの配布もできるようになりますが、「まず自分の端末で1回動かしたい」という今回の目的であれば、上記の無料フローで十分です。

## Xcodeが使える場合のセットアップ手順

Macが用意できた場合は、`project.yml`を使わずに通常通りXcodeでプロジェクトを作成しても構いません。

1. Xcodeで **File > New > Project > iOS > App** を選択
   - Product Name: `MultiStreamViewer`
   - Interface: **SwiftUI**
   - Minimum Deployments: **iOS 15以上**を推奨
2. 生成された`ContentView.swift`・`〇〇App.swift`を、このプロジェクト内の同名ファイルの中身で置き換える
3. 残りのファイル(`EmbedResolver.swift`, `PaneStore.swift`, `StreamWebView.swift`, `StreamPaneView.swift`)をXcodeのプロジェクトナビゲータにドラッグ&ドロップで追加
4. シミュレータ(またはiOS 15以上の実機)を選択してビルド・実行

あるいは、Mac上でもXcodeGenがインストールされていれば(`brew install xcodegen`)、プロジェクトルートで`xcodegen generate`を実行するだけで`.xcodeproj`が生成され、そのまま開けます。

## 既知の制約

- チャンネルの`/live`ページなど動画IDを直接含まないURLは、簡易フォールバック表示(生ページ+DOM操作でのミュート)になります(Android版と同様)
- Twitch Embedの`parent`パラメータには`streamgrid.local`という固定のダミードメインを使用しています
- WKWebViewの`mediaTypesRequiringUserActionForPlayback = []`により自動再生を許可していますが、iOSのバージョンやサイト側のポリシー変更により、自動再生がブロックされる可能性があります
- Android版で確認済みの「YouTube/Twitchとも実際に再生できる」という動作結果は、あくまでAndroid実機での確認結果です。iOS版はロジックを移植しただけで、実機・シミュレータでの動作は未確認です
- GitHub Actionsのビルド設定(`project.yml`・`build-ios.yml`)も同様に未検証です

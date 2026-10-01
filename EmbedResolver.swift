import Foundation

/// ペインに表示する対象の種類(Android版 EmbedTarget の移植)
enum EmbedTarget: Equatable {
    case youTube(videoId: String)
    case twitchChannel(channel: String)
    case twitchVod(videoId: String)
    /// 動画IDを特定できなかった場合(チャンネルの/liveページ等)。生ページをそのまま表示する。
    case unrecognized
}

/// URL解析と埋め込みHTML生成(Android版 EmbedResolver.kt の移植)
enum EmbedResolver {

    /// loadHTMLStringのbaseURLに使うダミーのオリジン。Twitch Embedのparent許可リストと一致させる。
    static let embedParentDomain = "streamgrid.local"

    private static let ytShort = try! NSRegularExpression(pattern: "youtu\\.be/([a-zA-Z0-9_-]{6,})")
    private static let ytWatch = try! NSRegularExpression(pattern: "[?&]v=([a-zA-Z0-9_-]{6,})")
    private static let ytEmbed = try! NSRegularExpression(pattern: "youtube\\.com/embed/([a-zA-Z0-9_-]{6,})")
    private static let ytLive = try! NSRegularExpression(pattern: "youtube\\.com/live/([a-zA-Z0-9_-]{6,})")

    private static let twitchVod = try! NSRegularExpression(pattern: "twitch\\.tv/videos/(\\d+)")
    private static let twitchChannel = try! NSRegularExpression(
        pattern: "twitch\\.tv/([a-zA-Z0-9_]{3,25})(?:[/?#]|$)"
    )
    private static let twitchReserved: Set<String> = [
        "videos", "directory", "p", "settings", "subscriptions", "moderator"
    ]

    /// ユーザーが貼り付けた通常のURLから、埋め込み再生に必要な情報を判定する
    static func resolve(_ rawUrl: String) -> EmbedTarget {
        let url = rawUrl.trimmingCharacters(in: .whitespacesAndNewlines)

        if let id = firstMatch(ytShort, in: url) { return .youTube(videoId: id) }
        if let id = firstMatch(ytWatch, in: url) { return .youTube(videoId: id) }
        if let id = firstMatch(ytEmbed, in: url) { return .youTube(videoId: id) }
        if let id = firstMatch(ytLive, in: url) { return .youTube(videoId: id) }

        if let id = firstMatch(twitchVod, in: url) { return .twitchVod(videoId: id) }
        if let name = firstMatch(twitchChannel, in: url), !twitchReserved.contains(name.lowercased()) {
            return .twitchChannel(channel: name)
        }

        return .unrecognized
    }

    private static func firstMatch(_ regex: NSRegularExpression, in text: String) -> String? {
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              match.numberOfRanges > 1,
              let r = Range(match.range(at: 1), in: text) else { return nil }
        return String(text[r])
    }

    static func buildHtml(for target: EmbedTarget, initiallyMuted: Bool) -> String? {
        switch target {
        case .youTube(let videoId):
            return youTubeHtml(videoId: videoId, muted: initiallyMuted)
        case .twitchChannel(let channel):
            return twitchHtml(targetParam: "\"channel\": \"\(channel)\"", initiallyMuted: initiallyMuted)
        case .twitchVod(let videoId):
            return twitchHtml(targetParam: "\"video\": \"\(videoId)\"", initiallyMuted: initiallyMuted)
        case .unrecognized:
            return nil
        }
    }

    private static func youTubeHtml(videoId: String, muted: Bool) -> String {
        """
        <!DOCTYPE html><html><head>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        </head><body style="margin:0;padding:0;background:#000;overflow:hidden;">
        <div id="player" style="position:absolute;top:0;left:0;width:100%;height:100%;"></div>
        <script>
          var tag = document.createElement('script');
          tag.src = "https://www.youtube.com/iframe_api";
          document.head.appendChild(tag);
          var ytPlayer;
          function onYouTubeIframeAPIReady() {
            ytPlayer = new YT.Player('player', {
              width: '100%', height: '100%',
              videoId: '\(videoId)',
              playerVars: { autoplay: 1, playsinline: 1, mute: \(muted ? 1 : 0) },
              events: {
                onReady: function(e) {
                  \(muted ? "e.target.mute();" : "e.target.unMute();")
                  e.target.playVideo();
                }
              }
            });
          }
          window.setPaneMuted = function(m) {
            try { if (ytPlayer && ytPlayer.mute) { m ? ytPlayer.mute() : ytPlayer.unMute(); } } catch (e) {}
          };
          window.pausePane = function() {
            try { if (ytPlayer && ytPlayer.pauseVideo) { ytPlayer.pauseVideo(); } } catch (e) {}
          };
          window.resumePane = function() {
            try { if (ytPlayer && ytPlayer.playVideo) { ytPlayer.playVideo(); } } catch (e) {}
          };
        </script>
        </body></html>
        """
    }

    private static func twitchHtml(targetParam: String, initiallyMuted: Bool) -> String {
        """
        <!DOCTYPE html><html><head>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        </head><body style="margin:0;padding:0;background:#000;overflow:hidden;">
        <div id="twitch-embed" style="position:absolute;top:0;left:0;width:100%;height:100%;"></div>
        <script src="https://embed.twitch.tv/embed/v1.js"></script>
        <script>
          var twPlayer;
          var embed = new Twitch.Embed("twitch-embed", {
            width: "100%",
            height: "100%",
            \(targetParam),
            layout: "video",
            muted: \(initiallyMuted),
            autoplay: true,
            parent: ["\(embedParentDomain)"]
          });
          embed.addEventListener(Twitch.Embed.VIDEO_READY, function() {
            twPlayer = embed.getPlayer();
            twPlayer.setMuted(\(initiallyMuted));
          });
          window.setPaneMuted = function(m) {
            try { if (twPlayer) twPlayer.setMuted(m); } catch (e) {}
          };
          window.pausePane = function() {
            try { if (twPlayer) twPlayer.pause(); } catch (e) {}
          };
          window.resumePane = function() {
            try { if (twPlayer) twPlayer.play(); } catch (e) {}
          };
        </script>
        </body></html>
        """
    }
}

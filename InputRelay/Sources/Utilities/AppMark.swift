import AppKit

/// 品牌标识：线性狐狸。
/// 窗口标题和菜单栏共用同一份资源，避免两处各画一个。
enum AppMark {
    /// 按 point 尺寸返回标识图；资源缺失时回退到原来的手柄符号。
    /// 每次返回副本，避免调用方之间互相改写 size（窗口 19pt / 菜单栏 18pt）。
    static func image(size: CGFloat) -> NSImage {
        let image = (base?.copy() as? NSImage) ?? fallback(size: size)
        image.size = NSSize(width: size, height: size)
        return image
    }

    /// 菜单栏用的模板图：系统按菜单栏明暗自动着色。
    /// 未连接时降低不透明度，保留原先 idle / connected 的状态区分。
    static func statusImage(connected: Bool, size: CGFloat = 18) -> NSImage {
        let source = image(size: size)
        guard !connected else { return template(source) }
        let dimmed = NSImage(size: source.size, flipped: false) { rect in
            source.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 0.4)
            return true
        }
        return template(dimmed)
    }

    private static func template(_ image: NSImage) -> NSImage {
        image.isTemplate = true
        return image
    }

    /// build.sh 把 fox-mark.png 放在 Contents/Resources 下。
    private static let base: NSImage? = {
        guard let url = Bundle.main.url(forResource: "fox-mark", withExtension: "png"),
              let image = NSImage(contentsOf: url) else { return nil }
        return image
    }()

    private static func fallback(size: CGFloat) -> NSImage {
        NSImage(systemSymbolName: "gamecontroller", accessibilityDescription: "InputRelay")
            ?? NSImage(size: NSSize(width: size, height: size))
    }
}

import AppKit

/// 品牌标识：线性狐狸。
/// 窗口标题和菜单栏共用同一份资源，避免两处各画一个。
@MainActor
enum AppMark {
    /// 按 point 尺寸返回标识图；资源缺失时回退到原来的手柄符号。
    /// 每次返回副本，避免调用方之间互相改写 size（窗口 19pt / 菜单栏 18pt）。
    static func image(size: CGFloat) -> NSImage {
        let image = (base?.copy() as? NSImage) ?? fallback(size: size)
        image.size = NSSize(width: size, height: size)
        return image
    }

    /// 菜单栏用的模板图：系统按菜单栏明暗自动着色。
    /// 始终保持完整不透明度，连接状态由菜单文字表示。
    static func statusImage(size: CGFloat = 18) -> NSImage {
        template(image(size: size))
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

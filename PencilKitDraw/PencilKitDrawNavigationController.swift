/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`PencilKitDrawNavigationController` turns off the navigation bar background as it will affect latency.
 这段代码通过自定义一个 1x1 像素的图形作为导航栏背景，实现了简单的导航栏背景自定义。
 这样的设计可以减少导航栏背景的渲染对应用性能（特别是绘图延迟）的影响。
 此外，通过在 traitCollectionDidChange 方法中调用 updateNavigationBarBackground 方法，
 确保了应用主题（如深色模式和浅色模式）切换时，导航栏背景能够相应地更新。
*/

import UIKit

// 自定义的导航控制器类。
class PencilKitDrawNavigationController: UINavigationController {
    // 视图加载完成时调用。
    override func viewDidLoad() {
        super.viewDidLoad()
        // 更新导航栏背景。
        updateNavigationBarBackground()
    }
    
    // 当视图的特征集合发生改变时调用（例如，切换深色模式和浅色模式）。
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // 重新更新导航栏背景以适应新的特征集合。
        updateNavigationBarBackground()
    }
    
    // 更新导航栏的背景样式。
    func updateNavigationBarBackground() {
        // 开始一个图形上下文，大小为 1x1 像素。
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        // 设置导航栏背景色。这里使用次级系统背景色，透明度为 0.95。
        UIColor.secondarySystemBackground.withAlphaComponent(0.95).set()
        // 填充一个 1x1 像素的矩形区域。
        UIBezierPath(rect: CGRect(x: 0, y: 0, width: 1, height: 1)).fill()
        // 将当前图形上下文中的图像设置为导航栏的背景图，应用于默认状态。
        navigationBar.setBackgroundImage(UIGraphicsGetImageFromCurrentImageContext(), for: .default)
        // 结束图形上下文。
        UIGraphicsEndImageContext()
    }
}

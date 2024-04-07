/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The thumbnail cell for showing thumbnails in ThumbnailCollectionViewController.
 这个单元格类主要负责展示一个图画的缩略图。通过 @IBOutlet 将 imageView 与 Interface Builder 中的图像视图关联起来，
 使得可以在 storyboard 或者 xib 文件中直接设置这个单元格的外观和属性。awakeFromNib 方法在单元格从 nib 或 storyboard 加载完毕后被调用，
 这里用它来为 imageView 设置阴影，增加视觉层次感和美观性。阴影的路径、透明度、偏移量都可以根据需要调整，以达到设计要求。
*/

import UIKit

// 缩略图集合视图的单元格类。
class ThumbnailCollectionViewCell: UICollectionViewCell {
    
    // 缩略图的图像视图，通过 Interface Builder 关联。
    @IBOutlet weak var imageView: UIImageView!
    
    // 初始化视图。
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // 为图像视图设置阴影效果。
        // 创建阴影路径，路径为图像视图的边界。
        imageView.layer.shadowPath = UIBezierPath(rect: imageView.bounds).cgPath
        // 设置阴影的透明度。
        imageView.layer.shadowOpacity = 0.2
        // 设置阴影的偏移量，这里设置为宽度为0，高度为3，意味着阴影向下投射。
        imageView.layer.shadowOffset = CGSize(width: 0, height: 3)
        // 禁用图像视图的裁剪，让阴影能够显示出来。
        imageView.clipsToBounds = false
    }
}

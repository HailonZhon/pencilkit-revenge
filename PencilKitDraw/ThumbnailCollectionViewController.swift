/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`ThumbnailCollectionViewController` shows a set of thumbnails of all drawings.
*/

import UIKit
import PencilKit

// 缩略图集合视图控制器，展示绘图应用中的图画缩略图。
class ThumbnailCollectionViewController: UICollectionViewController, DataModelControllerObserver {
    
    // 显示在此视图控制器中的图画的数据模型。
    var dataModelController = DataModelController()
    
    // 视图生命周期
    
    // 初始设置视图。
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 将当前的缩略图特征（如颜色模式）信息通知数据模型。
        dataModelController.thumbnailTraitCollection = traitCollection
        
        // 观察数据模型的变化。
        dataModelController.observers.append(self)
    }
    
    // 当视图的特征集合发生改变（如深色模式和浅色模式切换）时，更新数据模型的缩略图特征。
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        dataModelController.thumbnailTraitCollection = traitCollection
    }
    
    // 数据模型观察者
    
    // 当数据模型发生变化时，重新加载集合视图。
    func dataModelChanged() {
        collectionView.reloadData()
    }
    
    // 行为
    
    // 创建一个新的绘图。
    @IBAction func newDrawing(_ sender: Any) {
        dataModelController.newDrawing()
    }
    
    // 集合视图数据源
    
    // 数据源方法：集合视图的分区数量。
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    // 数据源方法：每个分区中的项目数量。
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataModelController.drawings.count
    }
    
    // 数据源方法：为每个单元格提供视图。
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // 根据标识符获取一个单元格视图。
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "ThumbnailCell",
            for: indexPath) as? ThumbnailCollectionViewCell
            else {
                fatalError("Unexpected cell type.")
        }
        
        // 如果可用，设置缩略图图像。
        if let index = indexPath.last, index < dataModelController.thumbnails.count {
            cell.imageView.image = dataModelController.thumbnails[index]
        }
        
        return cell
    }
    
    // 集合视图代理
    
//    // 代理方法：点击单元格后展示对应的图画。
//    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        
//        // 创建绘图视图控制器。
//        guard let drawingViewController = storyboard?.instantiateViewController(withIdentifier: "DrawingViewController") as? DrawingViewController,
//            let navigationController = navigationController else {
//                return
//        }
//        
//        // 过渡到绘图视图控制器。
//        drawingViewController.dataModelController = dataModelController
//        drawingViewController.drawingIndex = indexPath.last!
//        navigationController.pushViewController(drawingViewController, animated: true)
//    }
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 使用Storyboard ID来创建SplitDrawingViewController实例
        guard let splitDrawingViewController = storyboard?.instantiateViewController(withIdentifier: "SplitDrawingViewController") as? SplitDrawingViewController else {
            return
        }
        
        // 传递所需的数据给splitDrawingViewController
        splitDrawingViewController.dataModelController = dataModelController
        // 假设SplitDrawingViewController有一个用来接收选中绘图索引的属性
        splitDrawingViewController.drawingIndex = indexPath.row
        
        // 使用导航控制器来推送视图控制器
        navigationController?.pushViewController(splitDrawingViewController, animated: true)
    }

}

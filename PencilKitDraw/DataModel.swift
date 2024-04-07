/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's data model for storing drawings, thumbnails, and signatures.
*/

/// Underlying the app's data model is a cross-platform `PKDrawing` object. `PKDrawing` adheres to `Codable`
/// in Swift, or you can fetch its data representation as a `Data` object through its `dataRepresentation()`
/// method. `PKDrawing` is the only PencilKit type supported on non-iOS platforms.

/// From `PKDrawing`'s `image(from:scale:)` method, you can get an image to save, or you can transform a
/// `PKDrawing` and append it to another drawing.

/// If you already have some saved `PKDrawing`s, you can make them available in this sample app by adding them
/// to the project's "Assets" catalog, and adding their asset names to the `defaultDrawingNames` array below.
/// 这个代码提供了一个应用程序的基础架构，用于使用 PencilKit 处理、展示和保存用户绘制的图画。包含了数据模型的定义、数据的保存和加载、缩略图的生成以及如何通知应用程序的其他部分数据模型发生变化。

import UIKit
import PencilKit
import os

// `DataModel` 结构体定义了数据模型，包含多个图画和一个签名图画。
struct DataModel: Codable {
    
    // 默认图画名称数组，用于第一次初始化数据模型。
    static let defaultDrawingNames: [String] = ["Notes"]
    
    // 用于绘画画布的宽度。
    static let canvasWidth: CGFloat = 768
    
    // 当前数据模型的图画集合。
    var drawings: [PKDrawing] = []
    var signature = PKDrawing()
}

// `DataModelControllerObserver` 协议定义了观察者对数据模型变化的响应方法。
protocol DataModelControllerObserver {
    // 当数据模型发生变化时被调用。
    func dataModelChanged()
}

// `DataModelController` 类协调对数据模型的更改。
class DataModelController {
    
    // 底层的数据模型。
    var dataModel = DataModel()
    
    // 代表数据模型中图画的缩略图数组。
    var thumbnails = [UIImage]()
    var thumbnailTraitCollection = UITraitCollection() {
        didSet {
            // 如果用户界面风格发生变化，重新生成所有缩略图。
            if oldValue.userInterfaceStyle != thumbnailTraitCollection.userInterfaceStyle {
                generateAllThumbnails()
            }
        }
    }
    
    // 用于执行此控制器的后台操作的调度队列。
    private let thumbnailQueue = DispatchQueue(label: "ThumbnailQueue", qos: .background)
    private let serializationQueue = DispatchQueue(label: "SerializationQueue", qos: .background)
    
    // 观察者将自己添加到这个数组中以开始接收数据模型变化的通知。
    var observers = [DataModelControllerObserver]()
    
    // 缩略图的尺寸。
    static let thumbnailSize = CGSize(width: 192, height: 256)
    
    // 提供访问数据模型中图画的计算属性。
    var drawings: [PKDrawing] {
        get { dataModel.drawings }
        set { dataModel.drawings = newValue }
    }
    // 提供访问数据模型中签名图画的计算属性。
    var signature: PKDrawing {
        get { dataModel.signature }
        set { dataModel.signature = newValue }
    }
    
    // 初始化一个新的数据模型。
    init() {
        loadDataModel()
    }
    
    // 更新某个索引处的图画并生成新的缩略图。
    func updateDrawing(_ drawing: PKDrawing, at index: Int) {
        dataModel.drawings[index] = drawing
        generateThumbnail(index)
        saveDataModel()
    }
    
    // 辅助方法，触发重新生成所有缩略图。
    private func generateAllThumbnails() {
        for index in drawings.indices {
            generateThumbnail(index)
        }
    }
    
    // 辅助方法，根据当前缩略图视图控制器的用户界面风格重新生成特定缩略图。
    private func generateThumbnail(_ index: Int) {
        let drawing = drawings[index]
        let aspectRatio = DataModelController.thumbnailSize.width / DataModelController.thumbnailSize.height
        let thumbnailRect = CGRect(x: 0, y: 0, width: DataModel.canvasWidth, height: DataModel.canvasWidth / aspectRatio)
        let thumbnailScale = UIScreen.main.scale * DataModelController.thumbnailSize.width / DataModel.canvasWidth
        let traitCollection = thumbnailTraitCollection
        
        thumbnailQueue.async {
            traitCollection.performAsCurrent {
                let image = drawing.image(from: thumbnailRect, scale: thumbnailScale)
                DispatchQueue.main.async {
                    self.updateThumbnail(image, at: index)
                }
            }
        }
    }
    
    // 辅助方法，替换给定索引处的缩略图。
    private func updateThumbnail(_ image: UIImage, at index: Int) {
        thumbnails[index] = image
        didChange()
    }
    
    // 辅助方法，通知观察者数据模型发生了变化。
    private func didChange() {
        for observer in self.observers {
            observer.dataModelChanged()
        }
    }
    
    // 数据模型保存到持久存储的文件URL。
    private var saveURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths.first!
        return documentsDirectory.appendingPathComponent("PencilKitDraw.data")
    }
    
    // 将数据模型保存到持久存储。
    func saveDataModel() {
        let savingDataModel = dataModel
        let url = saveURL
        serializationQueue.async {
            do {
                let encoder = PropertyListEncoder()
                let data = try encoder.encode(savingDataModel)
                try data.write(to: url)
            } catch {
                os_log("Could not save data model: %s", type: .error, error.localizedDescription)
            }
        }
    }
    
    // 从持久存储加载数据模型。
    private func loadDataModel() {
        let url = saveURL
        serializationQueue.async {
            let dataModel: DataModel
            
            if FileManager.default.fileExists(atPath: url.path) {
                do {
                    let decoder = PropertyListDecoder()
                    let data = try Data(contentsOf: url)
                    dataModel = try decoder.decode(DataModel.self, from: data)
                } catch {
                    os_log("Could not load data model: %s", type: .error, error.localizedDescription)
                    dataModel = self.loadDefaultDrawings()
                }
            } else {
                dataModel = self.loadDefaultDrawings()
            }
            
            DispatchQueue.main.async {
                self.setLoadedDataModel(dataModel)
            }
        }
    }
    
    // 当不存在数据模型时，构造一个初始数据模型。
    private func loadDefaultDrawings() -> DataModel {
        var testDataModel = DataModel()
        for sampleDataName in DataModel.defaultDrawingNames {
            guard let data = NSDataAsset(name: sampleDataName)?.data else { continue }
            if let drawing = try? PKDrawing(data: data) {
                testDataModel.drawings.append(drawing)
            }
        }
        return testDataModel
    }
    
    // 辅助方法，设置当前数据模型为在后台队列上创建的数据模型。
    private func setLoadedDataModel(_ dataModel: DataModel) {
        self.dataModel = dataModel
        thumbnails = Array(repeating: UIImage(), count: dataModel.drawings.count)
        generateAllThumbnails()
    }
    
    // 在数据模型中创建一个新的图画。
    func newDrawing() {
        let newDrawing = PKDrawing()
        dataModel.drawings.append(newDrawing)
        thumbnails.append(UIImage())
        updateDrawing(newDrawing, at: dataModel.drawings.count - 1)
    }
}

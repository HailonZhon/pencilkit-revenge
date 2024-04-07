/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`DrawingViewController` is the primary view controller for showing drawings.
*/

///`PKCanvasView` is the main drawing view that you will add to your view hierarchy.
/// The drawingPolicy dictates whether drawing with a finger is allowed.  If it's set to default and if the tool picker is visible,
/// then it will respect the global finger pencil toggle in Settings or as set in the tool picker.  Otherwise, only drawing with
/// a pencil is allowed.

/// You can add your own class as a delegate of PKCanvasView to receive notifications after a user
/// has drawn or the drawing was updated. You can also set the tool or toggle the ruler on the canvas.

/// There is a shared tool picker for each window. The tool picker floats above everything, similar
/// to the keyboard. The tool picker is moveable in a regular size class window, and fixed to the bottom
/// in compact size class. To listen to tool picker notifications, add yourself as an observer.

/// Tool picker visibility is based on first responders. To make the tool picker appear, you need to
/// associate the tool picker with a `UIResponder` object, such as a view, by invoking the method
/// `UIToolpicker.setVisible(_:forResponder:)`, and then by making that responder become the first

/// Best practices:
///
/// -- Because the tool picker palette is floating and moveable for regular size classes, but fixed to the
/// bottom in compact size classes, make sure to listen to the tool picker's obscured frame and adjust your UI accordingly.

/// -- For regular size classes, the palette has undo and redo buttons, but not for compact size classes.
/// Make sure to provide your own undo and redo buttons when in a compact size class.

import UIKit
import PencilKit


class DrawingViewController: UIViewController, PKCanvasViewDelegate, PKToolPickerObserver, UIScreenshotServiceDelegate {
    
    // 与 Interface Builder 关联的画布视图和工具栏按钮。
    @IBOutlet weak var canvasView: PKCanvasView!
//    @IBOutlet var undoBarButtonitem: UIBarButtonItem!
//    @IBOutlet var redoBarButtonItem: UIBarButtonItem!
    
    var toolPicker: PKToolPicker!
    var signDrawingItem: UIBarButtonItem!
    
    // 在 iOS 14.0 中，这不再必要，因为手指与铅笔的切换是工具选择器的全局设置
    var pencilFingerBarButtonItem: UIBarButtonItem!

    // 画布的标准过度滚动高度。
    static let canvasOverscrollHeight: CGFloat = 500
    
    // 当前绘图的数据模型。
    var dataModelController: DataModelController!
    
    // 私有绘图状态。
    var drawingIndex: Int = 0
    var hasModifiedDrawing = false
    
    // 视图生命周期
    
    // 视图将要出现时的设置。
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 使用数据模型中的第一个绘图设置画布视图。
        canvasView.delegate = self
        canvasView.drawing = dataModelController.drawings[drawingIndex]
        canvasView.alwaysBounceVertical = true
        
        // 设置工具选择器。
        if #available(iOS 14.0, *) {
            toolPicker = PKToolPicker()
        } else {
            // 使用父视图的窗口来设置工具选择器，因为我们的视图还没有被添加到窗口上。
            let window = parent?.view.window
            toolPicker = PKToolPicker.shared(for: window!)
        }
        
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        toolPicker.addObserver(self)
        updateLayout(for: toolPicker)
        canvasView.becomeFirstResponder()
        
        // 添加“签名绘图”按钮到页面右下角。
//        signDrawingItem = UIBarButtonItem(title: "Sign Drawing", style: .plain, target: self, action: #selector(signDrawing(sender:)))
//        navigationItem.rightBarButtonItems?.append(signDrawingItem)
        
        // 在 iOS 14 之前，添加一个按钮来切换手指绘图功能。
        if #available(iOS 14.0, *) { } else {
            pencilFingerBarButtonItem = UIBarButtonItem(title: "Enable Finger Drawing",
                                                        style: .plain,
                                                        target: self,
                                                        action: #selector(toggleFingerPencilDrawing(_:)))
            navigationItem.rightBarButtonItems?.append(pencilFingerBarButtonItem)
            canvasView.allowsFingerDrawing = false
        }
        
        // 总是显示返回按钮。
        navigationItem.leftItemsSupplementBackButton = true
        
        // 设置这个视图控制器作为创建全屏截图的代理。
        parent?.view.window?.windowScene?.screenshotService?.delegate = self
    }
    
    // 视图布局变化时，调整画布的缩放以便缩放到默认的 `canvasWidth`。
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let canvasScale = canvasView.bounds.width / DataModel.canvasWidth
        canvasView.minimumZoomScale = canvasScale
        canvasView.maximumZoomScale = canvasScale
        canvasView.zoomScale = canvasScale
        
        // 滚动到顶部。
        updateContentSizeForDrawing()
        canvasView.contentOffset = CGPoint(x: 0, y: -canvasView.adjustedContentInset.top)
    }
    
    // 视图将要消失时，如果有修改，则保存修改后的绘图。
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if hasModifiedDrawing {
            dataModelController.updateDrawing(canvasView.drawing, at: drawingIndex)
        }
        
        // 移除这个视图控制器作为截图代理。
        view.window?.windowScene?.screenshotService?.delegate = nil
    }
    
    // 隐藏家庭指示器，因为它会影响延迟。
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    // 行为
    
    // 切换手指绘图功能的动作方法，仅在 iOS 14.0 之前的设备上有效。
    @IBAction func toggleFingerPencilDrawing(_ sender: Any) {
        if #available(iOS 14.0, *) { } else {
            canvasView.allowsFingerDrawing.toggle()
            let title = canvasView.allowsFingerDrawing ? "Disable Finger Drawing" : "Enable Finger Drawing"
            pencilFingerBarButtonItem.title = title
        }
    }
//    func setNewDrawingUndoable(_ newDrawing: PKDrawing) {
//        let oldDrawing = canvasView.drawing
//        undoManager?.registerUndo(withTarget: self) {
//            $0.setNewDrawingUndoable(oldDrawing)
//        }
//        canvasView.drawing = newDrawing
//    }
    // 添加签名到当前绘图的动作方法。
//    @IBAction func signDrawing(sender: UIBarButtonItem) {
//        // 获取签名绘图，并按照画布的缩放调整。
//        var signature = dataModelController.signature
//        let signatureBounds = signature.bounds
//        let loc = CGPoint(x: canvasView.bounds.maxX, y: canvasView.bounds.maxY)
//        let scaledLoc = CGPoint(x: loc.x / canvasView.zoomScale, y: loc.y / canvasView.zoomScale)
//        signature.transform(using: CGAffineTransform(translationX: scaledLoc.x - signatureBounds.maxX, y: scaledLoc.y - signatureBounds.maxY))
//
//        // 将签名绘图添加到当前画布绘图上。
//        setNewDrawingUndoable(canvasView.drawing.appending(signature))
//    }

    // 导航
    
    // 画布视图代理
    
    // 绘图改变时的代理方法。
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        hasModifiedDrawing = true
        updateContentSizeForDrawing()
    }
    
    // 调整画布视图的内容大小以适应绘图。
    func updateContentSizeForDrawing() {
        let drawing = canvasView.drawing
        let contentHeight: CGFloat
        
        // 调整内容大小以始终大于绘图高度。
        if !drawing.bounds.isNull {
            contentHeight = max(canvasView.bounds.height, (drawing.bounds.maxY + DrawingViewController.canvasOverscrollHeight) * canvasView.zoomScale)
        } else {
            contentHeight = canvasView.bounds.height
        }
        canvasView.contentSize = CGSize(width: DataModel.canvasWidth * canvasView.zoomScale, height: contentHeight)
    }
    
    // 工具选择器观察者
    
    // 工具选择器改变遮盖画布视图的部分时的代理方法。
    func toolPickerFramesObscuredDidChange(_ toolPicker: PKToolPicker) {
        updateLayout(for: toolPicker)
    }
    
    // 工具选择器变为可见或隐藏时的代理方法。
    func toolPickerVisibilityDidChange(_ toolPicker: PKToolPicker) {
        updateLayout(for: toolPicker)
    }
    
    // 当工具选择器改变遮盖画布视图的部分时，调整画布视图的大小。
    func updateLayout(for toolPicker: PKToolPicker) {
        let obscuredFrame = toolPicker.frameObscured(in: view)
        
        if obscuredFrame.isNull {
            canvasView.contentInset = .zero
            navigationItem.leftBarButtonItems = []
        } else {
            canvasView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: view.bounds.maxY - obscuredFrame.minY, right: 0)
//            navigationItem.leftBarButtonItems = [undoBarButtonitem, redoBarButtonItem]
        }
        canvasView.scrollIndicatorInsets = canvasView.contentInset
    }
    
    // MARK: Screenshot Service Delegate
    
    /// Delegate method: Generate a screenshot as a PDF.
    func screenshotService(
        _ screenshotService: UIScreenshotService,
        generatePDFRepresentationWithCompletion completion:
        @escaping (_ PDFData: Data?, _ indexOfCurrentPage: Int, _ rectInCurrentPage: CGRect) -> Void) {
        
        // Find out which part of the drawing is actually visible.
        let drawing = canvasView.drawing
        let visibleRect = canvasView.bounds
        
        // Convert to PDF coordinates, with (0, 0) at the bottom left hand corner,
        // making the height a bit bigger than the current drawing.
        let pdfWidth = DataModel.canvasWidth
        let pdfHeight = drawing.bounds.maxY + 100
        let canvasContentSize = canvasView.contentSize.height - DrawingViewController.canvasOverscrollHeight
        
        let xOffsetInPDF = pdfWidth - (pdfWidth * visibleRect.minX / canvasView.contentSize.width)
        let yOffsetInPDF = pdfHeight - (pdfHeight * visibleRect.maxY / canvasContentSize)
        let rectWidthInPDF = pdfWidth * visibleRect.width / canvasView.contentSize.width
        let rectHeightInPDF = pdfHeight * visibleRect.height / canvasContentSize
        
        let visibleRectInPDF = CGRect(
            x: xOffsetInPDF,
            y: yOffsetInPDF,
            width: rectWidthInPDF,
            height: rectHeightInPDF)
        
        // Generate the PDF on a background thread.
        DispatchQueue.global(qos: .background).async {
            
            // Generate a PDF.
            let bounds = CGRect(x: 0, y: 0, width: pdfWidth, height: pdfHeight)
            let mutableData = NSMutableData()
            UIGraphicsBeginPDFContextToData(mutableData, bounds, nil)
            UIGraphicsBeginPDFPage()
            
            // Generate images in the PDF, strip by strip.
            var yOrigin: CGFloat = 0
            let imageHeight: CGFloat = 1024
            while yOrigin < bounds.maxY {
                let imgBounds = CGRect(x: 0, y: yOrigin, width: DataModel.canvasWidth, height: min(imageHeight, bounds.maxY - yOrigin))
                let img = drawing.image(from: imgBounds, scale: 2)
                img.draw(in: imgBounds)
                yOrigin += imageHeight
            }
            
            UIGraphicsEndPDFContext()
            
            // Invoke the completion handler with the generated PDF data.
            completion(mutableData as Data, 0, visibleRectInPDF)
        }
    }
}

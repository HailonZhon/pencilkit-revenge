//
//  SplitDrawingViewController.swift
//  PencilKitDraw
//
//  Created by hailong on 2024/4/7.
//  Copyright © 2024 Apple. All rights reserved.
//

import UIKit
import PencilKit

class SplitDrawingViewController: UIViewController, PKCanvasViewDelegate {

    var dataModelController: DataModelController!
    var drawingIndex: Int!
    var backgroundView: UIView!
    var canvasView: PKCanvasView!
    var previewView: UIImageView!
    var dividerView: UIView!
    var toolPicker: PKToolPicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 初始化背景视图，稍微留出边距以展示背景
        let margin: CGFloat = 10
        backgroundView = UIView(frame: CGRect(x: margin, y: margin, width: self.view.bounds.width - 2 * margin, height: self.view.bounds.height - 2 * margin))
        backgroundView.backgroundColor = .lightGray
        self.view.addSubview(backgroundView)

        // 初始化绘图视图，设置在背景视图的左半边
        let dividerThickness: CGFloat = 10
        canvasView = PKCanvasView(frame: CGRect(x: 0, y: 0, width: (backgroundView.bounds.width - dividerThickness) / 2, height: backgroundView.bounds.height))
        backgroundView.addSubview(canvasView)

        // 初始化预览视图，设置在背景视图的右半边
        previewView = UIImageView(frame: CGRect(x: (backgroundView.bounds.width + dividerThickness) / 2, y: 0, width: (backgroundView.bounds.width - dividerThickness) / 2, height: backgroundView.bounds.height))
        backgroundView.addSubview(previewView)

        // 初始化分割视图，设置在背景视图的中间
        dividerView = UIView(frame: CGRect(x: (backgroundView.bounds.width - dividerThickness) / 2, y: 0, width: dividerThickness, height: backgroundView.bounds.height))
        dividerView.backgroundColor = .gray
        backgroundView.addSubview(dividerView)
        
        // 添加拖动手势
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        dividerView.addGestureRecognizer(panGesture)

        // 显示工具选择器
        if #available(iOS 14.0, *) {
            toolPicker = PKToolPicker()
            toolPicker.setVisible(true, forFirstResponder: canvasView)
            toolPicker.addObserver(canvasView)
            canvasView.becomeFirstResponder()
        } else {
            // 对于iOS 14.0以下版本的额外处理
            if let window = self.view.window, let toolPicker = PKToolPicker.shared(for: window) {
                toolPicker.setVisible(true, forFirstResponder: canvasView)
                toolPicker.addObserver(canvasView)
                canvasView.becomeFirstResponder()
            }
        }
        
        canvasView.delegate = self // 设置绘图视图的代理
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self.view)
        let newCenterX = gesture.view!.center.x + translation.x
        
        // 确保分割线在视图范围内移动
        if newCenterX >= 100 && newCenterX <= self.view.bounds.width - 100 {
            gesture.view!.center.x = newCenterX
            gesture.setTranslation(.zero, in: self.view)
            
            // 调整绘图视图和预览视图的宽度
            canvasView.frame.size.width = newCenterX - canvasView.frame.origin.x
            previewView.frame.origin.x = newCenterX + dividerView.frame.width / 2
            previewView.frame.size.width = self.view.frame.width - previewView.frame.origin.x
        }
    }
    
}

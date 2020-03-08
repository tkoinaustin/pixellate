//
//  MainViewController.swift
//  Pixellate
//
//  Created by Tom Nelson on 2/20/20.
//  Copyright © 2020 Inmotion Software. All rights reserved.
//

import UIKit
import CoreImage

class MainViewController: UIViewController {

    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var savedImageView: UIImageView!
    
    private var isDrawing = false
    private var lastPoint: CGPoint!
    private var strokeColor: CGColor = UIColor.black.cgColor
    private var strokes = [Stroke]()
    private let rootLayer = CALayer()
    private let maskLayer = CAShapeLayer()
    private let ciContext = CIContext()
    private var refreshControl = UIRefreshControl()

    @IBAction func saveAction(_ sender: UIButton) {
        let activity = UIActivityIndicatorView(style: .large)
        activity.color = .black
        self.view.addSubview(activity)
        let centerY = self.imageView.center.y + self.imageView.bounds.height / 2 + 30
        activity.center = CGPoint(x: self.imageView.center.x, y: centerY)
        activity.startAnimating()
        self.save()
        self.saveButton.isEnabled = false
        UIView.animate(withDuration: 0.5, animations: {
            self.imageView.alpha = 0.0
            self.savedImageView.alpha = 1.0
        }, completion: { _ in
            activity.removeFromSuperview()
            self.resetButton.isEnabled = true
        })
    }
    
    @IBAction func resetAction(_ sender: UIButton) {
//        self.saveButton.isEnabled = true
        self.savedImageView.image = nil
        self.strokes = [Stroke]()
        self.updateMaskLayer()
        self.loadImage()
        UIView.animate(withDuration: 0.5) {
            self.imageView.alpha = 1.0
            self.savedImageView.alpha = 0.0
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.rootLayer.frame = self.imageView.bounds
        self.rootLayer.mask = self.maskLayer
        self.maskLayer.frame = self.imageView.bounds
        self.maskLayer.strokeColor = UIColor.black.cgColor
        self.maskLayer.lineWidth = 35
        self.maskLayer.lineCap = .round
        self.imageView.layer.addSublayer(self.rootLayer)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isDrawing else { return }
        isDrawing = true
        guard let touch = touches.first else { return }
        let currentPoint = touch.location(in: self.imageView)
        lastPoint = currentPoint
        if !self.resetButton.isEnabled { self.saveButton.isEnabled = true }
        self.resetButton.isEnabled = false
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDrawing else { return }
        guard let touch = touches.first else { return }
        let currentPoint = touch.location(in: self.imageView)
        let stroke = Stroke(startPoint: lastPoint, endPoint: currentPoint, color: strokeColor)
        self.strokes.append(stroke)
        lastPoint = currentPoint
        self.updateMaskLayer()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDrawing else { return }
        isDrawing = false
        guard let touch = touches.first else { return }
        let currentPoint = touch.location(in: self.imageView)
        let stroke = Stroke(startPoint: lastPoint, endPoint: currentPoint, color: strokeColor)
        self.strokes.append(stroke)
        lastPoint = nil
        self.updateMaskLayer()
    }
    
    func loadImage() {
        guard let image =  UIImage(named: "paint") else { return }
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        let fileSize = Double(imageData.count / 1048576) //Convert in to MB
        let size = image.size
        print("picture size: \(size)")
        let scaleFactor = size.width / imageView.frame.width
        print("scale factor: \(scaleFactor)")

        print("Photo size in MB: ", fileSize)
        self.imageView.image = UIImage(data: imageData, scale: scaleFactor)
        guard let ciImage = filteredImage(self.imageView.image!) else { return }
        let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent)
        self.rootLayer.contents = cgImage
        self.resetButton.isEnabled = false
        self.saveButton.isEnabled = false
    }
    
    var maskPath: CGPath {
        let path = UIBezierPath()
        for stroke in self.strokes {
            path.move(to: stroke.startPoint)
            path.addLine(to: stroke.endPoint)
        }
        return path.cgPath
    }
    
    private func updateMaskLayer() {
        self.maskLayer.path = self.maskPath
    }
    
    func filteredImage(_ image: UIImage) -> CIImage? {
        guard let originalCIImage = CIImage(image: image) else { return nil }
        return pixellateFilter(originalCIImage, scale: 80.0)
    }

    func pixellateFilter(_ input: CIImage, scale: Double) -> CIImage? {
        let pixellateFilter = CIFilter(name:"CIPixellate")
        pixellateFilter?.setValue(input, forKey: kCIInputImageKey)
        pixellateFilter?.setValue(scale, forKey: "inputScale")
        return pixellateFilter?.outputImage
    }

    func save() {
        let start = DispatchTime.now().uptimeNanoseconds

        UIGraphicsBeginImageContextWithOptions(self.imageView.bounds.size, false, UIScreen.main.scale)
        self.imageView.drawHierarchy(in: self.imageView.bounds, afterScreenUpdates: true)
        let image2 = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: self.imageView.bounds.size, format: format)
        let image = renderer.image { ctx in
            view.drawHierarchy(in: self.imageView.bounds, afterScreenUpdates: true)
        }
        
        guard let data = image2?.pngData() else { return }
        let dataSize = Double(data.count / 1048576) //Convert in to MB
        print("Data size in MB: ", dataSize)
        let url = self.getDocumentsDirectory().appendingPathComponent("photo2.image")

        do {
            try data.write(to: url)
        } catch {
            print(error.localizedDescription)
        }

        do {
            let imageData = try Data.init(contentsOf: url)
            let fileSize = Double(imageData.count / 1048576) //Convert in to MB
            print("Photo size in MB: ", fileSize)
            let image1 = UIImage(data: imageData)
            let size = image1?.size
            print("picture size: \(size)")
            let scaleFactor = size!.width / self.savedImageView.frame.width
            print("scale factor: \(scaleFactor)")
            let image = UIImage(data: imageData, scale: scaleFactor)
            self.savedImageView.image = image
            let processtime = (DispatchTime.now().uptimeNanoseconds - start) / 1_000_000_000
            print("Time to retrieve photo was \(processtime) seconds")
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}


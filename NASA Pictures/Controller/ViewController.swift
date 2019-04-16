//
//  ViewController.swift
//  NASA Pictures
//
//  Created by Dmitry Novosyolov on 02/04/2019.
//  Copyright © 2019 Dmitry Novosyolov. All rights reserved.
//

import UIKit

class ViewController: UIViewController
{
    var shapeLayer: CAShapeLayer!
    var pulsatingLayer: CAShapeLayer!
    let percentageLabel: UILabel =
    {
        let label = UILabel()
        label.text = "...%"
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 30)
        label.textColor = .white
        return label
    }()
    
    var interval: Double = -86400
    {
        didSet
        {
            guard self.interval > 0.0 else { return }
            self.interval -= 86400
            print(#function, "Out of range!")
            updateUI()
        }
    }
    
    var photoInfo: PhotoInfo?
    {
        didSet
        {
            updateUI()
        }
    }
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var copyrightLabel: UILabel!
    
    private func setupNotificationObservers()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(handleEnterForground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc private func handleEnterForground() { animatePulsatingLayer() }
    
    private func createCircleShapeLayer(strokeColor: UIColor, fillColor: UIColor) -> CAShapeLayer
    {
        let circularPath = UIBezierPath(arcCenter: .zero, radius: 50, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        let layer = CAShapeLayer()
        layer.path = circularPath.cgPath
        layer.strokeColor = strokeColor.cgColor
        layer.lineWidth = 8
        layer.fillColor = fillColor.cgColor
        layer.lineCap = CAShapeLayerLineCap.round
        layer.position = self.view.center
        return layer
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Networking.shared.setSessionDelegate(self)
        
        setupNotificationObservers()
        setupCircleLayers()
        setupAnimationLabel()
        setupTextViewAndLabels()
        
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(swipesAction(sender:)))
        leftSwipe.direction = .left
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(swipesAction(sender:)))
        rightSwipe.direction = .right
        
        view.addGestureRecognizer(leftSwipe)
        view.addGestureRecognizer(rightSwipe)
        view.backgroundColor = UIColor.backgroundColor
        
        Networking.shared.fetchPhotoInfo(date: Date(timeIntervalSinceNow: interval)) { self.photoInfo = $0 }
    }
    
    private func setupTextViewAndLabels()
    {
        descriptionTextView.isEditable = false
        titleLabel.textColor = #colorLiteral(red: 0, green: 0.9914394021, blue: 1, alpha: 1)
        descriptionTextView.backgroundColor = .backgroundColor
        descriptionTextView.textColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        copyrightLabel.textColor = #colorLiteral(red: 0, green: 0.9914394021, blue: 1, alpha: 1)
    }
    
    private func setupAnimationLabel()
    {
        view.addSubview(percentageLabel)
        percentageLabel.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        percentageLabel.center = self.view.center
        
    }
    
    private func setupCircleLayers()
    {
        pulsatingLayer = createCircleShapeLayer(strokeColor: .clear, fillColor: UIColor.pulsatingFillColor)
        view.layer.addSublayer(pulsatingLayer)
        let trackLayer = createCircleShapeLayer(strokeColor: .trackStrokeColor, fillColor: .backgroundColor)
        view.layer.addSublayer(trackLayer)
        animatePulsatingLayer()
        shapeLayer = createCircleShapeLayer(strokeColor: .outlineStrokeColor, fillColor: .clear)
        shapeLayer.transform = CATransform3DMakeRotation(-CGFloat.pi / 2, 0, 0, 5)
        shapeLayer.strokeEnd = 0
        view.layer.addSublayer(shapeLayer)
    }
    
    private func animatePulsatingLayer()
    {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.toValue = 1.3
        animation.duration = 0.8
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        animation.autoreverses = true
        animation.repeatCount = Float.infinity
        pulsatingLayer.add(animation, forKey: "pulsing")
    }
    
    private func beginDownloadFile()
    {
        print(#function, "start to download file...")
        
        guard let urlSession = Networking.shared.session else { return }
        guard let url = photoInfo?.url else { return }
        let downloadTask = urlSession.downloadTask(with: url)
        downloadTask.resume()
    }
    
    @objc private func swipesAction(sender: UISwipeGestureRecognizer)
    {
        guard sender.state == .ended else { return }
        switch sender.direction
        {
        case .left:
            interval += 86400
            Networking.shared.fetchPhotoInfo(date: Date(timeIntervalSinceNow: interval)) { self.photoInfo = $0 }
        case .right:
            interval -= 86400
            Networking.shared.fetchPhotoInfo(date: Date(timeIntervalSinceNow: interval)) { self.photoInfo = $0 }
        default:
            break
        }
    }
    
    func updateUI()
    {
        beginDownloadFile()
        
        Networking.shared.fetchImage(url: photoInfo?.url) { image in
            
            OperationQueue.main.addOperation { self.imageView.image = image }
        }
        DispatchQueue.main.async
            {
            self.titleLabel.text = self.photoInfo?.title
            self.copyrightLabel.text = "\(self.photoInfo?.copyright ?? "") ©"
            self.descriptionTextView.text = self.photoInfo?.description
        }
    }
}

extension ViewController: URLSessionDownloadDelegate
{
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL)
    {
        
        
        print(#function, "finished download file!")
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    {
        let persentage = CGFloat(totalBytesWritten) / CGFloat(totalBytesExpectedToWrite)
        
        DispatchQueue.main.async
            {
                self.percentageLabel.text = "\(Int(persentage * 100))%"
                self.shapeLayer.strokeEnd = persentage
                self.percentageLabel.transform = CGAffineTransform(scaleX: persentage, y: persentage)
                
                if persentage < 0.0 { self.percentageLabel.text = "...%" }
        }
        print(persentage)
    }
}

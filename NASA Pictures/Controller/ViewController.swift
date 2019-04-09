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
    let shapeLayer = CAShapeLayer()
    let percentageLabel: UILabel =
    {
        let label = UILabel()
        label.text = "Start"
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 32)
        return label
    }()
    
    var interval: Double = -86400
    {
        didSet
        {
            guard self.interval > 0.0 else { return }
            self.interval -= 86400
            print(#function, "Out of range!")
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
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        view.addSubview(percentageLabel)
        percentageLabel.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        percentageLabel.center = view.center
        
        Networking.shared.setSessionDelegate(self)
        
//        let center = view.center
        let trackLayer = CAShapeLayer()
        
        let circularPath = UIBezierPath(arcCenter: .zero, radius: 100, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        
        trackLayer.path = circularPath.cgPath
        trackLayer.strokeColor = UIColor.lightGray.cgColor
        trackLayer.lineWidth = 10
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineCap = CAShapeLayerLineCap.round
        trackLayer.position = view.center
        
        view.layer.addSublayer(trackLayer)
        
        shapeLayer.path = circularPath.cgPath
        shapeLayer.strokeColor = UIColor.red.cgColor
        shapeLayer.lineWidth = 10
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineCap = CAShapeLayerLineCap.round
        shapeLayer.position = view.center
        
        shapeLayer.transform = CATransform3DMakeRotation(-CGFloat.pi / 2, 0, 0, 1)
        shapeLayer.strokeEnd = 0
        
        view.layer.addSublayer(shapeLayer)

        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(swipesAction(sender:)))
        leftSwipe.direction = .left
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(swipesAction(sender:)))
        rightSwipe.direction = .right
        
        view.addGestureRecognizer(leftSwipe)
        view.addGestureRecognizer(rightSwipe)
        
        descriptionTextView.isEditable = false
        Networking.shared.fetchPhotoInfo(date: Date(timeIntervalSinceNow: interval)) { self.photoInfo = $0 }
    }
    
    private func beginDownloadFile()
    {
//        shapeLayer.strokeEnd = 0
        
        guard let urlSession = Networking.shared.session else { return }
        guard let url = photoInfo?.url else { return }
        let downloadTask = urlSession.downloadTask(with: url)
        downloadTask.resume()
    }
    
//    fileprivate func animateCircle()
//    {
//        let basicAnimation = CABasicAnimation(keyPath: "strokeEnd")
//        basicAnimation.toValue = 1
//        basicAnimation.duration = 2
//        basicAnimation.fillMode = CAMediaTimingFillMode.forwards
//        basicAnimation.isRemovedOnCompletion = false
//
//        shapeLayer.add(basicAnimation, forKey: "urSoBasic")
//    }
    
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
            Networking.shared.fetchPhotoInfo(date: Date(timeIntervalSinceNow: interval)) { self.photoInfo = $0 }        default:
            break
        }
    }
    
    func updateUI()
    {
        print("Attempting to animate stroke")
        beginDownloadFile()
        Networking.shared.fetchImage(url: photoInfo?.url) { image in
            
            OperationQueue.main.addOperation
                {
                    self.imageView.image = image
            }
        }
        DispatchQueue.main.async
            {
                self.titleLabel.text = self.photoInfo?.title
                self.copyrightLabel.text = self.photoInfo?.copyright
                self.descriptionTextView.text = self.photoInfo?.description
        }
    }
}

extension ViewController: URLSessionDownloadDelegate
{
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL)
    {
        print("finished download file!")
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    {
        let persentage = CGFloat(totalBytesWritten) / CGFloat(totalBytesExpectedToWrite)
        
        DispatchQueue.main.async
            {
                self.percentageLabel.text = "\(Int(persentage * 100))%"
                self.shapeLayer.strokeEnd = persentage
        }
        
        print(persentage)
    }
    
}

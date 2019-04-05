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
    
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(swipesAction(sender:)))
        leftSwipe.direction = .left
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(swipesAction(sender:)))
        rightSwipe.direction = .right
        
        view.addGestureRecognizer(leftSwipe)
        view.addGestureRecognizer(rightSwipe)
        
        descriptionTextView.isEditable = false
        Networking.shared.fetchPhotoInfo(date: Date()) { self.photoInfo = $0 }
    }
    
    func updateUI()
    {
        Networking.shared.fetchImage(url: photoInfo?.url) { image in
            OperationQueue.main.addOperation
                {
                self.imageView.image = image
                    print(#function, Networking.shared.mapPhotoInfo)
            }
        }
        DispatchQueue.main.async
            {
                self.titleLabel.text = self.photoInfo?.title
                self.copyrightLabel.text = self.photoInfo?.copyright
                self.descriptionTextView.text = self.photoInfo?.description
        }
    }
    
    @objc func swipesAction(sender: UISwipeGestureRecognizer)
    {
        guard sender.state == .ended else { return }
        switch sender.direction
        {
        case .left:
            Networking.shared.fetchPhotoInfo(date: Date()) { self.photoInfo = $0 }
        case .right:
            Networking.shared.fetchPhotoInfo(date: Date()) { self.photoInfo = $0 }
        default:
            break
        }
    }
}

extension Date {
    func days(to secondDate: Date, calendar: Calendar = Calendar.current) -> Int {
        return calendar.dateComponents([.day], from: self, to: secondDate).day!
    }
}

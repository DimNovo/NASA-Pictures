//
//  Networking.swift
//  NASA Pictures
//
//  Created by Dmitry Novosyolov on 03/04/2019.
//  Copyright © 2019 Dmitry Novosyolov. All rights reserved.
//

import UIKit

class Networking
{
    static let shared = Networking()
    let formater = DateFormatter()
    var session: URLSession!
    var samplePhotoInfo = Array<Any>()
    
    private init() {}
    
    let baseURL = URL(string: "https://api.nasa.gov/planetary/apod")!
    var query = ["api_key": "put_here_your_key", "date": "2019-04-03"]
    
    func fetchPhotoInfo(date: Date, completion: @escaping (PhotoInfo?) -> Void)
    {
        formater.timeStyle = .none
        formater.dateFormat = "yyyy-MM-dd"
        query["date"] = formater.string(from: date)
        
        let url = baseURL.withQueries(query)!
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            
            guard let data = data else
            {
                if let error = error { print(#function, #line, error.localizedDescription) }
                completion(nil)
                return
            }
            
            let jsonDecoder = JSONDecoder()
            
            guard let photoInfo = try? jsonDecoder.decode(PhotoInfo.self, from: data) else
            {
                print(#function, #line, "Cant't decode data \(data)", self.formater.string(from: date))
                
                completion(self.samplePhotoInfo.last as? PhotoInfo)
                return
            }
            
            self.samplePhotoInfo.append(photoInfo)
            completion(photoInfo)
            
        }.resume()
    }
    
    func setSessionDelegate(_ delegate: URLSessionDelegate)
    {
        session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
    }
    
    func fetchImage(url: URL?, completion: @escaping (UIImage?) -> Void)
    {
        guard let url = url else {
            completion(nil)
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else {
                completion(nil)
                return
            }
            let image = UIImage(data: data)
            completion(image)
        }.resume()
    }
}

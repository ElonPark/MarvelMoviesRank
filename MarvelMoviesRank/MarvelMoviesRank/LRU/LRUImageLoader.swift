//
//  LRUImageLoader.swift
//  MarvelMoviesRank
//
//  Created by Elon on 10/03/2019.
//  Copyright © 2019 Elon. All rights reserved.
//

import UIKit
import Alamofire

class LRUImageLoader {
    
    private var capacity: Int
    private var cache: LRU<String, UIImage>
    
    ///LRU Cache capacity default `10`
    init(capacity: Int = 10) {
        self.capacity = capacity
        self.cache = LRU<String, UIImage>(capacity: capacity)
    }
    
    func getImage(key: String) -> UIImage? {
        return cache[key]
    }
    
    func setImage(urlString: String, completion: ((UIImage?) -> Void)? = nil) {
        var image: UIImage? = nil
        
        guard cache[urlString] == nil else {
            completion?(cache[urlString])
            return
        }
        
        Alamofire.request(urlString)
            .responseData {[weak self] (response) in
                defer {
                    completion?(image)
                }
                
                switch response.result {
                case .success(let data):
                    image = UIImage(data: data)
                    self?.cache[urlString] = image
                    
                case .failure(let error):
                    Log.error(error)
                }
        }
    }
    
    func clearCache() {
        cache.removeAll()
    }
    
    func cacheDescription() -> String {
        return cache.description
    }
}


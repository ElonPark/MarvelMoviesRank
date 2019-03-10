//
//  LRUImageLoader.swift
//  MarvelMoviesRank
//
//  Created by Elon on 10/03/2019.
//  Copyright © 2019 Elon. All rights reserved.
//

import UIKit
import Alamofire
import RxSwift

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
    
    func setImage(urlString: String) -> Observable<UIImage?> {
        return Observable.create { [weak self] observer in
            guard self?.cache[urlString] == nil else {
                observer.onNext(self?.cache[urlString])
                return Disposables.create()
            }
            
            Alamofire.request(urlString)
                .responseData { (response) in
                    switch response.result {
                    case .success(let data):
                        self?.cache[urlString] = UIImage(data: data)
                        observer.onNext(self?.cache[urlString])
                        
                    case .failure(let error):
                        Log.error(error)
                        observer.onError(error)
                    }
            }
            return Disposables.create()
        }
    }
    
    func clearCache() {
        cache.removeAll()
    }
    
    func cacheDescription() -> String {
        return cache.description
    }
}


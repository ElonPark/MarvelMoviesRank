//
//  HTMLLoader.swift
//  MarvelMoviesRank
//
//  Created by Elon on 07/03/2019.
//  Copyright © 2019 Elon. All rights reserved.
//

import Foundation
import Alamofire
import RxSwift


///HTML Loader
struct HTMLLoader {
    ///요청할 주소
    static let baseURL = "https://www.thewrap.com/marvel-movies-ranked-worst-best-avengers-infinity-war-ant-man-venom-stan-lee-spider-man-into-the-spider-verse/"
    
    static func loadHTML() -> Observable<[MarvelMovie]> {
        return Observable.create { observer in
            Alamofire.request(baseURL, method: .get)
                .responseString { (response) in
                    switch response.result {
                    case .success(let htmlString):
                        let html = HTMLParser(htmlString: htmlString)
                        if let parserError = html.parserError {
                            Log.error(parserError.localizedDescription)
                            observer.onError(parserError)
                        } else {
                            observer.onNext(html.parsingData())
                        }
             
                    case .failure(let error):
                        Log.error(error.localizedDescription)
                        observer.onError(error)
                    }
            }
            
            return Disposables.create()
        }
    }
}

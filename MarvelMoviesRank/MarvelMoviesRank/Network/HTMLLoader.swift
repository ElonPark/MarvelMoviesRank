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
    
    ///아이폰 사파리로 유저에이전트 변경
//    static let headers = ["User-Agent" : "Mozilla/5.0 (iPhone; CPU iPhone OS 11_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/11.0 Mobile/15E148 Safari/604.1"]
    
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

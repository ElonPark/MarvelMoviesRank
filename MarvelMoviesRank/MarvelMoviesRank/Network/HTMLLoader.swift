//
//  HTMLLoader.swift
//  MarvelMoviesRank
//
//  Created by Elon on 07/03/2019.
//  Copyright © 2019 Elon. All rights reserved.
//

import Foundation
import Alamofire

///HTML Loader
struct HTMLLoader {
    ///요청할 주소
    static let baseURL = "https://www.thewrap.com/marvel-movies-ranked-worst-best-avengers-infinity-war-ant-man-venom-stan-lee-spider-man-into-the-spider-verse/"
    
    ///아이폰 사파리로 유저에이전트 변경
    static let headers = ["User-Agent" : "Mozilla/5.0 (iPhone; CPU iPhone OS 11_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/11.0 Mobile/15E148 Safari/604.1"]
    
    static func loadHTML() {
        Alamofire.request(baseURL, method: .get, headers: headers)
            .responseString { (response) in
                switch response.result {
                case .success(let htmlString):
                    //FIXME: 테스트용
                    #warning ("FIXME: 테스트용")
                    let html = HTMLParser(htmlString: htmlString)
                    html.parser()
                    
                case .failure(let error):
                    Log.error(error.localizedDescription)
                }
        }
    }
}

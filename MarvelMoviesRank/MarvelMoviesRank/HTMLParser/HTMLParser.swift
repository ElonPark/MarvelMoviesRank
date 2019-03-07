//
//  HTMLParser.swift
//  MarvelMoviesRank
//
//  Created by Elon on 07/03/2019.
//  Copyright © 2019 Elon. All rights reserved.
//

import Foundation
import Kanna

extension HTMLParser {
    enum HTMLParserError: Error {
        case xPath
        
        var errorDescription: String? {
            switch self {
            case .xPath:
                return NSLocalizedString("목록을 가져오는데 실패 하였습니다.",
                                         comment: "HTML parsing Error")
            }
        }
    }
}

class HTMLParser {
    
    var htmlString: String = ""
    var parserError: Error? = nil
    
    init(htmlString: String) {
        self.htmlString = htmlString
    }
    
    func document(by html: String) -> HTMLDocument? {
        var document: HTMLDocument? = nil
        
        do {
            document = try HTML(html: html, encoding: .utf8)
            
        } catch {
            parserError = error
            Log.error(error.localizedDescription)
        }
        
        return document
    }
    
    func splitRankAndName(by title:String) -> (Int, String) {
        var rank: Int = 0
        var movie: String = ""
        let removeQuotation = title.replacingOccurrences(of: "\"", with: "")
        let titleArray = removeQuotation.components(separatedBy: ". ")
        
        if titleArray.count > 1 {
            rank = Int(titleArray[0]) ?? 0
            movie = titleArray[1]
        }
        
        return (rank, movie)
    }
    
    func imageURL(by item: XMLElement) -> String {
        var imageURL: String = ""
        let imagePath = "div[@class='image-wrap']/a[@class='imagelink']"
        let srcPath = imagePath + "/img[@class='image']"
        let dataSrcPath = imagePath + "/img[@class='image lazy']"
        
        if let src = item.at_xpath(srcPath)?["src"] {
            imageURL = src
        } else if let dataSrc = item.at_xpath(dataSrcPath)?["data-src"] {
            imageURL = dataSrc
        }
        
        return imageURL
    }
    
    func parsingData() -> [MarvelMovie] {
        var movies = [MarvelMovie]()
        
        ///xPath
        let galleryWrapPhotosPath = "//div[@class='gallery-wrap photos']"
        let itemPath = "div[@class='item-wrap']"
        
        let titlePath = "div[@class='caption']/strong"
        

        guard let document = document(by: htmlString) else {
            return movies
        }
        
        guard let element = document.at_xpath(galleryWrapPhotosPath) else {
            parserError = HTMLParserError.xPath
            return movies
        }
   
        for item in element.xpath(itemPath) {
            var rank: Int = 0
            var movie: String = ""
            var imagePath: String = ""
            
            //strong 태그로 제목이 달린 경우에만 제목, 이미지 가져옴
            guard let title = item.at_xpath(titlePath)?.content else { continue }
            (rank, movie) = splitRankAndName(by: title)
            imagePath = imageURL(by: item)
            
            let marvelMovie = MarvelMovie(rank: rank, title: movie, imageURL: imagePath)
            print(marvelMovie)
            movies.append(marvelMovie)
        }
        
        return movies
    }
}

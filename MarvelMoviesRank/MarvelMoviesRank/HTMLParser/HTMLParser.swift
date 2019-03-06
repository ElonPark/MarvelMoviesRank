//
//  HTMLParser.swift
//  MarvelMoviesRank
//
//  Created by Elon on 07/03/2019.
//  Copyright © 2019 Elon. All rights reserved.
//

import Foundation
import Kanna

struct HTMLParser {
    
    var htmlString: String
    
    func document(by html: String) -> HTMLDocument? {
        var document: HTMLDocument? = nil
        
        do {
            document = try HTML(html: html, encoding: .utf8)
            
        } catch {
            Log.error(error.localizedDescription)
        }
        
        return document
    }
    
    func parser() {
        ///xPath
        let galleryWrapPhotosPath = "//div[@class='gallery-wrap photos']"
        let itemPath = "div[@class='item-wrap']"
        
        let titlePath = "div[@class='caption']/strong"
        
        let imagePath = "div[@class='image-wrap']/a[@class='imagelink']"
        let srcPath = imagePath + "/img[@class='image']"
        let dataSrcPath = imagePath + "/img[@class='image lazy']"
        
        guard let doc = document(by: htmlString) else { return }
        guard let element = doc.at_xpath(galleryWrapPhotosPath) else { return }
   
        for item in element.xpath(itemPath) {
            guard let title = item.at_xpath(titlePath)?.content else { continue }
            print(title)
            
            //strong 태그로 제목이 달린 경우에만 이미지 주소 가져옴
            if let src = item.at_xpath(srcPath)?["src"] {
                print(src)
            } else if let dataSrc = item.at_xpath(dataSrcPath)?["data-src"] {
                print(dataSrc)
            }
        }
    }
}

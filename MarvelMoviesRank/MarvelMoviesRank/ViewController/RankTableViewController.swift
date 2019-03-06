//
//  RankTableViewController.swift
//  MarvelMoviesRank
//
//  Created by Elon on 07/03/2019.
//  Copyright © 2019 Elon. All rights reserved.
//

import UIKit

extension RankTableViewController {
    
    func prefersLargeTitles() {
        let navigationBar = navigationController?.navigationBar
        navigationBar?.prefersLargeTitles = true
    }
}

/// - TODO: 사이트 웹 소스를 파싱 [Link](https://www.thewrap.com/marvel-movies-ranked-worst-best-avengers-infinity-war-ant-man-venom-stan-lee-spider-man-into-the-spider-verse/)
/// - TODO: 각 이미지와 정보를 갖는 리스트 생성 (순위, 타이틀)
/// - TODO: 출력은 1위부터 20개 단위로 정보 로딩
/// - TODO: 리스트에서 보여주는 이미지를 캐쉬
/// - TODO: LRU 알고리즘이 적용된 ImageLoader 방식으로 이미지를 캐쉬하여 로딩
/// - TODO: 리스트 아이템 클릭시 원본 이미지 화면
class RankTableViewController: UIViewController {

    @IBOutlet weak var movieTableView: UITableView!
    
    override func loadView() {
        super.loadView()
        prefersLargeTitles()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //FIXME: 테스트용
        #warning ("FIXME: 테스트용")
        Log.verbose("로딩 시작")
        HTMLLoader.loadHTML()
        
    }
}


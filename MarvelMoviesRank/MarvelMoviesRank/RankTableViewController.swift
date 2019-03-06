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


class RankTableViewController: UIViewController {

    @IBOutlet weak var movieTableView: UITableView!
    
    override func loadView() {
        prefersLargeTitles()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        
    }
}


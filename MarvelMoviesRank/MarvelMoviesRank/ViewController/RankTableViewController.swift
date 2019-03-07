//
//  RankTableViewController.swift
//  MarvelMoviesRank
//
//  Created by Elon on 07/03/2019.
//  Copyright © 2019 Elon. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import NVActivityIndicatorView
import Kingfisher

extension RankTableViewController {
    
    func startLoading() {
        let size = CGSize(width: 40, height: 40)
        let message = "데이터를 불러오는 중입니다."
        startAnimating(size, message: message, type: .circleStrokeSpin)
    }
    
    func prefersLargeTitles() {
        let navigationBar = navigationController?.navigationBar
        navigationBar?.prefersLargeTitles = true
    }
    
    func setMovieTableView() {
        movieTableView.delegate = nil
        movieTableView.dataSource = nil
        
        movieTableView.rowHeight = UITableView.automaticDimension
        movieTableView.estimatedRowHeight = defaultCellSize
    }
    
    func errorAlert(_ error: Error) {
        let alert = UIAlertController(title: "",
                                      message: error.localizedDescription,
                                      preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "확인", style: .cancel)
        
        alert.addAction(okAction)
        
        present(alert, animated: true)
    }
    
    func sotedChunk(movies: [MarvelMovie]) -> [MarvelMovie] {
        let ranking = movies.sorted { $0.rank < $1.rank }
        dataChunks = ranking.chunked(into: 20)
        
        return dataChunks[page]
    }
    
    func loadMovieList() {
        startLoading()
        let scheduler = ConcurrentDispatchQueueScheduler(qos: .userInteractive)
        
        Log.verbose("로딩 시작")
        HTMLLoader.loadHTML()
            .retry(2)
            .observeOn(scheduler)
            .map { [weak self] movies -> [MarvelMovie] in
                guard let `self` = self else { return [] }
                return self.sotedChunk(movies: movies)
            }
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] movies in
                self?.dataSource.accept(movies)
                self?.stopAnimating()
                
                }, onError: { [weak self] error in
                    self?.stopAnimating()
                    self?.errorAlert(error)
            })
            .disposed(by: disposeBag)
    }
    
    func dataBinding() {
        dataSource.asDriver()
            .drive(movieTableView.rx.items(cellIdentifier: MovieCell.identifier, cellType: MovieCell.self)) {(_, model, cell) in
                cell.titleLabel.text = "\(model.rank). \(model.title)"
                
                cell.movieImageView.kf.indicatorType = .activity
                //FIXME: 추후 LRU 알고리즘이 적용된 ImageLoader로 변경
                let url = URL(string: model.imageURL)
                cell.movieImageView.kf.setImage(with: url)
            }
            .disposed(by: disposeBag)
    }
    
    func isCloseScrollBottom(offset: CGPoint) -> Bool {
        let size = offset.y + movieTableView.frame.size.height + defaultCellSize
        return size > movieTableView.contentSize.height
    }
    
    func updateDatasoruce() {
        guard page < dataChunks.count - 1 else { return }
        page += 1
        Log.debug("page: \(page)")
        dataSource.accept(dataSource.value + dataChunks[page])
    }
    
    func updateTableView() {
        movieTableView.rx
            .contentOffset
            .asDriver()
            .drive(onNext: { contentOffset in
                guard self.isCloseScrollBottom(offset: contentOffset) else { return }
                self.updateDatasoruce()
            })
            .disposed(by: disposeBag)
    }
    
    func showImage(with index: IndexPath) {
        Log.debug("select \(index.row)")
        guard let imageVC = MovieImageViewController.instantiateVC() else { return }
        let cell = movieTableView.cellForRow(at: index) as? MovieCell
        imageVC.image = cell?.movieImageView.image
        
        navigationController?.pushViewController(imageVC, animated: true)
    }
    
    func selecteItem() {
        movieTableView.rx
            .itemSelected
            .observeOn(MainScheduler.instance)
            .bind { [weak self] (index) in
                self?.showImage(with: index)
            }
            .disposed(by: disposeBag)
    }
}

/// - TODO: 리스트에서 보여주는 이미지를 캐쉬
/// - TODO: LRU 알고리즘이 적용된 ImageLoader 방식으로 이미지를 캐쉬하여 로딩
class RankTableViewController: UIViewController, NVActivityIndicatorViewable {

    @IBOutlet weak var movieTableView: UITableView!
    
    let disposeBag = DisposeBag()
    
    let defaultCellSize: CGFloat = 250
    
    var page: Int = 0
    var dataChunks = [[MarvelMovie]]()
    lazy var dataSource = BehaviorRelay(value: [MarvelMovie]())
    
    override func loadView() {
        super.loadView()
        prefersLargeTitles()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setMovieTableView()
        
        loadMovieList()
        dataBinding()
        selecteItem()
        updateTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
    }
}


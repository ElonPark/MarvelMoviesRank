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
    
    func cacheConfig() {
        let cache = ImageCache.default
        ///메로리 캐시 용량 제한 100MB
        cache.memoryStorage.config.totalCostLimit = 100 * 1024 * 1024
        ///메모리 캐시 갯수 제한
        cache.memoryStorage.config.countLimit = 40
        ///디스트 캐시 용량 제한 500MB, 초과할 경우 LRU 방식으로 정리됨
        cache.diskStorage.config.sizeLimit = 500 * 1024 * 1024
    }
    
    ///리스트에 보여줄 이미지를 캐시
    func prefetchImage(by movies: [MarvelMovie]) {
        let urls = movies.compactMap { URL(string: $0.imageURL) }
        imageURLs.append(contentsOf: urls)
        
        let prefetcher = ImagePrefetcher(urls: urls)
        prefetcher.start()
    }
    
    ///순위대로 정렬 후,  20개 단위로 로딩할 수 있도록 분할
    func sortedChunk(movies: [MarvelMovie]) -> [MarvelMovie] {
        let ranking = movies.sorted { $0.rank < $1.rank }
        dataChunks = ranking.chunked(into: 20)
        
        return dataChunks[page]
    }
    
    func loadMovieList() {
        startLoading()
        let scheduler = ConcurrentDispatchQueueScheduler(qos: .background)
        
        Log.verbose("로딩 시작")
        HTMLLoader.loadHTML()
            .observeOn(scheduler)
            .retry(2) //실패시 2번까지 재시도
            .map { [weak self] movies -> [MarvelMovie] in
                guard let `self` = self else { return [] }
                let chunk = self.sortedChunk(movies: movies)
                self.prefetchImage(by: chunk)
                return chunk
            }
            .observeOn(scheduler)
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
            .drive(movieTableView.rx.items(cellIdentifier: MovieCell.identifier, cellType: MovieCell.self)) { [weak self] row, model, cell in
                cell.titleLabel.text = "\(model.rank). \(model.title)"
                cell.movieImageView.kf.indicatorType = .activity

                //LRU 알고리즘이 적용된 ImageLoader
                //Kingfisher는 디스크 캐시를 LRU 알고리즘을 사용하여 정리함
                // https://github.com/onevcat/Kingfisher/issues/404#issuecomment-240347946
                
                //캐시에서 이미지 가져옴
                if let url = self?.imageURLs[row] {
                    cell.movieImageView.kf.setImage(with: url)
                }
                
            }
            .disposed(by: disposeBag)
    }
    
    ///스크롤이 바닥 근처인지
    func isCloseScrollBottom(offset: CGPoint) -> Bool {
        let size = offset.y + movieTableView.frame.size.height + defaultCellSize
        return size > movieTableView.contentSize.height
    }
    
    ///분할 해놓은 다음 데이터를 로딩하도록 업데이트
    func updateDataSoruce() {
        guard page < dataChunks.count - 1 else { return }
        page += 1
        Log.debug("page: \(page)")
        prefetchImage(by: dataChunks[page])
        dataSource.accept(dataSource.value + dataChunks[page])
    }
    
    func updateTableViewByScroll() {
        movieTableView.rx
            .contentOffset
            .asDriver()
            .drive(onNext: { contentOffset in
                guard self.isCloseScrollBottom(offset: contentOffset) else { return }
                self.updateDataSoruce()
            })
            .disposed(by: disposeBag)
    }
    
    ///선택된 셀의 이미지 보여줌
    func showImage(with index: IndexPath) {
        Log.debug("select \(index.row)")
        guard let imageVC = MovieImageViewController.instantiateVC() else { return }
        let cell = movieTableView.cellForRow(at: index) as? MovieCell
        imageVC.image = cell?.movieImageView.image
        
        navigationController?.pushViewController(imageVC, animated: true)
    }
    
    ///셀 선택시
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


class RankTableViewController: UIViewController, NVActivityIndicatorViewable {

    @IBOutlet weak var movieTableView: UITableView!
    
    let disposeBag = DisposeBag()
    
    ///기본 셀 크기
    let defaultCellSize: CGFloat = 250
    
    ///분할된 데이터를 저장하기 위함
    var dataChunks = [[MarvelMovie]]()
    
    ///분할된 데이터에서 가져올 페이지
    var page: Int = 0
   
    ///테이블뷰 데이터 소스
    lazy var dataSource = BehaviorRelay(value: [MarvelMovie]())
    
    ///미리 불러오기 위한 이미지 URL 배열
    var imageURLs = [URL]()
    
    override func loadView() {
        super.loadView()
        prefersLargeTitles()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setMovieTableView()
        
        cacheConfig()
        loadMovieList()
        dataBinding()
        selecteItem()
        updateTableViewByScroll()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
    }
}


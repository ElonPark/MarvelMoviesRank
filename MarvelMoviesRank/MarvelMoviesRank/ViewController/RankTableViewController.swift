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
                return chunk
            }
            .observeOn(MainScheduler.instance)
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
            .drive(movieTableView.rx.items(cellIdentifier: MovieCell.identifier, cellType: MovieCell.self)) { row, model, cell in
                cell.titleLabel.text = "\(model.rank). \(model.title)"
                cell.movieImageView.kf.indicatorType = .activity

                //LRU 알고리즘이 적용된 ImageLoader
                //Kingfisher는 디스크 캐시를 LRU 알고리즘을 사용하여 정리함
                // https://github.com/onevcat/Kingfisher/issues/404#issuecomment-240347946
                
                //Kingfisher는 캐시된 이미지가 있는 경우 캐시된 이미지를 보여주고, 이미지가 없을 경우만 다운로드를 진행함
                if let url = URL(string: model.imageURL) {
                    //셀 이미지뷰 사이즈로 다운샘플링 해서 보여줌
                    let downsampling = DownsamplingImageProcessor(size: cell.movieImageView.bounds.size)
                    cell.movieImageView.kf.setImage(with: url, options: [
                        .processor(downsampling),
                        .scaleFactor(UIScreen.main.scale),
                         //캐시가 존재하지 않아 다운로드를 진행한 경우, 원본 이미지는 디스크 캐시에 캐시
                        .cacheOriginalImage
                        ])
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
    
    ///이미지를 보여주기 위해 이미지 VC로 이동
    func moveToMovieImageVC(with index: IndexPath) {
        Log.debug("select \(index.row)")
        guard let imageVC = MovieImageViewController.instantiateVC() else { return }
        
        imageVC.imageURL = dataSource.value[index.row].imageURL
        
        navigationController?.pushViewController(imageVC, animated: true)
    }
    
    ///셀 선택시
    func selecteItem() {
        movieTableView.rx
            .itemSelected
            .observeOn(MainScheduler.instance)
            .bind { [weak self] (index) in
                self?.moveToMovieImageVC(with: index)
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


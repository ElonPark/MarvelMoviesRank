//
//  MovieImageViewController.swift
//  MarvelMoviesRank
//
//  Created by Elon on 08/03/2019.
//  Copyright © 2019 Elon. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Kingfisher

extension MovieImageViewController: UIScrollViewDelegate {
    
    func setScrollView() {
        scrollView.alwaysBounceVertical = false
        scrollView.alwaysBounceHorizontal = false
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        scrollView.delegate = self
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return movieImageView
    }
    
    func close() {
        cancelButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                self?.navigationController?
                    .popViewController(animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    
    func setMovieImage() {
        guard let url = URL(string: imageURL) else { return }
        //원본 이미지 설정
        movieImageView.kf.setImage(with: url, options: [.originalCache(ImageCache.default)])
    }
}

class MovieImageViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var movieImageView: UIImageView!
    @IBOutlet weak var cancelButton: UIButton!
    
    var imageURL: String = ""
    let disposeBag = DisposeBag()
    
    class func instantiateVC() -> MovieImageViewController? {
        let identifier = "MovieImageViewController"
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let imageVC = storyboard.instantiateViewController(withIdentifier: identifier)
        
        return imageVC as? MovieImageViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setScrollView()
        close()
        setMovieImage()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }
}

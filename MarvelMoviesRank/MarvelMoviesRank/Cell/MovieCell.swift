//
//  MovieCell.swift
//  MarvelMoviesRank
//
//  Created by Elon on 07/03/2019.
//  Copyright © 2019 Elon. All rights reserved.
//

import UIKit

class MovieCell: UITableViewCell {

    @IBOutlet weak var movieImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    static let identifier = "MovieCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        movieImageView.image = nil
        titleLabel.text = ""
    }
}

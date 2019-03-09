//
//  StoryboardExtension.swift
//  MarvelMoviesRank
//
//  Created by Elon on 08/03/2019.
//  Copyright © 2019 Elon. All rights reserved.
//

import UIKit

extension UIStoryboard {
    func instantiateVC<T: UIViewController>() -> T? {
        if let name = NSStringFromClass(T.self).components(separatedBy: ".").last {
            return instantiateViewController(withIdentifier: name) as? T
        }
        return nil
    }
}

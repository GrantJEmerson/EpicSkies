//
//  SkyImageFullResolution.swift
//  EpicSkies
//
//  Created by Grant Emerson on 8/19/17.
//  Copyright © 2017 com.CelebrityGames. All rights reserved.
//  Membership to all Targets

import UIKit
import CloudKit

// MARK: - Sky Original Image Model

struct SkyImageFullResolution {
    
    let picture: CKAsset
    let image: UIImage?
    
    init(picture: CKAsset) {
        self.picture = picture
        image = UIImage(contentsOfFile: self.picture.fileURL.path)
    }
}

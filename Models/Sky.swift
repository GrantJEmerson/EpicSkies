//
//  Sky.swift
//  EpicSkies
//
//  Created by Grant Emerson on 7/27/17.
//  Copyright © 2017 com.CelebrityGames. All rights reserved.
//  Membership to all Targets 

import UIKit
import CloudKit

// MARK: - Sky Model

struct Sky {
    
    let name: String
    let type: String
    let date: Date
    let location: CLLocation
    let picture: CKAsset
    
    let likes: Int
    let flags: Int
    
    var likedBy: [CKReference]
    var flaggedBy: [CKReference]
    
    let originalImage: CKReference
    
    let image: UIImage?
    
    init (name:String, type:String, date:Date, location:CLLocation, picture:CKAsset, likes:Int, flags:Int,
          likedBy: [CKReference], flaggedBy: [CKReference], originalImage: CKReference) {
        self.name = name
        self.type = type
        self.date = date
        self.location = location
        self.picture = picture
        
        self.likes = likes
        self.flags = flags
        
        self.likedBy = likedBy
        self.flaggedBy = flaggedBy
        
        self.originalImage = originalImage

        image = UIImage(contentsOfFile: self.picture.fileURL.path)
    }

}

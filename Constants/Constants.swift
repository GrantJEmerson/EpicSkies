//
//  Constants.swift
//  EpicSkies
//
//  Created by Grant Emerson on 9/27/17.
//  Copyright © 2017 com.CelebrityGames. All rights reserved.
//  Membership to multiple Targets

import Foundation
import UIKit

// MARK: - Universal Constants

struct Constants {
    
    // MARK: - Constants
    
    let skyTypes = ["Clouds", "Sunset", "Sunrise", "Storm", "Rain", "Snow", "Tornado/Hurricane", "Rainbow", "Eclipse"]
    let sortSkyTypes = ["All", "Clouds", "Sunset", "Sunrise", "Storm", "Rain", "Snow", "Tornado/Hurricane", "Rainbow", "Eclipse"]
    let sortDescriptors = ["Date: Newest First", "Date: Oldest First", "Closest Location", "Most Likes"]
    
    let defaultButtonColor = UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
    
    // Private Data
    let containerIdentifier = ""
    let adAppID = ""
    let adUnitID = ""
    let testDeviceID = ""
    
    // MARK: - Singleton Declaration
    
    static let sharedInstance = Constants()
}

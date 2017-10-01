//
//  SkyLocationInterfaceController.swift
//  EpicSkies
//
//  Created by Grant Emerson on 9/1/17.
//  Copyright © 2017 com.CelebrityGames. All rights reserved.
//

import WatchKit
import Foundation


class SkyLocationInterfaceController: WKInterfaceController {
    
    // MARK: - Properties
    
    @IBOutlet var mapView: WKInterfaceMap!
    
    // MARK: - Interface Life Cycle

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        if let location = context as? CLLocation {
            mapView.addAnnotation(location.coordinate, with: WKInterfaceMapPinColor.red)
        }
    }

}

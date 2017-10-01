//
//  SkyDetailViewController.swift
//  EpicSkies
//
//  Created by Grant Emerson on 9/1/17.
//  Copyright © 2017 com.CelebrityGames. All rights reserved.
//

import WatchKit
import Foundation
import CoreLocation


class SkyDetailViewController: WKInterfaceController {
    
    // MARK: - Properties
    
    private var location: CLLocation!
    
    @IBOutlet var skyImageView: WKInterfaceImage!
    @IBOutlet var skyNameLabel: WKInterfaceLabel!
    @IBOutlet var skyLocationLabel: WKInterfaceLabel!
    @IBOutlet var skyTypeLabel: WKInterfaceLabel!
    @IBOutlet var skyDateLabel: WKInterfaceLabel!
    
    // MARK: - Interface Life Cycle
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        guard let sky = context as? Sky else { return }
        
        skyImageView.setImage(sky.image)
        skyNameLabel.setText(sky.name)
        skyTypeLabel.setText(sky.type)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        skyDateLabel.setText(dateFormatter.string(from: sky.date))
        
        CLGeocoder().reverseGeocodeLocation(sky.location) { (placeMarks, error) in
            if error != nil {
                print(error?.localizedDescription ?? "")
            } else {
                self.skyLocationLabel.setText(placeMarks?.first?.name ?? "unknown")
            }
        }
        
        location = sky.location
    }
    
    // MARK: - Navigation
    
    override func contextForSegue(withIdentifier segueIdentifier: String) -> Any? {
        if segueIdentifier == "showMap" {
            return location
        }
        return nil
    }

}

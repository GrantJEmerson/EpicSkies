//
//  FadeInSegue.swift
//  EpicSkies
//
//  Created by Grant Emerson on 8/22/17.
//  Copyright © 2017 com.CelebrityGames. All rights reserved.
//

import UIKit

class FadeInSegue: UIStoryboardSegue {
    
    // MARK: - Segue Used For Animated Splash Screen
    
    override func perform() {
        let sourceViewController = self.source
        
        let transition: CATransition = CATransition()
        
        transition.duration = 0.65
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        transition.type = kCATransitionFade
        
        sourceViewController.view.window?.layer.add(transition, forKey: kCATransition)
        sourceViewController.present(self.destination, animated: false, completion: nil)
    }
}

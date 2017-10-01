//
//  SplashScreenViewController.swift
//  EpicSkies
//
//  Created by Grant Emerson on 8/22/17.
//  Copyright © 2017 com.CelebrityGames. All rights reserved.
//

import UIKit

class SplashScreenViewController: UIViewController {
    
    // MARK: - Properties
    
    @IBOutlet weak var Cloud1: UIImageView!
    @IBOutlet weak var Cloud2: UIImageView!
    @IBOutlet weak var Cloud3: UIImageView!
    @IBOutlet weak var Cloud4: UIImageView!
    @IBOutlet weak var Cloud5: UIImageView!
    @IBOutlet weak var EpicSkiesSplashImage: UIImageView!
    
    // MARK: - ViewController Life Cycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateSplashScreenUI()
        
        let h = view.frame.height
        let w = view.frame.width
        
        Cloud1.center = CGPoint(x: w * 0.427, y: h * 0.184)
        Cloud2.center = CGPoint(x: w * 0.08, y: h * 0.279)
        Cloud3.center = CGPoint(x: w * 0.469, y: h * 0.544)
        Cloud4.center = CGPoint(x: w * 0.091, y: h * 0.6)
        Cloud5.center = CGPoint(x: w * 0.392, y: h * 0.751)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animate(withDuration: 4, delay: 0, options: [.curveEaseInOut], animations: {
            self.Cloud1.center.x = self.view.frame.width + self.Cloud1.bounds.width
        }, completion: nil)
        UIView.animate(withDuration: 4, delay: 0, options: [.curveEaseInOut], animations: {
            self.Cloud2.center.x = self.view.frame.width + self.Cloud2.bounds.width
        }, completion: nil)
        UIView.animate(withDuration: 3.75, delay: 0.25, options: [.curveEaseInOut], animations: {
            self.Cloud3.center.x = self.view.frame.width + self.Cloud3.bounds.width
        }, completion: nil)
        UIView.animate(withDuration: 3.75, delay: 0.25, options: [.curveEaseInOut], animations: {
            self.Cloud4.center.x = self.view.frame.width + self.Cloud4.bounds.width
        }, completion: nil)
        UIView.animate(withDuration: 4, delay: 0.25, options: [.curveEaseInOut], animations: {
            self.Cloud5.center.x = self.view.frame.width + self.Cloud5.bounds.width
        }) { (_) in
            self.performSegue(withIdentifier: "launchApp", sender: self)
        }
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        updateSplashScreenUI()
    }
    
    // MARK: - Private Functions
    
    private func updateSplashScreenUI() {
        let h = view.frame.height
        let w = view.frame.width
        
        let clouds = [Cloud1, Cloud2, Cloud3, Cloud4, Cloud5]
        
        for cloud in clouds {
            cloud?.bounds.size = CGSize(width: w * 0.363, height: h * 0.079)
        }
    }
}

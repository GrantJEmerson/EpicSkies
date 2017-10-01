//
//  FirstViewController.swift
//  EpicSkiesAppleTVExtension
//
//  Created by Grant Emerson on 9/1/17.
//  Copyright © 2017 com.CelebrityGames. All rights reserved.
//

import UIKit
import CloudKit

// MARK: - Public Protocols

public protocol RestartSkySlideShow {
    func restartSkySlideShow()
}

class SkyImageSlideShowViewController: UIViewController, UIScrollViewDelegate {
    
    // MARK: - Properties
    
    private var skies = [Sky]()
    private var records = [CKRecord]()
    
    private var selectedSky: Sky?
    private var selectedRecordID: CKRecordID?
    
    fileprivate var timer: Timer?
    
    fileprivate var nextImage = UIImage()
    
    private var fetching = false
    fileprivate var index = 0
    
    private let cloud = Service.sharedInstance
    private var cursor: CKQueryCursor?
    
    private var secondsPerSlide = 5
    private var skyType = "All"
    private var dontShowNameAndDate = false
    
    private var settings = UserDefaults()
    
    private var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        return dateFormatter
    }()
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var skyNameAndDateLabel: UITextView! {
        didSet {
            skyNameAndDateLabel.layer.shadowColor = UIColor.black.cgColor
            skyNameAndDateLabel.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
            skyNameAndDateLabel.layer.shadowOpacity = 1.0
            skyNameAndDateLabel.layer.shadowRadius = 2.0
            skyNameAndDateLabel.layer.backgroundColor = UIColor.clear.cgColor
            skyNameAndDateLabel.isSelectable = true
        }
    }
    
    // MARK: - ViewController Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.contentSize = imageView.bounds.size

        loadData()
        
        if let settingsVC = tabBarController?.viewControllers?[1] as? SettingsViewController {
            settingsVC.delegate = self
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let settingsStoredSecondsPerSlide = settings.integer(forKey: "secondsPerSlide")
        if settingsStoredSecondsPerSlide != 0 {
            secondsPerSlide = settingsStoredSecondsPerSlide
        }
        let settingsStoredSkyType = settings.string(forKey: "skyType")
        if settingsStoredSkyType != nil {
            skyType = settingsStoredSkyType!
        }
        dontShowNameAndDate = settings.bool(forKey: "dontShowNameAndDate")
    }
    
    // MARK: - Private Functions
    
    @objc private func changeSkyImage() {
        
        UIView.transition(with: imageView, duration: 1, options: .transitionCrossDissolve, animations: {
            self.scrollView.zoomScale = 1
            self.imageView.image = self.nextImage
            if self.dontShowNameAndDate == true {
                self.skyNameAndDateLabel.text = ""
            } else {
                self.skyNameAndDateLabel.text = "\(self.skies[self.index].name) - \(self.dateFormatter.string(from: self.skies[self.index].date))"
            }
        })
        
        UIView.animate(withDuration: TimeInterval(secondsPerSlide), animations: {
            self.scrollView.zoomScale = 2
        })
        
        index += 1
        
        if let cursor = cursor, index >= skies.count - 3
        {
            loadMore(cursor: cursor)
        }
        
        if index > skies.count - 1 {
            index = 0
        }
        getNextImage()
    }
    
    private func getNextImage() {
        let skyRecordID = self.skies[self.index].originalImage.recordID
        cloud.getRecord(withRecordID: skyRecordID) { [weak self] (record) in
            guard let record = record else { return }
            let skyFullResolutionImage = SkyImageFullResolution(picture: record["picture"] as! CKAsset)
            guard let skyImage = skyFullResolutionImage.image else { return }
            self?.nextImage = skyImage
        }
    }
    
    @objc fileprivate func loadData() {
        
        guard !fetching else { return }
        
        fetching = true
        
        skies = [Sky]()
        records = [CKRecord]()
        
        let predicate = (self.skyType == "All") ? NSPredicate(value: true) : NSPredicate(format: "type == %@", self.skyType)
        
        cloud.loadSkies(predicate: predicate, sortDescriptorIndexPath: 3) { [weak self] (skies, records, cursor) in
            self?.fetching = false
            
            guard let skies = skies else { return }
            guard let records = records else { return }
            
            if let cursor = cursor {
                self?.cursor = cursor
            } else {
                self?.cursor = nil
            }
            
            self?.skies = skies
            self?.records = records
            
            guard let initialSkyRecordID = self?.skies[0].originalImage.recordID else { return }
            self?.cloud.getRecord(withRecordID: initialSkyRecordID) { [weak self] (record) in
                guard let record = record else { return }
                
                let skyImage = SkyImageFullResolution(picture: record["picture"] as! CKAsset)
                self?.nextImage = skyImage.image!
                
                DispatchQueue.main.async {
                    self?.activityIndicator.stopAnimating()
                    self?.scrollView.backgroundColor = .black
                    self?.changeSkyImage()
                    guard let currentVC = self else { return }
                    self?.timer = Timer.scheduledTimer(timeInterval: TimeInterval(self?.secondsPerSlide ?? 5), target: currentVC, selector: #selector(self?.changeSkyImage), userInfo: nil, repeats: true)
                }
            }
        }
    }
        
    private func loadMore(cursor: CKQueryCursor) {
        
        guard !fetching else { return }
        fetching = true
        
        cloud.loadAdditionalSkies(withCursor: cursor) { [weak self] (skies, records, cursor) in
            
            self?.fetching = false
            
            if let cursor = cursor {
                self?.cursor = cursor
            } else {
                self?.cursor = nil
            }
            
            guard let skies = skies else { return }
            guard let records = records else { return }
            
            self?.skies += skies
            self?.records += records
        }
    }
    
    // MARK: - ScrollViewDelegate
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

}

extension SkyImageSlideShowViewController: RestartSkySlideShow {
    
    // MARK: - Custom RestartSlideShowDelegate Implementation
    
    func restartSkySlideShow() {
        index = 0
        imageView.image = nil
        nextImage = UIImage()
        timer?.invalidate()
        timer = nil
        activityIndicator.startAnimating()
        loadData()
    }
}


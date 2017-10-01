//
//  SettingsViewController.swift
//  EpicSkies
//
//  Created by Grant Emerson on 9/3/17.
//  Copyright © 2017 com.CelebrityGames. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    
    // MARK: - Properties
    
    @IBOutlet weak var skyTypePicker: TVPickerView!
    @IBOutlet weak var showNameAndDateSwitch: UIButton!
    @IBOutlet weak var secondsPerSkyControl: UISegmentedControl!
    
    fileprivate var isPickerLoaded: Bool = false
    
    fileprivate let constants = Constants.sharedInstance
    private var seconds = [5,8,10,12]
    
    fileprivate var settings = UserDefaults()
    
    public var delegate: RestartSkySlideShow?
    
    // MARK: - ViewController Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        skyTypePicker.focusDelegate = self
        skyTypePicker.dataSource = self
        skyTypePicker.delegate = self
        skyTypePicker.backgroundColor = .white
        
        if settings.bool(forKey: "dontShowNameAndDate") == true {
            showNameAndDateSwitch.setTitleColor(.lightGray, for: .normal)
            showNameAndDateSwitch.setTitle("Off", for: .normal)
        }
        let secPerSlide = settings.integer(forKey: "secondsPerSlide")
        if secPerSlide != 0 {
            guard let seconds = seconds.index(of: secPerSlide) else { return }
            secondsPerSkyControl.selectedSegmentIndex = seconds
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !isPickerLoaded {
            skyTypePicker.reloadData()
            let savedSkyType = settings.object(forKey: "skyType")
            if savedSkyType != nil {
                skyTypePicker.scrollToIndex(constants.sortSkyTypes.index(of: savedSkyType as! String)!)
            }
            isPickerLoaded = true
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func changeShowNameAndDateProperty(_ sender: UIButton) {
        let on = showNameAndDateSwitch.titleLabel?.text == "On"
        showNameAndDateSwitch.setTitle((on ? "Off" : "On"), for: .normal)
        showNameAndDateSwitch.setTitleColor((on ? .lightGray : .green), for: .normal)
        settings.set(!on, forKey: "dontShowNameAndDate")
    }
    
    @IBAction func secondsChanged(_ sender: UISegmentedControl) {
        let i = sender.selectedSegmentIndex
        settings.set(seconds[i], forKey: "secondsPerSlide")
        delegate?.restartSkySlideShow()
    }
    
}

extension SettingsViewController: TVPickerViewFocusDelegate {
    
    // MARK: - TVPickerViewFocusDelegate Implementation
    
    func pickerView(_ picker: TVPickerView, deepFocusStateChanged isDeepFocus: Bool) {
        
        if !isDeepFocus {
            settings.set(constants.sortSkyTypes[picker.selectedIndex], forKey: "skyType")
            delegate?.restartSkySlideShow()
        }
    }
}

extension SettingsViewController: TVPickerViewDataSource {
    
    // MARK: - TVPickerViewDataSource Implementation
    
    func numberOfViewsInPickerView(_ picker: TVPickerView) -> Int {
        return constants.sortSkyTypes.count
    }
    
    func pickerView(_ picker: TVPickerView, viewForIndex idx: Int, reusingView view: UIView?) -> UIView {
        
        var sview = view as? UILabel
        
        if sview == nil {
            sview = UILabel()
            sview!.textColor = .white
            sview!.font = .systemFont(ofSize: 30)
            sview!.textAlignment = .center
        }
        
        sview!.backgroundColor = UIColor(red: 135/255, green: 206/255, blue: 235/255, alpha: 1)
        sview!.text = constants.sortSkyTypes[idx]
        
        return sview!
    }
}

extension SettingsViewController: TVPickerViewDelegate {
    
    // MARK: - TVPickerViewDelegate Implementation
    
    func pickerView(_ picker: TVPickerView, didChangeToIndex index: Int) {
    }
}

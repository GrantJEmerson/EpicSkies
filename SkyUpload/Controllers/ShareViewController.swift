//
//  ShareViewController.swift
//  SkyUpload
//
//  Created by Grant Emerson on 8/27/17.
//  Copyright © 2017 com.CelebrityGames. All rights reserved.
//

import UIKit
import Social
import CloudKit
import Photos
import MobileCoreServices

// MARK: - Public Protocols

protocol TypeSelectionViewControllerDelegate {
    func typeSelection(sender: Any, selectedValue: String)
}

class ShareViewController: SLComposeServiceViewController {
    
    // MARK: - Properties
    
    private let themeColor = UIColor(red: 135/255, green: 206/255, blue: 235/255, alpha: 1)
    
    private let imageType = kUTTypeImage as String
    
    private var skyImage: UIImage?
    private var skyImageURL: URL?
    private var skyOriginalImageURL: URL?
    
    private var selectedType = "Clouds"
    private var date = Date()
    
    private var location = CLLocation(latitude:  37.3320003, longitude: -122.03078119999998)
    
    private var timer: Timer?
    
    private let cloud = Service.sharedInstance
    
    private var loadingAlert: UIAlertController = {
        let loadingAlert = UIAlertController(title: "Saving...", message: "We are saving your sky to the cloud.", preferredStyle: .alert)
        return loadingAlert
    }()
    
    lazy var typeConfigurationItem: SLComposeSheetConfigurationItem = {
        if let item = SLComposeSheetConfigurationItem() {
            item.title = "Type"
            item.value = self.selectedType
            item.tapHandler = self.showSelectionType
            return item
        }
        return SLComposeSheetConfigurationItem()
    }()
    
    // MARK: - ViewController Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.backgroundColor = themeColor
        self.navigationController?.navigationBar.tintColor = .white
        placeholder = "Sky Name..."
        view.tintColor = .white
    }
    
    private func showSelectionType() {
        let controller = SkyTypeTableViewController(style: .plain)
        controller.selectedTypeName = typeConfigurationItem.value
        controller.delegate = self
        pushConfigurationViewController(controller)
    }
    
    override func isContentValid() -> Bool {
        return true
    }
    
    override func configurationItems() -> [Any]! {
        return [typeConfigurationItem]
    }
    
    // MARK: - Private Functions
    
    @objc private func loadingFunction() {
        guard let title = loadingAlert.title else { return }
        if title == "Saving..." {
            loadingAlert.title = "Saving."
        } else {
            loadingAlert.title = title + "."
        }
    }

    override func didSelectPost() {
        
        self.present(loadingAlert, animated: true)
        
        if #available(iOS 10.0, *) {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (_) in
                self.loadingFunction()
            }
        } else {
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(loadingFunction), userInfo: nil, repeats: true)
        }
        
        guard let content = extensionContext?.inputItems[0] as? NSExtensionItem else { closePostWindow(); return }
        guard let contentAttachments = content.attachments as? [NSItemProvider] else { closePostWindow(); return }
        
        let skyName = self.textView.text
        
        for attachment in contentAttachments {
            if attachment.hasItemConformingToTypeIdentifier(imageType) {
                attachment.loadItem(forTypeIdentifier: imageType, options: nil) { (data, error) in
                    guard error == nil, let url = data as? NSURL else { self.closePostWindow(); return }
                    self.imageFromAsset(url: url as URL)
                    if !self.selectedType.isEmpty {
                        do {
                            let imageData = try Data(contentsOf: url as URL)
                            self.skyImage = UIImage(data: imageData)
                            
                            self.saveSkyImage()
                            
                            guard let skyOriginalImageURL = self.skyOriginalImageURL else { self.closePostWindow(); return }
                            guard let skyImageURL = self.skyImageURL else { self.closePostWindow(); return }
                            
                            let newSky = Sky(name: skyName ?? "Another Sky",
                                             type: self.selectedType,
                                             date: self.date,
                                             location: self.location,
                                             picture: CKAsset(fileURL: skyImageURL),
                                             likes: 0, flags: 0,
                                             likedBy: [CKReference](), flaggedBy: [CKReference](),
                                             originalImage: CKReference(record: CKRecord(recordType: "SkyImage"), action: .none))
                            let newSkyImage = SkyImageFullResolution(picture: CKAsset(fileURL: skyOriginalImageURL))
                            self.saveSky(sky: newSky, skyImage: newSkyImage)
                        } catch {
                            print(error.localizedDescription)
                            self.closePostWindow()
                        }
                    }
                }
            }
        }
    }
    
    private func closePostWindow() {
        timer?.invalidate()
        timer = nil
        
        loadingAlert.dismiss(animated: true)
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    private func saveSkyImage() {
        
        guard let skyImage = skyImage else { return }
        
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let photoURL = URL(fileURLWithPath: documentDirectory)
        skyImageURL = photoURL.appendingPathComponent("test")
        skyOriginalImageURL = photoURL.appendingPathComponent("original")
        
        do {
            var compressionQuality = 1.0
            
            if let photoDataAtFullRes = UIImageJPEGRepresentation(skyImage, 1.0) {
                
                try photoDataAtFullRes.write(to: skyOriginalImageURL!)
                
                let photoNSDataAtFullRes = NSData(data: photoDataAtFullRes)
                let photoSizeInKB = Double(photoNSDataAtFullRes.length) / 1024.0
                if photoSizeInKB > 300 {
                    compressionQuality = 300 / photoSizeInKB
                }
            }
            if let imageJPEGData = UIImageJPEGRepresentation(skyImage, CGFloat(compressionQuality)) {
                try imageJPEGData.write(to: skyImageURL!)
            }
            
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func saveSky(sky: Sky, skyImage: SkyImageFullResolution) {
        
        let newSky = CKRecord(recordType: "Sky")
        newSky["name"] = sky.name as CKRecordValue
        newSky["type"] = sky.type as CKRecordValue
        newSky["image"] = sky.picture
        newSky["location"] = sky.location as CKRecordValue
        newSky["date"] = sky.date as CKRecordValue
        newSky["likes"] = sky.likes as CKRecordValue
        newSky["flags"] = sky.flags as CKRecordValue
        newSky["flaggedBy"] = sky.flaggedBy as CKRecordValue
        newSky["likedBy"] = sky.likedBy as CKRecordValue
        
        let newSkyImage = CKRecord(recordType: "SkyImage")
        newSkyImage["picture"] = skyImage.picture
        newSkyImage["parentSky"] = CKReference(record: newSky, action: .deleteSelf)
        
        cloud.saveNewSky(newSky: newSky, newSkyImage: newSkyImage) { [weak self] _ in
            self?.closePostWindow()
        }
    }
    
    private func imageFromAsset(url: URL) {
        guard let asset = PHAsset.fetchAssets(withALAssetURLs: [url], options: nil).firstObject else { return }
        if let assetLocation = asset.location {
            location = assetLocation
        }
        if let creationDate = asset.creationDate {
            date = creationDate
        }
    }
    
}

extension ShareViewController: TypeSelectionViewControllerDelegate {
    
    // MARK: - Custom TypeSelectionDelegate Implementation
    
    func typeSelection(sender: Any, selectedValue: String) {
        self.selectedType = selectedValue
        typeConfigurationItem.value = selectedType
    }
}

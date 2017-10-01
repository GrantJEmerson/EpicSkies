//
//  NewSkyCreatorTableViewController.swift
//  EpicSkies
//
//  Created by Grant Emerson on 7/27/17.
//  Copyright © 2017 com.CelebrityGames. All rights reserved.
//

import UIKit
import CloudKit
import Photos
import MobileCoreServices

// MARK: - Public Protocol Location Finder

public protocol LocationFinderDelegate {
    func setLocation(newLocation: CLLocation)
}

class NewSkyCreatorTableViewController: UITableViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - Properties
    
    private enum AlertMessages: String {
        case emptyTextField = "Please make sure all text fields have text in them."
        case noPhoto = "Please make sure you upload a photo."
        case cloudError = "There was an error saving to the cloud. Please try again later."
        case noLocation = "Please make sure you add a location for your picture."
    }
    
    private enum AlertTitles: String {
        case noText = "Empty Text Field(s)"
        case noPhoto = "No Photo"
        case cloudError = "iCloud Error"
        case noLocation = "Empty Location"
    }
    
    private let imagePickerController = UIImagePickerController()
    
    private var skyImage: UIImage?
    private var skyImageURL: URL?
    private var skyOriginalImageURL: URL?
    
    private var location: CLLocation?
    
    private let constants = Constants.sharedInstance
    private let cloud = Service.sharedInstance
    
    private var alert: UIAlertController = {
        let alert = UIAlertController(title: "", message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel) { _ in
            alert.dismiss(animated: true)
        })
        return alert
    }()
    
    private var loadingAlert: UIAlertController = {
        let loadingAlert = UIAlertController(title: "Saving...", message: "We are saving your sky to the cloud.", preferredStyle: .alert)
        return loadingAlert
    }()
    
    @IBOutlet weak var adressLabel: UILabel!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var typePicker: UIPickerView!
    @IBOutlet weak var skyImageView: UIImageView!
    
    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let itemGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(chooseInputType))
        skyImageView.addGestureRecognizer(itemGestureRecognizer)
        
        imagePickerController.delegate = self
        imagePickerController.mediaTypes = [kUTTypeImage as String]
        
        typePicker.selectRow(0, inComponent: 0, animated: false)
    }
    
    // MARK: - Actions
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true)
    }
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        
        guard nameTextField.text?.nilIfEmpty() != nil else {
            alert.title = AlertTitles.noText.rawValue
            alert.message = AlertMessages.emptyTextField.rawValue
            present(alert, animated: true)
            return
        }
        
        guard let skyImageURL = skyImageURL, let skyOriginalImageURL = skyOriginalImageURL else {
            alert.title = AlertTitles.noPhoto.rawValue
            alert.message = AlertMessages.noPhoto.rawValue
            present(alert, animated: true)
            return
        }
        
        guard let location = location else {
            alert.title = AlertTitles.noLocation.rawValue
            alert.message = AlertMessages.noLocation.rawValue
            present(alert, animated: true)
            return
        }
        
        let newSky = Sky(name: nameTextField.text!,
                         type: constants.skyTypes[typePicker.selectedRow(inComponent: 0)],
                         date: datePicker.date,
                         location: location,
                         picture: CKAsset(fileURL: skyImageURL),
                         likes: 0, flags: 0,
                         likedBy: [CKReference](), flaggedBy: [CKReference](),
                         originalImage: CKReference(record: CKRecord(recordType: "SkyImage"), action: .none))
        let newSkyImage = SkyImageFullResolution(picture: CKAsset(fileURL: skyOriginalImageURL))
        
        saveSky(sky: newSky, skyImage: newSkyImage)
        
    }
    
    // MARK: - Private Functions
    
    private func saveSky(sky: Sky, skyImage: SkyImageFullResolution) {
        
        self.present(loadingAlert, animated: true)
        
        var timer: Timer?
        
        if #available(iOS 10.0, *) {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (_) in
                self.loadingFunction()
            }
        } else {
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(loadingFunction), userInfo: nil, repeats: true)
        }
        
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
        
        cloud.saveNewSky(newSky: newSky, newSkyImage: newSkyImage) { [weak self] (success) in
            
            timer?.invalidate()
            timer = nil
            
            DispatchQueue.main.async {
                if success {
                    self?.loadingAlert.dismiss(animated: true)
                    self?.dismiss(animated: true)
                } else {
                    self?.handleErrorSavingSky()
                }
            }
        }
    }
    
    @objc private func loadingFunction() {
        if loadingAlert.title == "Saving..." {
            loadingAlert.title = "Saving."
        } else {
            loadingAlert.title = loadingAlert.title! + "."
        }
    }
    
    private func handleErrorSavingSky() {
        alert.message = AlertMessages.cloudError.rawValue
        alert.title = AlertTitles.cloudError.rawValue
        present(alert, animated: true)
    }
    
    private func locationToAdress(location: CLLocation) {
        CLGeocoder().reverseGeocodeLocation(location) { (placeMarks, error) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                guard let locationName = placeMarks?.first?.name else { return }
                self.adressLabel.text = locationName
            }
        }
    }
    
    // MARK: - TextField Delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: - ImagePickerController
    
    @objc private func chooseInputType() {
        let actionSheet = UIAlertController(title: "Image Source", message: "Select a source of input for you image.", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default) { [weak self] (action) in
            self?.addPhoto(withType: .camera)
            actionSheet.dismiss(animated: true)
        })
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default) { [weak self] (action) in
            self?.addPhoto(withType: .photoLibrary)
            actionSheet.dismiss(animated: true)
        })
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            actionSheet.dismiss(animated: true)
        })
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            actionSheet.modalPresentationStyle = .popover
            actionSheet.popoverPresentationController?.sourceRect = skyImageView.bounds
            actionSheet.popoverPresentationController?.sourceView = skyImageView
        }
        
        self.present(actionSheet, animated: true)
    }
    
    private func addPhoto(withType type: UIImagePickerControllerSourceType) {
        imagePickerController.sourceType = type
        if UIDevice.current.userInterfaceIdiom == .pad {
            imagePickerController.modalPresentationStyle = .formSheet
        }
        self.present(imagePickerController, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        picker.dismiss(animated: true)
        
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            skyImage = image
            skyImageView.image = skyImage
        }
        
        let imageName: String!
        
        if let url = info[UIImagePickerControllerReferenceURL] as? URL {
            imageName = url.lastPathComponent
            imageFromAsset(url: url)
        } else {
            imageName = "test"
        }
        
        guard let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                                          .userDomainMask, true).first else { return }
        let photoURL = URL(fileURLWithPath: documentDirectory)
        skyImageURL = photoURL.appendingPathComponent(imageName)
        skyOriginalImageURL = photoURL.appendingPathComponent("original")
        
        do {
            var compressionQuality = 1.0
            
            if let photoDataAtFullRes = UIImageJPEGRepresentation(skyImage!, 1.0) {
                
                try photoDataAtFullRes.write(to: skyOriginalImageURL!)
                
                let photoNSDataAtFullRes = NSData(data: photoDataAtFullRes)
                let photoSizeInKB = Double(photoNSDataAtFullRes.length) / 1024.0
                if photoSizeInKB > 300 {
                    compressionQuality = 300 / photoSizeInKB
                }
            }
            if let imageJPEGData = UIImageJPEGRepresentation(skyImage!, CGFloat(compressionQuality)) {
                try imageJPEGData.write(to: skyImageURL!)
            }
            
        } catch {
            print(error.localizedDescription)
        }
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func imageFromAsset(url: URL) {
        
        guard let asset = PHAsset.fetchAssets(withALAssetURLs: [url], options: nil).firstObject else { return }
        
        if let assetLocation = asset.location {
            location = assetLocation
            locationToAdress(location: assetLocation)
        }
        if let creationDate = asset.creationDate {
            datePicker.setDate(creationDate, animated: false)
        }
    }
    
    // MARK: Navigtion
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController,
            segue.identifier == "setLocation" {
            if let locationFinderVC = navController.viewControllers[0] as? LocationSetterViewController {
                locationFinderVC.locationFinderDelegate = self
            }
        }
    }
    
}

extension NewSkyCreatorTableViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    // MARK: - PickerView
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return constants.skyTypes.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return constants.skyTypes[row]
    }
}

extension NewSkyCreatorTableViewController: LocationFinderDelegate {
    
    // MARK: - Location Finder Delegate Implementation
    
    func setLocation(newLocation: CLLocation) {
        location = newLocation
        locationToAdress(location: newLocation)
    }
}

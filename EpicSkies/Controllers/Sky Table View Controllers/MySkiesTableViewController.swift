//
//  MySkiesTableViewController.swift
//  EpicSkies
//
//  Created by Grant Emerson on 7/27/17.
//  Copyright © 2017 com.CelebrityGames. All rights reserved.
//

import UIKit
import CloudKit
import MobileCoreServices

class MySkiesTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - Properties
    
    private var mySkies = [Sky]()
    private var records = [CKRecord]()
    
    private var fetching = false
    
    private var userRecordID: CKRecordID?
    private var userProfilePic: UIImage?
    
    private let cloud = Service.sharedInstance
    private var cursor: CKQueryCursor?
    
    private lazy var refresh: UIRefreshControl = {
        let refresh = UIRefreshControl()
        refresh.attributedTitle = NSAttributedString(string: "Pull to load skies...")
        refresh.backgroundColor = UIColor.lightGray
        refresh.addTarget(self, action: #selector(loadData), for: .valueChanged)
        return refresh
    }()
    
    private lazy var pagingSpinner: UIActivityIndicatorView = {
        let pagingSpinner = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        pagingSpinner.hidesWhenStopped = true
        return pagingSpinner
    }()
    
    private let imagePickerController: UIImagePickerController = {
        let imagePC = UIImagePickerController()
        imagePC.mediaTypes = [kUTTypeImage as String]
        return imagePC
    }()
    
    @IBOutlet weak var profileImageButton: UIBarButtonItem!
    
    // MARK: - ViewController Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePickerController.delegate = self
        self.tableView.addSubview(refresh)
        
        setUserRecordID()
    
    }
    
    // MARK: - Private Functions
    
    @objc private func loadData() {
        
        guard userRecordID != nil else {
            setUserRecordID()
            return
        }
        
        if !fetching {
            
            fetching = true
            
            mySkies.removeAll()
            records.removeAll()
            
            DispatchQueue.main.async {
                self.tableView.allowsSelection = false
            }
            
            guard let recordID = userRecordID else { return }
            
            let reference = CKReference(recordID: recordID, action: .none)
            let predicate = NSPredicate(format: "creatorUserRecordID == %@", reference)
            
            cloud.loadSkies(predicate: predicate,
                            sortDescriptorIndexPath: 0)
            { [weak self] (skies, records, cursor) in
                
                self?.fetching = false
                
                guard let skies = skies else { return }
                guard let records = records else { return }
                
                if let cursor = cursor {
                    self?.cursor = cursor
                } else {
                    self?.cursor = nil
                }
                
                self?.mySkies = skies
                self?.records = records
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                    self?.refresh.endRefreshing()
                    self?.tableView.allowsSelection = true
                }
            }
        }
    }
    
    private func loadMore(cursor: CKQueryCursor) {
        
        if !fetching {
            
            fetching = true
            
            cloud.loadAdditionalSkies(withCursor: cursor)
            { [weak self] (skies, records, cursor) in
                
                self?.fetching = false
                
                if let cursor = cursor {
                    self?.cursor = cursor
                } else {
                    self?.cursor = nil
                }
                
                guard let skies = skies else { return }
                guard let records = records else { return }
                
                self?.mySkies += skies
                self?.records += records
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                    self?.pagingSpinner.stopAnimating()
                    self?.tableView.tableFooterView = nil
                    self?.tableView.allowsSelection = true
                }
            }
            
        }
    }
    
    private func setUserRecordID() {
        cloud.getRecordID { [weak self] (recordID) in
            guard let recordID = recordID else { return }
            self?.userRecordID = recordID
            self?.loadData()
            self?.loadUserProfilePicture(withRecordID: recordID)
        }
    }
    
    private func loadUserProfilePicture(withRecordID recordID: CKRecordID) {
        cloud.getRecord(withRecordID: recordID) { [weak self] record in
            guard let record = record else { return }
            guard let picture = record["profileImage"] as? CKAsset else { return }
            if let image = UIImage(contentsOfFile: picture.fileURL.path) {
                DispatchQueue.main.async {
                    self?.changeProfilePictureButton(withImage: image)
                }
            }
        }
    }
    
    @objc private func chooseInputType() {
        let actionSheet = UIAlertController(title: "Change Profile Picture", message: "Select a source of input for you image.", preferredStyle: .actionSheet)
        
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
        
        actionSheet.popoverPresentationController?.barButtonItem = navigationItem.leftBarButtonItem
        
        self.present(actionSheet, animated: true)
    }
    
    private func addPhoto(withType type: UIImagePickerControllerSourceType) {
        imagePickerController.sourceType = type
        if UIDevice.current.userInterfaceIdiom == .pad {
            imagePickerController.modalPresentationStyle = .formSheet
        }
        imagePickerController.popoverPresentationController?.barButtonItem = navigationItem.leftBarButtonItem
        self.present(imagePickerController, animated: true)
    }
    
    // MARK: Profile Pic Updater
    
    func changeProfilePictureButton(withImage image: UIImage) {
        let button = UIButton()
        
        button.setImage(image, for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        
        button.addTarget(self, action: #selector(self.chooseInputType), for: UIControlEvents.touchUpInside)
        
        button.frame = CGRect(x: 0, y: 0, width: 31, height: 31)
        
        button.layer.cornerRadius = button.bounds.width / 2
        button.layer.borderWidth = 2.5
        button.layer.borderColor = UIColor.lightGray.cgColor
        
        button.clipsToBounds = true
        
        button.widthAnchor.constraint(equalToConstant: 31).isActive = true
        button.heightAnchor.constraint(equalToConstant: 31).isActive = true
        
        let barButton = UIBarButtonItem(customView: button)
        
        self.navigationItem.leftBarButtonItem = barButton
    }
    
    @IBAction func changeProfilePic(_ sender: UIBarButtonItem) {
        chooseInputType()
    }
    
    func modifyUserProfile(image: URL) {
        guard let userRecordID = userRecordID else { return }
        cloud.changeProfilePic(withImage: image, userRecordID: userRecordID) { success in
            DispatchQueue.main.async {
                guard let userProfilePic = self.userProfilePic else { return }
                self.changeProfilePictureButton(withImage: userProfilePic)
            }
        }
    }
    
    // MARK: - ImagePickerController Delegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        picker.dismiss(animated: true)
        
        var imageSelected = UIImage()
        var imageName = ""
        
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageSelected = image
            userProfilePic = image
        }
        
        if let url = info[UIImagePickerControllerReferenceURL] as? URL {
            imageName = url.lastPathComponent
        } else {
            imageName = "test"
        }
        
        if let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            
            let photoURL = URL(fileURLWithPath: documentDirectory)
            let profilePictureURL = photoURL.appendingPathComponent(imageName)
            
            do {
                if let photo = UIImageJPEGRepresentation(imageSelected, 1.0) {
                    try photo.write(to: profilePictureURL)
                }
                modifyUserProfile(image: profilePictureURL)
                
            } catch {
                print(error.localizedDescription)
            }
        }
    
    }
    
    // MARK: - Table View Datasource & Delegate

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mySkies.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let skyCell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! SkyTableViewCell
        
        if mySkies.count != 0 {
            let sky = mySkies[indexPath.row]
            let creationDate = records[indexPath.row].creationDate
        
            skyCell.skyImageView.image = UIImage(contentsOfFile: sky.picture.fileURL.path)
            skyCell.SkyNameLabel.text = sky.name
            skyCell.skyDateLabel.text = creationDate?.timeAgoDisplay()
            skyCell.likeCountLabel.text = "\(sky.likes)"
            
        }
        
        return skyCell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let recordID = records[indexPath.row].recordID
            Service.sharedInstance.deleteRecord(recordID: recordID) { success in
                if success { self.loadData() }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let sky = mySkies[indexPath.row]
        let recordID = records[indexPath.row].recordID
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        performSegue(withIdentifier: "showSkyView", sender: (sky, recordID))
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height - self.view.frame.size.height {
            if let cursor = cursor {
                pagingSpinner.startAnimating()
                tableView.tableFooterView = pagingSpinner
                loadMore(cursor: cursor)
            }
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSkyView",
            let skyViewController = segue.destination as? SkyViewController,
            let selectedData = sender as? (Sky, CKRecordID) {
            skyViewController.sky = selectedData.0
            skyViewController.recordID = selectedData.1
            skyViewController.isPersonalSky = true
        }
    }

}

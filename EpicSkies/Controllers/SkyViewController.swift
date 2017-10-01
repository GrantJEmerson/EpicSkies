//
//  SkyViewController.swift
//  EpicSkies
//
//  Created by Grant Emerson on 7/29/17.
//  Copyright © 2017 com.CelebrityGames. All rights reserved.
//

import UIKit
import CoreLocation
import CloudKit
import MapKit

class SkyViewController: UIViewController {
    
    // MARK: - Properties
    
    public var reloadDelegate: ReloadDataDelegate?
    
    public var sky: Sky!
    public var recordID: CKRecordID!
    private var userReference: CKReference?
    
    private let cloud = Service.sharedInstance
    private let constants = Constants.sharedInstance
    
    private var userName = ""
    private var locationString = "Unknown"
    public var isPersonalSky = false
    
    private var modifying = false
    
    private var skyImage = UIImage() {
        didSet {
            imageView.image = skyImage
        }
    }
    
    private var originalSkyImage: UIImage? {
        didSet {
            DispatchQueue.main.async {
                if self.skyImage.size != self.originalSkyImage?.size {
                    self.imageView.image = self.originalSkyImage
                    self.imageView.sizeToFit()
                    self.skyView.contentSize = self.imageView.bounds.size
                    self.zoomToImageView(animated: false)
                }
            }
        }
    }
    
    private var userImage = UIImage() {
        didSet {
            DispatchQueue.main.async {
                self.profilePicImageView.image = self.userImage
            }
        }
    }
    
    private var visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    private var effect: UIVisualEffect!
    
    private var imageView = UIImageView()
    
    private var userNameLabel: UILabel = {
        var userNameLabel = UILabel()
        userNameLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 20))
        userNameLabel.clipsToBounds = true
        userNameLabel.layer.cornerRadius = 5
        userNameLabel.backgroundColor = .white
        userNameLabel.textAlignment = .center
        userNameLabel.font = UIFont(name: "Futura", size: 14)
        userNameLabel.alpha = 0
        return userNameLabel
    }()
    
    private lazy var activityView: UIActivityIndicatorView = {
        let activityView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        activityView.color = .white
        activityView.hidesWhenStopped = true
        return activityView
    }()
    
    private lazy var alert: UIAlertController = {
        let alert = UIAlertController(title: "Continue?",
                                      message: "This action can not be undone. Are you sure you want to flag this item?",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
        alert.dismiss(animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "Continue", style: .destructive) { [weak self] _ in
            guard let recordID = self?.recordID else { return }
            self?.cloud.deleteRecord(recordID: recordID, completion: { success in
                if success {
                    self?.dismiss(animated: true)
                }
            })
        })
        return alert
    }()
    
    @IBOutlet var moreInfoView: UIView!
    @IBOutlet weak var moreInfoName: UILabel!
    @IBOutlet weak var moreInfoType: UILabel!
    @IBOutlet weak var moreInfoDate: UILabel!
    @IBOutlet weak var moreInfoLocation: UILabel!
    
    @IBOutlet weak var flagButton: UIBarButtonItem!
    @IBOutlet weak var likeButton: UIBarButtonItem!
    @IBOutlet weak var downloadButton: UIButton!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var profilePicImageView: UIImageView!
    @IBOutlet weak var skyView: UIScrollView!
    
    // MARK: - ViewController Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        effect = visualEffectView.effect
        visualEffectView.effect = nil
        
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        moreInfoView.translatesAutoresizingMaskIntoConstraints = false
        
        moreInfoView.layer.cornerRadius = 5
        
        profilePicImageView.clipsToBounds = true
        profilePicImageView.layer.cornerRadius = profilePicImageView.bounds.width / 2
        profilePicImageView.layer.borderWidth = 2
        profilePicImageView.layer.borderColor = UIColor.lightGray.cgColor
        
        skyView.delegate = self
        skyView.minimumZoomScale = 0.03
        skyView.maximumZoomScale = 2.0
        skyView.contentSize = imageView.bounds.size
        skyView.addSubview(imageView)
        
        updateUI()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showUserName))
        profilePicImageView.addGestureRecognizer(tapGesture)
        
        // Setting Up Username Label
        
        view.addSubview(userNameLabel)
        
        userNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let verticalSpacing = NSLayoutConstraint(item: userNameLabel, attribute: .top, relatedBy: .equal, toItem: profilePicImageView, attribute: .bottom, multiplier: 1, constant: 10)
        let center = NSLayoutConstraint(item: userNameLabel, attribute: .centerX, relatedBy: .equal, toItem: profilePicImageView, attribute: .centerX, multiplier: 1, constant: 0)
        let constantWidth = NSLayoutConstraint(item: userNameLabel, attribute: .width, relatedBy: .equal, toItem: profilePicImageView, attribute: .width, multiplier: 3, constant: 0)
        let constantHeight = NSLayoutConstraint(item: userNameLabel, attribute: .height, relatedBy: .equal, toItem: profilePicImageView, attribute: .height, multiplier: 1, constant: 0)
        
        view.addConstraints([verticalSpacing, center, constantWidth, constantHeight])
        
        flagButton.isEnabled = !isPersonalSky
        likeButton.isEnabled = !isPersonalSky
        
        setMoreInfoText()
        
        setUserRefernce()
        loadUserProfilePic()
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        zoomToImageView(animated: false)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - Private Functions
    
    private func setUserRefernce() {
        cloud.getRecordID() { [weak self] recordID in
            guard let recordID = recordID else { return }
            
            let userReference = CKReference(recordID: recordID, action: .none)
            self?.userReference = userReference
            
            DispatchQueue.main.async {
                if (self?.sky.likedBy.contains(userReference) ?? false) {
                    self?.likeButton.tintColor = .lightGray
                }
                
                if (self?.sky.flaggedBy.contains(userReference) ?? false) {
                    self?.flagButton.isEnabled = false
                }
            }
            
            self?.getUserName()
        }
    }
    
    private func loadUserProfilePic() {
        cloud.getRecord(withRecordID: recordID) { [weak self] (record) in
            guard let record = record else { return }
            guard let recordCreatorID = record.creatorUserRecordID else { return }
            
            self?.cloud.getRecord(withRecordID: recordCreatorID) { (record) in
                guard let recordCreatorUserRecord = record else { return }
                guard let image = recordCreatorUserRecord["profileImage"] as? CKAsset else { return }
                if let profileImage = UIImage(contentsOfFile: image.fileURL.path) {
                    self?.userImage = profileImage
                }
            }
        }
    }
    
    private func getUserName() {

        guard let skyCreatorRecordID = userReference?.recordID else { return }
        
        CKContainer.default().requestApplicationPermission(.userDiscoverability) { [weak self] (status, error) in
            if status == .granted {
                self?.cloud.getUserName(withRecordID: skyCreatorRecordID) { (name) in
                    DispatchQueue.main.async {
                        self?.userNameLabel.text = self?.userName
                    }
                }
            }
        }
    }
    
    private func setMoreInfoText() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        moreInfoName.text = "Name: \(sky.name)"
        moreInfoType.text = "Type: \(sky.type)"
        moreInfoDate.text = "Date: \(dateFormatter.string(from: sky.date))"
        moreInfoLocation.adjustsFontSizeToFitWidth = true
        
        CLGeocoder().reverseGeocodeLocation(sky.location) { (placeMarks, error) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                self.locationString = placeMarks?.first?.name ?? "unknown"
                DispatchQueue.main.async {
                    self.moreInfoLocation.text = "Location: \(self.locationString)"
                }
            }
        }
    }
    
    private func getHighResPhoto() {
        cloud.getRecord(withRecordID: sky.originalImage.recordID) { [weak self] (record) in
            guard let record = record else { return }
            let skyImage = SkyImageFullResolution(picture: record["picture"] as! CKAsset)
            self?.originalSkyImage = skyImage.image
        }
    }
    
    @objc func showUserName() {
        UIView.animate(withDuration: 1, animations: {
            self.userNameLabel.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 1, delay: 2, options: [.curveLinear], animations: {
                self.userNameLabel.alpha = 0
            }, completion: nil)
        }
    }
    
    private func updateUI() {
        if let image = UIImage(contentsOfFile: sky.picture.fileURL.path) {
            skyImage = image
            imageView.sizeToFit()
            skyView.contentSize = imageView.bounds.size
            skyView.isScrollEnabled = true
            zoomToImageView(animated: false)
            nameLabel.text = sky.name
            getHighResPhoto()
        }
    }
    
    private func zoomToImageView(animated: Bool) {
        skyView.minimumZoomScale = 0.03
        skyView.zoom(to: imageView.bounds, animated: animated)
        imageView.center = view.center
        skyView.minimumZoomScale = skyView.zoomScale
    }
    
    private func centerScrollViewContents() {
        let boundsSize = skyView.bounds.size
        var contentsFrame = imageView.frame
        
        if contentsFrame.size.width < boundsSize.width{
            contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2
        } else {
            contentsFrame.origin.x = 0
        }
        
        if contentsFrame.size.height < boundsSize.height {
            contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2
        } else {
            contentsFrame.origin.y = 0
        }
        
        imageView.frame = contentsFrame
    }
    
    // MARK: - Image Saving Completion
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        activityView.stopAnimating()
        if let error = error {
            let ac = UIAlertController(title: "Saving Error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
            
            downloadButton.setImage(#imageLiteral(resourceName: "downloadIcon"), for: .normal)
            downloadButton.isUserInteractionEnabled = true
        } else {
            let ac = UIAlertController(title: "Saved!", message: "The sky image has been saved to your photos.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func back(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    
    @IBAction func downloadImage(_ sender: UIButton) {
        
        downloadButton.setImage(nil, for: .normal)
        downloadButton.isUserInteractionEnabled = false
        
        view.addSubview(activityView)
        activityView.center = sender.center
        activityView.startAnimating()
        
        UIImageWriteToSavedPhotosAlbum(originalSkyImage ?? skyImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @IBAction func flag(_ sender: UIBarButtonItem) {
        guard let userReference = userReference else {
            setUserRefernce()
            return
        }
        if !sky.flaggedBy.contains(userReference) && !modifying {
            if sky.flags >= 2 {
                self.present(alert, animated: true)
            } else {
                modifying = true
                cloud.modifyCKRecord(recordID: recordID,
                                     sky: sky,
                                     flagsToAdd: 1,
                                     likesToAdd: 0,
                                     user: userReference)
                { [weak self] (success) in
                    self?.modifying = false
                    if success {
                        DispatchQueue.main.async {
                            self?.flagButton.isEnabled = false
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func like(_ sender: UIBarButtonItem) {
        
        guard let userReference = userReference else {
            setUserRefernce()
            return
        }
        
        if !modifying {
            modifying = true
            let alreadyLikedByUser = sky.likedBy.contains(userReference)
            cloud.modifyCKRecord(recordID: recordID,
                                 sky: sky,
                                 flagsToAdd: 0,
                                 likesToAdd: alreadyLikedByUser ? -1 : 1,
                                 user: userReference)
            { [weak self] (success) in
                self?.modifying = false
                if success {
                    DispatchQueue.main.async {
                        self?.likeButton.tintColor = alreadyLikedByUser ? self?.constants.defaultButtonColor : .lightGray
                        self?.reloadDelegate?.reloadData()
                    }
                    if alreadyLikedByUser {
                        if let indexOfRemoval = self?.sky.likedBy.index(of: userReference) {
                            self?.sky.likedBy.remove(at: indexOfRemoval)
                        }
                    } else {
                        self?.sky.likedBy.append(userReference)
                    }
                }
            }
        }
    }
    
    @IBAction func info(_ sender: UIBarButtonItem) {
        
        self.view.addSubview(visualEffectView)
        
        let constraintBottom = NSLayoutConstraint(item: visualEffectView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        let constraintTop = NSLayoutConstraint(item: visualEffectView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0)
        let constraintLeading = NSLayoutConstraint(item: visualEffectView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0)
        let constraintTrailing = NSLayoutConstraint(item: visualEffectView, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0)
        
        view.addConstraints([constraintBottom, constraintTop, constraintLeading, constraintTrailing])
        
        visualEffectView.frame.size = view.bounds.size
        visualEffectView.center = view.center
        
        self.view.addSubview(moreInfoView)
        
        let constraintHorizontal = NSLayoutConstraint(item: moreInfoView, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)
        let constraintVertical = NSLayoutConstraint(item: moreInfoView, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: moreInfoView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: moreInfoView.bounds.width)
        
        view.addConstraints([constraintVertical, constraintHorizontal, widthConstraint])
        
        moreInfoView.bounds.size.width = moreInfoView.bounds.height * 1.6
        moreInfoView.center = self.view.center
        
        moreInfoView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
        moreInfoView.alpha = 0
        
        UIView.animate(withDuration: 0.4) {
            self.visualEffectView.effect = self.effect
            self.moreInfoView.alpha = 1
            self.moreInfoView.transform = CGAffineTransform.identity
        }
        
    }
    
    @IBAction func getDirections(_ sender: UIButton) {
        let coordinate = sky.location.coordinate
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary:nil))
        mapItem.name = "Sky Location"
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
    }
    
    @IBAction func done(_ sender: UIButton) {
        UIView.animate(withDuration: 0.3, animations: {
            self.moreInfoView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
            self.moreInfoView.alpha = 0
        }) { _ in
            self.moreInfoView.removeFromSuperview()
            self.visualEffectView.removeFromSuperview()
        }
        self.visualEffectView.effect = nil
    }
    
}

extension SkyViewController: UIScrollViewDelegate {
    
    // MARK: - Implementation ScrollView Delegate
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerScrollViewContents()
    }
}

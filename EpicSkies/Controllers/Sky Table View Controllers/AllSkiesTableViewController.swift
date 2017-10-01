//
//  AllSkiesTableViewController.swift
//  EpicSkies
//
//  Created by Grant Emerson on 7/27/17.
//  Copyright © 2017 com.CelebrityGames. All rights reserved.
//

import UIKit
import CloudKit
import GoogleMobileAds

// MARK: - Public Protocols

public protocol SortingInfoDelegate {
    func setSortInfo(sortDescriptorIndexPath: Int?, selectedType: String?)
}

public protocol ReloadDataDelegate {
    func reloadData()
}

class AllSkiesTableViewController: UITableViewController, GADNativeExpressAdViewDelegate {
    
    // MARK: - Properties
    
    private var tableViewItems = [AnyObject]()
    private var allSkies = [Sky]()
    private var records = [CKRecord]()
    private var adsToLoad = [GADNativeExpressAdView]()

    private var fetching = false
    
    private var currentSortDescriptorIndexPath = 0
    private var selectedType = "All"
    
    private let adInterval = 8
    private let adViewHeight = CGFloat(100)
    private var adViewWidth = CGFloat(0)
    
    private var currentLocation = CLLocation()
    
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
    
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.searchBarStyle = UISearchBarStyle.prominent
        searchBar.placeholder = " Search..."
        searchBar.returnKeyType = .done
        searchBar.sizeToFit()
        searchBar.showsCancelButton = true
        searchBar.delegate = self
        return searchBar
    }()
    
    private lazy var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        return locationManager
    }()
    
    // MARK: - ViewController Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.tableHeaderView = searchBar
        self.tableView.addSubview(refresh)
        self.tableView.register(UINib(nibName: "NativeExpressAd", bundle: nil), forCellReuseIdentifier: "NativeExpressAdCell")
        
        loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if tableView.contentOffset.y == 0 {
            // Scrolls tableView down to hide search bar
            self.tableView.contentOffset.y = (self.tableView.tableHeaderView?.frame)!.height
        }
        adViewWidth = view.frame.width
    }
    
    // MARK: - Private Functions
    
    @objc fileprivate func loadData() {
        
        if !fetching {
            
            fetching = true
            
            allSkies.removeAll()
            records.removeAll()
            tableViewItems.removeAll()
            
            DispatchQueue.main.async {
                self.tableView.allowsSelection = false
            }
            
            var predicate = NSPredicate(value: true)
            
            if let searchText = self.searchBar.text?.nilIfEmpty() {
                if self.selectedType == "All" {
                    predicate = NSPredicate(format: "name BEGINSWITH %@", searchText)
                } else {
                    predicate = NSPredicate(format: "name BEGINSWITH %@ AND type == %@", searchText, self.selectedType)
                }
            } else {
                if self.selectedType != "All" {
                    predicate = NSPredicate(format: "type == %@", self.selectedType)
                }
            }
            
            cloud.loadSkies(predicate: predicate,
                            sortDescriptorIndexPath: currentSortDescriptorIndexPath,
                            location: currentLocation)
            { [weak self] (skies, records, cursor) in
                
                self?.fetching = false
                
                guard let skies = skies else { return }
                guard let records = records else { return }
                
                if let cursor = cursor {
                    self?.cursor = cursor
                } else {
                    self?.cursor = nil
                }
                
                self?.allSkies = skies
                self?.records = records
                
                DispatchQueue.main.async {
                    self?.reloadTable()
                    self?.refresh.endRefreshing()
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
                
                self?.allSkies += skies
                self?.records += records
                
                DispatchQueue.main.async {
                    self?.reloadTable()
                    self?.pagingSpinner.stopAnimating()
                    self?.tableView.tableFooterView = nil
                }
            }
        }
    }
        
    private func reloadTable() {
        self.tableViewItems.removeAll()
        self.allSkies.forEach() { (sky) in
            self.tableViewItems.append(sky as AnyObject)
        }
        self.addNativeExpressAds()
        self.loadNextAd()
        self.tableView.reloadData()
        self.tableView.allowsSelection = true
    }
    
    // MARK: AD Setup
    
    func nativeExpressAdViewDidReceiveAd(_ nativeExpressAdView: GADNativeExpressAdView) {
        loadNextAd()
    }
    
    func addNativeExpressAds() {
        var index = adInterval
        let size = GADAdSizeFromCGSize(CGSize(width: adViewWidth, height: adViewHeight))
        while index < allSkies.count {
            let adView = GADNativeExpressAdView(adSize: size)
            adView?.adUnitID = Constants.sharedInstance.adUnitID
            adView?.rootViewController = self
            adView?.delegate = self
            tableViewItems.insert(adView!, at: index)
            adsToLoad.append(adView!)
            index += adInterval
        }
    }
    
    func loadNextAd() {
        if !adsToLoad.isEmpty {
            let adView = adsToLoad.removeFirst()
            let request = GADRequest()
            request.testDevices = [Constants.sharedInstance.testDeviceID, kGADSimulatorID]
            adView.load(request)
        }
    }

    // MARK: - Table View DataSource & Delegate

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableViewItems.count == 0 && searchBar.text == "" {
            return 8
        } else if tableViewItems.count > 0 {
            return tableViewItems.count
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if !tableViewItems.isEmpty {
            
            if let sky = tableViewItems[indexPath.row] as? Sky {
                
                var row = Double(indexPath.row) - floor(Double(indexPath.row) / Double(adInterval))
                if row < 0 { row = 0 }
                let record = records[Int(row)]
                
                let creationDate = record.creationDate
                
                let skyCell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! SkyTableViewCell
                
                skyCell.SkyNameLabel.text = sky.name
                skyCell.skyImageView.image = sky.image
                skyCell.skyDateLabel.text = creationDate?.timeAgoDisplay()
                skyCell.likeCountLabel.text = "\(sky.likes)"
                
                return skyCell
            } else if let adView = tableViewItems[indexPath.row] as? GADNativeExpressAdView {
                let reusableAdCell = tableView.dequeueReusableCell(withIdentifier: "NativeExpressAdCell", for: indexPath)
                for subView in reusableAdCell.contentView.subviews {
                    subView.removeFromSuperview()
                }
                reusableAdCell.contentView.addSubview(adView)
                adView.center = reusableAdCell.contentView.center
                return reusableAdCell
            }
        }
        
        let defaultCell = UITableViewCell(style: .default, reuseIdentifier: "defaultCell")
        defaultCell.imageView?.image = UIImage(named: "DummyImage")
        defaultCell.textLabel?.text = "Epic Sky"
        return defaultCell
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !tableViewItems.isEmpty,
            let sky = tableViewItems[indexPath.row] as? Sky {
                var row = Double(indexPath.row) - floor(Double(indexPath.row) / Double(adInterval))
                if row < 0 { row = 0 }
                let recordID = records[Int(row)].recordID
                
                tableView.deselectRow(at: indexPath, animated: true)
                
                performSegue(withIdentifier: "showSkyViewFromAllSkies", sender: (sky, recordID))
        }
    
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if !tableViewItems.isEmpty && tableViewItems[indexPath.row] as? GADNativeExpressAdView != nil {
            return adViewHeight
        }
        return CGFloat(130)
    }
    
    // MARK: - ScrollView Delegate
    
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
        if segue.identifier == "showSkyViewFromAllSkies",
            let skyViewController = segue.destination as? SkyViewController,
            let selectedData = sender as? (Sky, CKRecordID) {
                skyViewController.sky = selectedData.0
                skyViewController.recordID = selectedData.1
                skyViewController.reloadDelegate = self
        } else if let sortVC = segue.destination as? SortDescriptorTableViewController {
                sortVC.sortingDelegate = self
                sortVC.selectedType = self.selectedType
                sortVC.currentSortDescriptorIndexPath = self.currentSortDescriptorIndexPath
        }
    }
}

extension AllSkiesTableViewController: CLLocationManagerDelegate {
    
    // MARK: - Location Manager Delegate Implementation
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            self.currentLocation = location
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    
}

extension AllSkiesTableViewController: UISearchBarDelegate {
    
    // MARK: - UISearchBarDelegate Implementation
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        loadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.text = ""
    }
}

extension AllSkiesTableViewController: SortingInfoDelegate {
    
    // MARK: - Custom Sorting Info Delegate Implementation
    
    func setSortInfo(sortDescriptorIndexPath: Int?, selectedType: String?) {
        if sortDescriptorIndexPath != nil {
            self.currentSortDescriptorIndexPath = sortDescriptorIndexPath!
        } else if selectedType != nil {
            self.selectedType = selectedType!
        }
        loadData()
    }
}

extension AllSkiesTableViewController: ReloadDataDelegate {
    
    // MARK: - Custom ReloadDateDelegate Implementation
    
    func reloadData() {
        DispatchQueue.main.async {
            self.loadData()
        }
    }
}

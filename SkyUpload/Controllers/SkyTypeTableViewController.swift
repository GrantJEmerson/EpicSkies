//
//  SkyTypeTableViewController.swift
//  EpicSkies
//
//  Created by Grant Emerson on 8/28/17.
//  Copyright © 2017 com.CelebrityGames. All rights reserved.
//

import UIKit

class SkyTypeTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    public var delegate: TypeSelectionViewControllerDelegate?
    
    private let constants = Constants.sharedInstance
    
    private let tableViewCellIdentifier = "typeSelectionCell"
    public var selectedTypeName = "All"
    
    // MARK: - ViewController Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: tableViewCellIdentifier)
    }
  
    // MARK: - TableView DataSource & Delegate

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return constants.skyTypes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: tableViewCellIdentifier, for: indexPath)
        cell.textLabel?.text = constants.skyTypes[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let delegate = delegate else { return }
            selectedTypeName = constants.skyTypes[indexPath.row]
            delegate.typeSelection(sender: self, selectedValue: selectedTypeName)
    }
    
}

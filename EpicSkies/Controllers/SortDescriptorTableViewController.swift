//
//  SortDescriptorTableViewController.swift
//  EpicSkies
//
//  Created by Grant Emerson on 8/1/17.
//  Copyright © 2017 com.CelebrityGames. All rights reserved.
//

import UIKit

class SortDescriptorTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    public var sortingDelegate: SortingInfoDelegate?
    
    public var currentSortDescriptorIndexPath: Int?
    public var selectedType: String?
        
    private let constants = Constants.sharedInstance
    
    @IBOutlet weak var itemPicker: UIPickerView!
    
    private lazy var pickerViewTitleLabel: UILabel = {
        var label = UILabel(frame:  CGRect(x: (itemPicker.center.x - itemPicker.bounds.width / 2), y: itemPicker.center.y, width: 100, height: 20))
        label.text = "  Type:"
        return label
    }()
    
    // MARK: - ViewController Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        itemPicker.addSubview(pickerViewTitleLabel)
    }
        
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        itemPicker.selectRow(constants.skyTypes.index(of: selectedType!) ?? 0, inComponent: 0, animated: true)
        pickerViewTitleLabel.center.y = itemPicker.frame.height / 2.0
    }

    // MARK: - TableView DataSource & Delegate

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return constants.sortDescriptors.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        cell.accessoryType = .none
        
        if indexPath.row == currentSortDescriptorIndexPath {
            cell.accessoryType = .checkmark
        }
        
        cell.textLabel?.text = constants.sortDescriptors[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        currentSortDescriptorIndexPath = indexPath.row
        sortingDelegate?.setSortInfo(sortDescriptorIndexPath: indexPath.row, selectedType: nil)
        tableView.reloadData()
    }

}

extension SortDescriptorTableViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    // MARK: - PickerView DataSource & Delegate
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return constants.sortSkyTypes.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedType = constants.sortSkyTypes[row]
        sortingDelegate?.setSortInfo(sortDescriptorIndexPath: nil, selectedType: constants.sortSkyTypes[row])
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return constants.sortSkyTypes[row]
    }
}


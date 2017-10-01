//
//  InterfaceController.swift
//  EpicSkiesWatch Extension
//
//  Created by Grant Emerson on 8/31/17.
//  Copyright © 2017 com.CelebrityGames. All rights reserved.
//

import WatchKit
import Foundation
import CloudKit

class InterfaceController: WKInterfaceController {
    
    // MARK: - Properties
    
    private var skies = [Sky]()
    private var records = [CKRecord]()
    
    private var selectedSky: Sky?
    private var selectedRecordID: CKRecordID?
    
    private var fetching = false
    
    private let cloud = Service.sharedInstance
    private var cursor: CKQueryCursor?
    
    @IBOutlet var tableView: WKInterfaceTable!
    
    // MARK: - Interface Life Cycle
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        loadData()
    }
    
    // MARK: - Private Functions
    
    private func loadTable() {
        var rows = [Int]()
        rows += 0..<skies.count
        tableView.removeRows(at: IndexSet(rows))
        
        tableView.setNumberOfRows(skies.count, withRowType: "skyRowController")
        var i = 0
        for sky in skies {
            let row = tableView.rowController(at: i) as! skyRowController
            row.myImageView.setImage(sky.image)
            row.skyNameLabel.setText(sky.name)
            row.skyDateLabel.setText(sky.date.timeAgoDisplay())
            i += 1
        }
        
        if cursor != nil {
            tableView.insertRows(at: IndexSet.init(integer: skies.count), withRowType: "LoadMore")
        }
    }
    
    @objc private func loadData() {
        
        if !fetching {
            
            fetching = true
            
            skies.removeAll()
            records.removeAll()
            
            let predicate = NSPredicate(value: true)
            
            cloud.loadSkies(predicate: predicate, sortDescriptorIndexPath: 0) { [weak self] (skies, records, cursor) in
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
                
                DispatchQueue.main.async {
                    self?.loadTable()
                }
            }
        }
    }
    
    private func loadMore(cursor: CKQueryCursor) {
        
        if fetching == false {
            
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
                
                self?.skies += skies
                self?.records += records
                
                DispatchQueue.main.async {
                    self?.loadTable()
                }
            }
        }
    }
    
    // MARK: - WatchKitTableDelegate
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        guard let cursor = cursor, rowIndex == skies.count else { return }
        loadMore(cursor: cursor)
    }
    
    // MARK: - Navigation
    
    override func contextForSegue(withIdentifier segueIdentifier: String, in table: WKInterfaceTable, rowIndex: Int) -> Any? {
        if segueIdentifier == "presentSky" {
            return skies[rowIndex]
        }
        return nil
    }
    
}

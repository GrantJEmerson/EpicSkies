//
//  Services.swift
//  EpicSkies
//
//  Created by Grant Emerson on 9/27/17.
//  Copyright © 2017 com.CelebrityGames. All rights reserved.
//

import Foundation
import CloudKit
import CoreLocation

// MARK: - API Singleton

struct Service {
    
    // Database Declaration
    private let database = CKContainer.init(identifier: Constants.sharedInstance.containerIdentifier).publicCloudDatabase
    
    // Make this a singleton, accessed through sharedInstance.
    static let sharedInstance = Service()
    
    func saveNewSky(newSky: CKRecord,
                    newSkyImage: CKRecord,
                    completion: @escaping (_ success: Bool) -> ()) {
        
        database.save(newSkyImage) { (skyImage, error) in
            
            if let error = error {
                print(error.localizedDescription)
                completion(false)
            } else {
                guard let skyImage = skyImage else { return }
                
                newSky["originalImage"] = CKReference(recordID: skyImage.recordID, action: CKReferenceAction.deleteSelf)
                
                self.database.save(newSky) { (sky, error) in
                    if let error = error {
                        print(error.localizedDescription)
                        
                        // Tries to delete original high res sky image if main sky
                        // fails to save.
                        
                        self.deleteRecord(recordID: skyImage.recordID) { _ in
                            print("Success in deletion")
                        }
                        completion(false)
                    }
                    completion(true)
                }
            }
        }
    }
    
    func loadSkies(predicate: NSPredicate,
                          sortDescriptorIndexPath: Int,
                          location: CLLocation? = nil,
                          completion: @escaping ([Sky]?, [CKRecord]?, CKQueryCursor?) -> ()) {
        
        let query = CKQuery(recordType: "Sky", predicate: predicate)
        
        switch sortDescriptorIndexPath {
        case 0:
            query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        case 1:
            query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        case 3:
            query.sortDescriptors = [NSSortDescriptor(key: "likes", ascending: false)]
        case 2:
            guard let location = location else { fallthrough }
            query.sortDescriptors = [CKLocationSortDescriptor(key: "location", relativeLocation: location)]
        default:
            query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        }
        
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.resultsLimit = 8
        
        var skies = [Sky]()
        var records = [CKRecord]()
        
        queryOperation.recordFetchedBlock = { (sky) in
            records.append(sky)
            skies.append(Sky(name: sky["name"] as! String,
                                      type: sky["type"] as! String,
                                      date: sky["date"] as! Date, location: sky["location"] as! CLLocation,
                                      picture: sky["image"] as! CKAsset, likes: sky["likes"] as! Int,
                                      flags: sky["flags"] as! Int, likedBy: sky["likedBy"] as! [CKReference],
                                      flaggedBy: sky["flaggedBy"] as! [CKReference],
                                      originalImage: sky["originalImage"] as! CKReference))
        }
        
        queryOperation.queryCompletionBlock = { cursor, error in
            
            if let error = error {
                print(error.localizedDescription)
                completion(nil, nil, nil)
            } else {
                completion(skies, records, cursor)
            }
        }
        database.add(queryOperation)
    }
    
    func loadAdditionalSkies(withCursor cursor: CKQueryCursor,
                                 completion: @escaping ([Sky]?, [CKRecord]?, CKQueryCursor?) -> ()) {
        
        let queryOperation = CKQueryOperation(cursor: cursor)
        queryOperation.resultsLimit = 8
    
        var skies = [Sky]()
        var records = [CKRecord]()
        
        queryOperation.recordFetchedBlock = { (sky) in
            records.append(sky)
            skies.append(Sky(name: sky["name"] as! String,
                             type: sky["type"] as! String,
                             date: sky["date"] as! Date, location: sky["location"] as! CLLocation,
                             picture: sky["image"] as! CKAsset, likes: sky["likes"] as! Int,
                             flags: sky["flags"] as! Int, likedBy: sky["likedBy"] as! [CKReference],
                             flaggedBy: sky["flaggedBy"] as! [CKReference],
                             originalImage: sky["originalImage"] as! CKReference))
        }
        
        queryOperation.queryCompletionBlock = { newCursor, error in
            
            if let error = error {
                print(error.localizedDescription)
                completion(nil, nil, cursor)
            } else {
                completion(skies, records, newCursor)
            }
        }
        database.add(queryOperation)
    }
    
    func getRecordID(completion: @escaping (CKRecordID?) -> ()) {
        CKContainer.default().fetchUserRecordID { recordID, error in
            guard let recordID = recordID, error == nil else {
                print(error?.localizedDescription ?? "error")
                completion(nil)
                return
            }
            completion(recordID)
        }
    }
    
    func getRecord(withRecordID recordID: CKRecordID,
                       completion: @escaping (CKRecord?) -> ()) {
        database.fetch(withRecordID: recordID) { (record, error) in
            guard let record = record, error == nil else {
                print(error?.localizedDescription ?? "error")
                completion(nil)
                return
            }
            completion(record)
        }
    }
    
    func deleteRecord(recordID: CKRecordID,
                      completion: @escaping (_ success: Bool) -> ()) {
        database.delete(withRecordID: recordID) { (record, error) in
            if let error = error {
                print(error.localizedDescription)
            } else if record != nil {
                completion(true)
            }
            completion(false)
        }
    }
    
    func modifyCKRecord(recordID: CKRecordID,
                        sky: Sky,
                        flagsToAdd: Int,
                        likesToAdd: Int,
                        user: CKReference,
                        completion: @escaping (_ success: Bool) -> ())  {
        var sky = sky
        getRecord(withRecordID: recordID) { (record) in
            
            guard let record = record else {
                completion(false)
                return
            }
            
            //Modify the record value here
            record.setObject(sky.likes + likesToAdd as CKRecordValue, forKey: "likes")
            record.setObject(sky.flags + flagsToAdd as CKRecordValue, forKey: "flags")
            
            if flagsToAdd == 1 {
                sky.flaggedBy.append(user)
                record.setObject(sky.flaggedBy as CKRecordValue, forKey: "flaggedBy")
            } else if likesToAdd == 1 {
                sky.likedBy.append(user)
                record.setObject(sky.likedBy as CKRecordValue, forKey: "likedBy")
            } else {
                if let indexOfReference = sky.likedBy.index(of: user) {
                    sky.likedBy.remove(at: indexOfReference)
                }
                record.setObject(sky.likedBy as CKRecordValue, forKey: "likedBy")
            }
            
            let modifyRecords = CKModifyRecordsOperation(recordsToSave:[record], recordIDsToDelete: nil)
            modifyRecords.savePolicy = CKRecordSavePolicy.changedKeys
            modifyRecords.qualityOfService = QualityOfService.userInitiated
            modifyRecords.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
                guard let savedRecord = savedRecords else { return }
                
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                
                completion(true)
                
                defer {
                    completion(false)
                }
            }
            self.database.add(modifyRecords)
        }
    }
    
    func changeProfilePic(withImage image: URL, userRecordID: CKRecordID,
                          completion: @escaping (_ success: Bool) -> ()) {
        
        database.fetch(withRecordID: userRecordID) { (record, error) in
            
            if let error = error {
                print(error.localizedDescription)
                completion(false)
            } else if let recordToSave = record {
                
                recordToSave.setObject(CKAsset(fileURL: image), forKey: "profileImage")
                
                let modifyRecords = CKModifyRecordsOperation(recordsToSave:[recordToSave], recordIDsToDelete: nil)
                modifyRecords.savePolicy = CKRecordSavePolicy.changedKeys
                modifyRecords.qualityOfService = QualityOfService.userInitiated
                modifyRecords.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
                    if let error = error {
                        print(error.localizedDescription)
                        completion(false)
                    }
                    completion(true)
                }
                self.database.add(modifyRecords)
            }
        }
    }
    
    func getUserName(withRecordID recordID: CKRecordID,
                     completion: @escaping (String) -> ()) {
        if #available(iOS 10.0, *) {
            let userInfo = CKUserIdentityLookupInfo(userRecordID: recordID)
            let discoverOperation = CKDiscoverUserIdentitiesOperation(userIdentityLookupInfos: [userInfo])
            discoverOperation.userIdentityDiscoveredBlock = { (userIdentity, userIdentityLookupInfo) in
                let userName = "\((userIdentity.nameComponents?.givenName ?? "")) \((userIdentity.nameComponents?.familyName ?? ""))"
                completion(userName)
            }
            discoverOperation.completionBlock = {
                completion("")
            }
            CKContainer.default().add(discoverOperation)
        } else {
            // iOS 10 and below version of the code above,
            // no longer works. So, we just return an empty string.
            completion("")
        }
    }
}


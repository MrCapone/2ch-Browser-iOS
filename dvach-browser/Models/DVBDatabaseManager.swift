//
//  DVBDatabaseManager.swift
//  dvach-browser
//
//  Created by Dmitry on 28.07.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import Foundation
import YapDatabase

private let DB_FILE = "dvachDB.sqlite"

class DVBDatabaseManager: NSObject {
    static var dbCollectionThreads: String? {
        get {
            return "kDbCollectionThreads"
        }
    }
    
    static var dbCollectionThreadPositions: String? {
        get {
            return "kDbCollectionThreadPositions"
        }
    }
    
    var database: YapDatabase?
    
    // MARK: - Construct DB
    static let sharedDatabaseSharedMyManager: DVBDatabaseManager = {
        var sharedMyManager = DVBDatabaseManager()
        return sharedMyManager
    }()
    
    class func sharedDatabase() -> DVBDatabaseManager {
        // `dispatch_once()` call was converted to a static variable initializer
        return sharedDatabaseSharedMyManager
    }
    
    override init() {
        super.init()
        if database == nil {
            database = YapDatabase(path: constructFullDbPath())
        }
    }
    
    func constructFullDbPath() -> String {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).map(\.path)
        let baseDir = (paths.count > 0) ? paths[0] : NSTemporaryDirectory()
        
        let databaseName = DB_FILE
        let databasePath = URL(fileURLWithPath: baseDir).appendingPathComponent(databaseName).absoluteString
        return databasePath
    }
    
    // MARK: - Change DB
    func clearAll() {
        let connection = database?.newConnection()
        connection?.readWrite({ transaction in
            transaction.removeAllObjectsInAllCollections()
        })
    }
}

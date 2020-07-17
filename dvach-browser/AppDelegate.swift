//
//  AppDelegate.swift
//  dvach-browser
//
//  Created by Dmitry Lukianov on 15.07.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import CoreData
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    private var defaultsManager: DVBDefaultsManager!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        defaultsManager = DVBDefaultsManager()
        defaultsManager.initApp()
        
        return true
    }
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: URL = {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = Bundle.main.url(forResource: "dvach-browser", withExtension: "momd")!
        
        let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)!
        return managedObjectModel
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let managedObjectModel = self.managedObjectModel
        
        // Create the coordinator and store
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        let applicationDocumentsDirectory = self.applicationDocumentsDirectory
        let storeURL = applicationDocumentsDirectory.appendingPathComponent("dvach-browser.sqlite")
        let failureReason = "There was an error creating or loading the application's saved data."
        
        do {
            try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
        } catch {
            // Report any error we got.
            var dict: [AnyHashable : Any] = [:]
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            let error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict as? [String : Any])
            if let user = (error as NSError?)?.userInfo {
                print("Unresolved error \(error), \(user)")
            } else {
                print("Unresolved error \(error)")
            }
            abort()
        }
        
        return persistentStoreCoordinator
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext()
    {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                if let user = (error as NSError?)?.userInfo {
                    print("Unresolved error \(error), \(user)")
                } else {
                    print("Unresolved error \(error)")
                }
                abort();
            }
        }
    }
}

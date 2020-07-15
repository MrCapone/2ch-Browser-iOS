//
//  AppDelegate.swift
//  dvach-browser
//
//  Created by Dmitry Lukianov on 15.07.2020.
//  Copyright © 2020 8of. All rights reserved.
//

import CoreData
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    fileprivate var _managedObjectContext: NSManagedObjectContext?
    fileprivate var _managedObjectModel: NSManagedObjectModel?
    fileprivate var _persistentStoreCoordinator: NSPersistentStoreCoordinator?
    
    private var defaultsManager: DVBDefaultsManager!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        defaultsManager = DVBDefaultsManager()
        defaultsManager.initApp()
        
        return true
    }
    
    // MARK: - Core Data stack
    
    func applicationDocumentsDirectory() -> URL? {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
    }
    
    var managedObjectModel: NSManagedObjectModel? {
        get {
            guard _managedObjectModel == nil else {
                return _managedObjectModel
            }
            
            guard let modelURL = Bundle.main.url(forResource: "dvach-browser", withExtension: "momd") else {
                return nil
            }
            
            _managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)
            return _managedObjectModel
        }
    }
    
    var persistentStoreCoordinator: NSPersistentStoreCoordinator? {
        get {
            guard _persistentStoreCoordinator == nil else {
                return _persistentStoreCoordinator
            }
            
            guard let managedObjectModel = self.managedObjectModel else {
                return nil
            }
            
            // Create the coordinator and store
            _persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
            if let _persistentStoreCoordinator = _persistentStoreCoordinator {
                guard let applicationDocumentsDirectory = applicationDocumentsDirectory() else {
                    return nil
                }
                let storeURL = applicationDocumentsDirectory.appendingPathComponent("dvach-browser.sqlite")
                let failureReason = "There was an error creating or loading the application's saved data."
                do {
                    try _persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
                } catch {
                    // Report any error we got.
                    var dict: [AnyHashable : Any] = [:]
                    dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
                    dict[NSLocalizedFailureReasonErrorKey] = failureReason
                    dict[NSUnderlyingErrorKey] = error
                    let error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict as? [String : Any])
                    if let user = (error as NSError?)?.userInfo {
                        print("Unresolved error \(error), \(user)")
                    }
                    abort()
                }
            }
            
            return _persistentStoreCoordinator
        }
    }
    
    var managedObjectContext: NSManagedObjectContext? {
        get {
            guard _managedObjectContext == nil else {
                return _managedObjectContext
            }
            
            let coordinator = persistentStoreCoordinator
            
            _managedObjectContext = NSManagedObjectContext()
            guard  let _managedObjectContext = _managedObjectContext else  {
                return nil
            }
            _managedObjectContext.persistentStoreCoordinator = coordinator
            return _managedObjectContext
        }
    }
    
    // MARK: - Core Data Saving support
    
    func saveContext()
    {
        if let managedObjectContext = self.managedObjectContext {
            if managedObjectContext.hasChanges {
                do {
                    try managedObjectContext.save()
                } catch {
                    print("Unresolved error \(error), \((error as NSError).userInfo)");
                    abort();
                }
            }
        }
    }
}

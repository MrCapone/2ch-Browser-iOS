//
//  DVBDefaultsManager.swift
//  dvach-browser
//
//  Created by Dmitry on 16.07.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import Foundation
import UIKit
import AFNetworking
import AsyncDisplayKit
import PINCache
import SDWebImage

@objc class DVBDefaultsManager: NSObject {
    private var networking: DVBNetworking!
    
    @objc class func initialDefaultsMattersForAppReset() -> [AnyHashable : Any]? {
        let defDarkTheme = UserDefaults.standard.bool(forKey: SETTING_ENABLE_DARK_THEME)
        let defClearThreads = UserDefaults.standard.bool(forKey: SETTING_CLEAR_THREADS)
        return [
            SETTING_ENABLE_DARK_THEME: NSNumber(value: defDarkTheme),
            SETTING_CLEAR_THREADS: NSNumber(value: defClearThreads)
        ]
    }
    
    @objc class func needToReset(withStoredDefaults defaultsToCompare: [AnyHashable : Any]?) -> Bool {
        let defDarkTheme = UserDefaults.standard.bool(forKey: SETTING_ENABLE_DARK_THEME)
        let defClearThreads = UserDefaults.standard.bool(forKey: SETTING_CLEAR_THREADS)
        let storedDefDarkTheme = defaultsToCompare?[SETTING_ENABLE_DARK_THEME] as? NSNumber
        let storedDefClearThreads = defaultsToCompare?[SETTING_CLEAR_THREADS] as? NSNumber
        
        if storedDefDarkTheme?.boolValue ?? false != defDarkTheme || storedDefClearThreads?.boolValue ?? false != defClearThreads {
            return true
        }
        
        return false
    }
    
    deinit {
        observeDefaults(false)
    }
    
    func initApp() {
        
        networking = DVBNetworking()
        let userAgent = networking.userAgent()!
        
        // User defaults
        let defaults: [String: Any] = [
            USER_AGREEMENT_ACCEPTED: NSNumber(value: false),
            SETTING_ENABLE_DARK_THEME: NSNumber(value: false),
            SETTING_CLEAR_THREADS: NSNumber(value: false),
            SETTING_FORCE_CAPTCHA: NSNumber(value: false),
            SETTING_BASE_DOMAIN: DVACH_DOMAIN,
            PASSCODE: "",
            USERCODE: "",
            DEFAULTS_AGE_CHECK_STATUS: NSNumber(value: false),
            DEFAULTS_USERAGENT_KEY: userAgent
        ]
        
        UserDefaults.standard.register(defaults: defaults)
        UserDefaults.standard.synchronize()
        
        // Turn off Shake to Undo because of tags on post screen
        UIApplication.shared.applicationSupportsShakeToEdit = false
        
        manageDownloadsUserAgent(userAgent)
        managePasscode()
        manageAFNetworking()
        manageDb()
        appearanceTudeUp()
        observeDefaults(true)
    }
    
    func manageDownloadsUserAgent(_ userAgent: String?) {
        // Prevent Clauda from shitting on my network queries
        SDWebImageManager.shared().imageDownloader.setValue(
            userAgent,
            forHTTPHeaderField: NETWORK_HEADER_USERAGENT_KEY)
        ASPINRemoteImageDownloader.setSharedImageManagerWith(URLSessionConfiguration.default)
        
    }
    
    func observeDefaults(_ enable: Bool) {
        if enable {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(defaultsChanged),
                name: UserDefaults.didChangeNotification,
                object: nil)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(defaultsChanged),
                name: UIContentSizeCategory.didChangeNotification,
                object: nil)
        } else {
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    func managePasscode() {
        let passcode = UserDefaults.standard.string(forKey: PASSCODE)!
        let usercode = UserDefaults.standard.string(forKey: USERCODE)!
        
        let isPassCodeNotEmpty = !(passcode == "")
        let isUserCodeEmpty = usercode == ""
        
        if isPassCodeNotEmpty && isUserCodeEmpty {
            networking.getUserCode(
                withPasscode: passcode,
                andCompletion: { completion in
                    if let usercode = completion {
                        UserDefaults.standard.set(usercode, forKey: USERCODE)
                        UserDefaults.standard.synchronize()
                        
                        self.setUserCodeCookieWithUsercode(usercode: usercode)
                    }
            })
        } else if !isPassCodeNotEmpty {
            deleteUsercodeOldData()
        } else if !isUserCodeEmpty {
            self.setUserCodeCookieWithUsercode(usercode: usercode)
        }
    }
    
    /// Execute all AFNetworking methods that need to be executed one time for entire app.
    func manageAFNetworking() {
        AFNetworkReachabilityManager.shared().startMonitoring()
        AFNetworkActivityIndicatorManager.shared().isEnabled = true
    }
    
    /// Create cookies for later posting with super csecret usercode
    func setUserCodeCookieWithUsercode(usercode: String) {
        let usercodeCookieDictionary: [HTTPCookiePropertyKey: Any] = [
            .name: "usercode_nocaptcha",
            .value: usercode
        ]
        let usercodeCookie = HTTPCookie(properties: usercodeCookieDictionary)!
        HTTPCookieStorage.shared.setCookie(usercodeCookie)
    }
    
    func deleteUsercodeOldData() {
        UserDefaults.standard.set("", forKey: USERCODE)
        UserDefaults.standard.synchronize()
        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                if (cookie.name == "usercode_nocaptcha") {
                    HTTPCookieStorage.shared.deleteCookie(cookie)
                    break
                }
            }
        }
    }
    
    func manageDb() {
        let shouldClearDB = UserDefaults.standard.bool(forKey: SETTING_CLEAR_THREADS)
        
        if shouldClearDB {
            self.clearDB()
        }
    }
    
    func clearDB() {
        self.clearAllCaches()
        let dbManager = DVBDatabaseManager.sharedDatabase()
        dbManager.clearAll()
        
        // Disable observing to prevent dead lock because of notificaitons
        self.observeDefaults(false)
        
        // Disable setting
        UserDefaults.standard.set(false,
                                  forKey:SETTING_CLEAR_THREADS)
        UserDefaults.standard.synchronize()
        
        // Re-enable Defaults observing
        self.observeDefaults(true)
    }
    
    func clearAllCaches() {
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearDisk()
        PINCache.shared.removeAllObjects()
    }
    
    /// Tuning appearance for entire app.
    func appearanceTudeUp() {
        UIView.appearance().tintColor = DVACH_COLOR
        UIButton.appearance(whenContainedInInstancesOf: [DVBPostPhotoContainerView.self]).tintColor = UIColor.white
        
        let colorView:UIView! = UIView()
        if UserDefaults.standard.bool(forKey: SETTING_ENABLE_DARK_THEME) {
            colorView.backgroundColor = CELL_SEPARATOR_COLOR_BLACK
        } else {
            colorView.backgroundColor = CELL_SEPARATOR_COLOR
        }
        UITableViewCell.appearance().selectedBackgroundView = colorView
    }
    
    @objc func defaultsChanged() {
        DVBUrls.reset()
        self.clearDB()
        self.appearanceTudeUp()
    }
}

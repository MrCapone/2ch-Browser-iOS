//
//  DVBUrls.swift
//  dvach-browser
//
//  Created by Dmitry on 28.07.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import Foundation

@objc class DVBUrls: NSObject {
    /// https://2ch.hk/
    @objc static var base: String {
        get {
            return "https://\(self.domain())"
        }
    }
    
    /// 2ch.hk/
    @objc static var baseWithoutScheme: String {
        get {
            return "\(self.domain())/"
        }
    }
    
    /// 2ch.hk
    @objc static var baseWithoutSchemeForUrlNinja: String {
        get {
            return self.domain()
        }
    }
    
     /// Always 2ch.hk
    @objc static var baseWithoutSchemeForUrlNinjaHk: String {
        get {
            return "2ch.hk"
        }
    }
    
    /// https://2ch.hk/makaba/makaba.fcgi
    @objc static var reportThread: String {
        get {
            "https://\(self.domain())/makaba/makaba.fcgi"
        }
    }
    
    /// https://2ch.hk/makaba/mobile.fcgi?task=get_boards
    @objc static var boardsList: String {
        get {
            return "https://\(self.domain())/makaba/mobile.fcgi?task=get_boards"
        }
    }
    
     /// https://2ch.hk/makaba/makaba.fcgi
    @objc static var getUsercode: String {
        get {
            "https://\(self.domain())/makaba/makaba.fcgi"
        }
    }
    

    /// Recalculate all base urls
    @objc class func reset() {
        //not needed on swift, left for compatibility with old obj-c code
    }
    
    // Private
    class func domain() -> String {
        return UserDefaults.standard.string(forKey: SETTING_BASE_DOMAIN) ?? ""
    }
}

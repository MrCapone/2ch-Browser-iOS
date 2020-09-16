//
//  NSNotification+DVBBookmarkThreadNotification.swift
//  dvach-browser
//
//  Created by Dmitry on 16.09.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import Foundation

extension NSNotification {
    @objc var title: String {
        get {
            return (self.userInfo?["title"] as? String) ?? ""
        }
    }
    @objc var url: String {
        get {
            return (self.userInfo?["url"] as? String) ?? ""
        }
    }
}

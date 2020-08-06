//
//  DVBMessagePostServerAnswer.swift
//  dvach-browser
//
//  Created by Dmitry on 06.08.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import Foundation

@objc class DVBMessagePostServerAnswer: NSObject {
    @objc private(set) var success = false
    @objc private(set) var statusMessage: String?
    /// New thread id number
    @objc private(set) var threadToRedirectTo: String?
    /// Num of new post in current thread
    @objc private(set) var num: String?

    convenience override init() {
        NSException(
            name: NSExceptionName("Need additional parameters"),
            reason: "Use -[[DVBMessagePostServerAnswer alloc] initWithSuccess:andStatusMessage:andThreadToRedirectTo:]",
            userInfo: nil).raise()
        
        fatalError()
    }

    init(success: Bool, andStatusMessage statusMessage: String?, andNum postNum: String?, andThreadToRedirectTo threadToRedirectTo: String?) {
        self.success = success
        self.statusMessage = statusMessage
        num = postNum
        self.threadToRedirectTo = threadToRedirectTo
        
        super.init()
    }
}

//
//  DVBCreatePostViewControllerDelegate.swift
//  dvach-browser
//
//  Created by Dmitry on 17.09.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import Foundation

@objc protocol DVBCreatePostViewControllerDelegate: NSObjectProtocol {
    /// Open thread after creating
    @objc func openThred(withCreatedThread threadNum: String?)
    /// Update thread after posting
    @objc optional func updateThreadAfterPosting()
}

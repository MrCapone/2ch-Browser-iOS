//
//  DVBThreadDelegate.swift
//  dvach-browser
//
//  Created by Dmitry on 17.09.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import Foundation
import UIKit

@objc protocol DVBThreadDelegate: NSObjectProtocol {
    @objc func openGalleryWIthUrl(_ url: String)
    @objc func quotePostIndex(_ index: Int, andText text: String?)
    @objc func showAnswers(for index: Int)
    @objc func share(withUrl url: String)
    @objc func isLinkInternal(withLink url: UrlNinja) -> Bool
    /// Open single post
    @objc func openPost(with urlNinja: UrlNinja)
    /// Open whole new thread
    @objc func openThread(with urlNinja: UrlNinja)
}

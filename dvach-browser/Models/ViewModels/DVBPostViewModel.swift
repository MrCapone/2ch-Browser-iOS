//
//  DVBPostViewModel.swift
//  dvach-browser
//
//  Created by Dmitry on 06.08.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import Foundation

@objc class DVBPostViewModel: NSObject {
    @objc private(set) var title: String?
    @objc private(set) var num: String?
    @objc private(set) var text: NSAttributedString?
    @objc private(set) var index = 0
    @objc private(set) var repliesCount = 0
    @objc private(set) var thumbs: [String]?
    @objc private(set) var pictures: [String]?
    @objc var timestamp: NSNumber = 0

    @objc init(post: DVBPost?, andIndex index: Int) {
        super.init()
        if let num = post?.num {
            title = String(format: "#%ld • %@ • ", index + 1, num)
        }
        num = post?.num
        text = post?.comment
        self.index = index
        repliesCount = post?.replies.count ?? 0
        thumbs = post?.thumbPathesArray
        pictures = post?.pathesArray
        timestamp = post?.timestamp ?? 0
    }

    /// To prevent multiple nesting
    @objc func convertToNested() {
        repliesCount = 0
    }
}

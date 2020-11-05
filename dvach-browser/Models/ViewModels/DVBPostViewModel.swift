//
//  DVBPostViewModel.swift
//  dvach-browser
//
//  Created by Dmitry on 06.08.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import Foundation

class DVBPostViewModel: DVBPost {
    private(set) var title: String!
    private(set) var text: NSAttributedString!
    private(set) var index = 0
    private(set) var repliesCount = 0
    private(set) var thumbs: [String]!
    private(set) var pictures: [String]!

    init(post: DVBPost?, andIndex index: Int) {
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
    
    required init!(coder: NSCoder!) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init(dictionary dictionaryValue: [AnyHashable : Any]!) throws {
        fatalError("init(dictionary:) has not been implemented")
    }
    
    /// To prevent multiple nesting
    func convertToNested() {
        repliesCount = 0
    }
}

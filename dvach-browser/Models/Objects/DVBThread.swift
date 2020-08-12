//
//  DVBThread.swift
//  dvach-browser
//
//  Created by Dmitry on 29.07.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

/**
*  Object for storing information about specific thread
*
*  @return Object with full info about board
*/

import Foundation
import Mantle

@objc class DVBThread: MTLModel, MTLJSONSerializing {
    /// UID of the open post of the thread.
    @objc var num: String = ""
    /// Subject of the thread
    @objc var subject: NSMutableString = ""
    /// Text of open post message.
    @objc var comment: NSMutableString = ""
    /// Count of posts inside given thread.
    @objc var postsCount: NSNumber = 0
    /// Path for open post's thumnail image
    @objc var thumbnail: String = ""
    @objc var timeSinceFirstPost: NSNumber = 0

    @objc class func jsonKeyPathsByPropertyKey() -> [AnyHashable : Any]? {
        return [
            "num": "num",
            "comment": "comment",
            "subject": "subject",
            "postsCount": "posts_count",
            "timeSinceFirstPost": "timestamp"
        ]
    }

    @objc class func subjectJSONTransformer() -> ValueTransformer? {
        return MTLValueTransformer.init(usingForwardBlock: { string, success, error in
            return (string as! NSString).convertingHTMLToPlainText()
        })
    }

    @objc class func commentJSONTransformer() -> ValueTransformer? {
        return MTLValueTransformer.init(usingForwardBlock: { string, success, error in
            var comment = string
            comment = (comment as! NSString).replacingOccurrences(of: "<br>", with: "\n")
            return (comment as! NSString).convertingHTMLToPlainText()
        })
    }

    @objc class func timeSinceFirstPostJSONTransformer() -> ValueTransformer? {
        return MTLValueTransformer.init(usingForwardBlock: { timestamp, success, error in
            return DVDateFormatter.date(fromTimestamp: (timestamp as! NSNumber).intValue)
        })
    }

    @objc class func threadControllerTitle(fromTitle title: String?, andNum num: String, andComment comment: String?) -> String {
        guard let title = title, !title.isEmpty else {
            return num
        }
        guard let comment = comment, !comment.contains(num) else {
            return num
        }
        return title
    }

    @objc class func isTitle(_ title: String?, madeFromComment comment: String?) -> Bool {
        if (title?.count ?? 0) > 2 && (comment?.count ?? 0) > 2 {
            if (title as NSString?)?.substring(to: 2) == (comment as NSString?)?.substring(to: 2) {
                return true
            }
        }
        return false
    }
}

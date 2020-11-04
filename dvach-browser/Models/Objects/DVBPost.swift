//
//  DVBPost.swift
//  dvach-browser
//
//  Created by Dmitry on 29.07.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import Foundation
import Mantle

@objc class DVBPost: MTLModel, MTLJSONSerializing {
    /// Number of the post
    @objc var num: String?
    /// Subject of the post (for section title in thread View Controller and thread View Controller title)
    @objc private var subject: String?
    /// Text of post message.
    @objc var comment: NSAttributedString?
    /// Array of pathes for full images attached to post
    @objc var pathesArray: [String]?
    /// Array of pathes for thumbnail images attached to post
    @objc var thumbPathesArray: [String]?
    /// Name of the author of the post
    @objc private var name: String?
    /// Replies to this post from other posts in the thread / need to be mutable, as we change it afer creating
    @objc var replies: [DVBPost] = []
    /// Replies to other posts in this post, children of the same thread / need to be mutable, as we change it afer creating
    @objc var repliesTo: [String]?
    @objc var timestamp: NSNumber?
    
    @objc class func jsonKeyPathsByPropertyKey() -> [AnyHashable : Any]? {
        return [
            "num": "num",
            "subject": "subject",
            "timestamp": "timestamp",
            "name": "name"
        ]
    }
    
    @objc class func numJSONTransformer() -> ValueTransformer? {
        return MTLValueTransformer.init(usingForwardBlock: { (num, success, error) ->String in
            let numToReturn = num as? NSString ?? NSString(format: "%ld", (num as! NSNumber).intValue)
            return numToReturn as String
        })
    }
    
    @objc class func subjectJSONTransformer() -> ValueTransformer? {
        return MTLValueTransformer.init(usingForwardBlock: { (string, success, error) -> String? in
            var subject: String?
            if (string as! NSString?)?.range(of: "ررً").location == NSNotFound {
                subject = string as? String
            } else {
                let brokenStringHere = NSLS("POST_BAD_SYMBOLS_IN_POST")
                subject = brokenStringHere
            }
            return subject
        })
    }
}

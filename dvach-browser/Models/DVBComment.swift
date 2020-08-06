//
//  DVBComment.swift
//  dvach-browser
//
//  Created by Dmitry on 06.08.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import Foundation

@objc class DVBComment: NSObject {
    @objc var comment: String = ""

    // MARK: Singleton Methods
    static let sharedCommentSharedMyManager: DVBComment? = {
        var sharedMyManager = DVBComment()
        return sharedMyManager
    }()

    @objc class func sharedComment() -> DVBComment? {
        return sharedCommentSharedMyManager
    }

    ///  Add post number to answer text as an address
    ///
    ///  - Parameter postNum: post number we want to answer in our comment
    @objc func topUpComment(withPostNum postNum: String?) {
        let oldCommentText = comment

        var newStringOfComment: String?

        if oldCommentText == "" {
            // creating from empty comment
            newStringOfComment = ">>\(postNum ?? "")\n"
        } else {
            // if there is some text in comment already
            newStringOfComment = "\n>>\(postNum ?? "")\n"
        }

        let commentToSingleton = "\(oldCommentText)\(newStringOfComment ?? "")"

        comment = commentToSingleton
    }

    ///  Add post number to answer text as an address and original post text as a quote
    ///
    ///  - Parameters:
    ///   - postNum:          post number we want to answer in our comment
    ///    - originalPostText: full post text to use as a quote
    ///    - quoteString:      selected part of the post text to use as a quote
    @objc func topUpComment(withPostNum postNum: String?, andOriginalPostText originalPostText: NSAttributedString?, andQuoteString quoteString: String?) {
        topUpComment(withPostNum: postNum)

        var additionalCommentString: String?
        if quoteString != nil && ((quoteString?.count ?? 0) > 0) {
            additionalCommentString = "\(quoteString ?? "")"
        } else {
            additionalCommentString = "\(originalPostText?.string ?? "")"
        }

        // delete old quote symbols - so we'll not quote the quotes
        additionalCommentString = additionalCommentString?.replacingOccurrences(of: ">", with: "")

        // insert quotes symbol after all new line symbols
        additionalCommentString = additionalCommentString?.replacingOccurrences(of: "\n", with: "\n>")

        // delete all new empty lines with quotes
        additionalCommentString = additionalCommentString?.replacingOccurrences(of: "\n>\n", with: "\n")

        // merge old comment text + ">" symbol + new comment with ">" symbols inside
        let commentToSingleton = "\(comment)>\(additionalCommentString ?? "")\n"

        comment = commentToSingleton
    }
}

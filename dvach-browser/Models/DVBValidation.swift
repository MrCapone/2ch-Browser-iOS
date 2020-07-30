//
//  DVBValidation.swift
//  dvach-browser
//
//  Created by Dmitry on 29.07.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import Foundation

@objc class DVBValidation: NSObject {
    /// Check shortcode for presence of different symbols
    @objc func checkBoardShortCode(with boardCode: String?) -> Bool {
        let isBoardCodeNullString = boardCode == ""
        let isBoardCodeWithoutSlash = (boardCode as NSString?)?.range(of: "/").location == NSNotFound
        let isBoardCodeWithoutQuote = (boardCode as NSString?)?.range(of: "/\'").location == NSNotFound
        let isBoardCodeWithoutDoubleQuote = (boardCode as NSString?)?.range(of: "\"").location == NSNotFound
        let isBoardCodeWithoutSpace = (boardCode as NSString?)?.range(of: " ").location == NSNotFound

        // Check if all above is good.
        if !isBoardCodeNullString && isBoardCodeWithoutSlash && isBoardCodeWithoutQuote && isBoardCodeWithoutDoubleQuote && isBoardCodeWithoutSpace {
            return true
        }

        return false
    }
}

//
//  DVBPostStyler.swift
//  dvach-browser
//
//  Created by Dmitry on 07.08.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import Foundation
import UIKit

@objc class DVBPostStyler: NSObject {
    @objc class func postCellBackgroundColor() -> UIColor? {
        return DVBBoardStyler.threadCellBackgroundColor()
    }

    @objc class func postCellInsideBackgroundColor() -> UIColor? {
        return DVBBoardStyler.threadCellInsideBackgroundColor()
    }

    @objc class func textColor() -> UIColor? {
        return DVBBoardStyler.textColor()
    }

    @objc class func borderColor() -> CGColor? {
        return DVBBoardStyler.borderColor()
    }

    @objc class func mediaSize() -> CGFloat {
        return IS_IPAD ? 150 : 62
    }

    @objc class func elementInset() -> CGFloat {
        return DVBBoardStyler.elementInset()
    }

    @objc class func innerInset() -> CGFloat {
        return 2 * self.elementInset()
    }

    @objc class func cornerRadius() -> CGFloat {
        return DVBBoardStyler.cornerRadius()
    }

    @objc class func ageCheckNotPassed() -> Bool {
        return DVBBoardStyler.ageCheckNotPassed()
    }
}

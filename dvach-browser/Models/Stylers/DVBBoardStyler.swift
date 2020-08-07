//
//  DVBBoardStyler.swift
//  dvach-browser
//
//  Created by Dmitry on 07.08.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import Foundation
import UIKit

@objc class DVBBoardStyler: NSObject {
// MARK: - Thread list
    @objc class func threadCellBackgroundColor() -> UIColor? {
        return self.isDarkTheme() ? UIColor.black : UIColor(red: 0.95, green: 0.96, blue: 0.97, alpha: 1)
    }

    @objc class func threadCellInsideBackgroundColor() -> UIColor? {
        return self.isDarkTheme() ? CELL_BACKGROUND_COLOR : UIColor.white
    }

    @objc class func textColor() -> UIColor? {
        return self.isDarkTheme() ? DARK_CELL_TEXT_COLOR : UIColor.black
    }

    @objc class func borderColor() -> CGColor? {
        let color = self.isDarkTheme() ? UIColor(red: 38.0 / 255.0, green: 38.0 / 255.0, blue: 38.0 / 255.0, alpha: 1) : UIColor.lightGray
        return color.cgColor
    }

    @objc class func mediaSize() -> CGFloat {
        return IS_IPAD ? 150 : 100
    }

    @objc class func elementInset() -> CGFloat {
        return 10
    }

    @objc class func cornerRadius() -> CGFloat {
        return IS_IPAD ? 6 : 3
    }

    @objc class func isDarkTheme() -> Bool {
        return UserDefaults.standard.bool(forKey: SETTING_ENABLE_DARK_THEME)
    }

    @objc class func ageCheckNotPassed() -> Bool {
        return !UserDefaults.standard.bool(forKey: DEFAULTS_AGE_CHECK_STATUS)
    }
}

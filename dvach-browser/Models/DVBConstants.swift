//
//  DVBConstants.swift
//  dvach-browser
//
//  Created by Dmitry on 16.07.2020.
//  Copyright © 2020 8of. All rights reserved.
//

import Foundation

// iOS version checkers
func SYSTEM_VERSION_EQUAL_TO(_ v: String) -> Bool {
    UIDevice.current.systemVersion.compare(v, options: .numeric, range: nil, locale: .current) == .orderedSame
}
func SYSTEM_VERSION_GREATER_THAN(_ v: String) -> Bool {
    UIDevice.current.systemVersion.compare(v, options: .numeric, range: nil, locale: .current) == .orderedDescending
}
func SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(_ v: String) -> Bool {
    UIDevice.current.systemVersion.compare(v, options: .numeric, range: nil, locale: .current) != .orderedAscending
}
func SYSTEM_VERSION_LESS_THAN(_ v: String) -> Bool {
    UIDevice.current.systemVersion.compare(v, options: .numeric, range: nil, locale: .current) == .orderedAscending
}
func SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(_ v: String) -> Bool {
    UIDevice.current.systemVersion.compare(v, options: .numeric, range: nil, locale: .current) != .orderedDescending
}

// Sizes
let ONE_PIXEL = 1.0 / UIScreen.main.scale
// Colors
let DVACH_COLOR = UIColor(red: 255.0 / 255.0, green: 139.0 / 255.0, blue: 16.0 / 255.0, alpha: 1.0)
let DVACH_COLOR_CG = UIColor(red: 255.0 / 255.0, green: 139.0 / 255.0, blue: 16.0 / 255.0, alpha: 1.0).cgColor
let DVACH_COLOR_HIGHLIGHTED = UIColor(red: 255.0 / 255.0, green: 139.0 / 255.0, blue: 16.0 / 255.0, alpha: 0.3)
let DVACH_COLOR_HIGHLIGHTED_CG = UIColor(red: 255.0 / 255.0, green: 139.0 / 255.0, blue: 16.0 / 255.0, alpha: 0.3).cgColor
let THUMBNAIL_GREY_BORDER = UIColor(red: 151.0 / 255.0, green: 151.0 / 255.0, blue: 151.0 / 255.0, alpha: 1.0).cgColor
let CELL_SEPARATOR_COLOR = UIColor(red: 200.0 / 255.0, green: 200.0 / 255.0, blue: 204.0 / 255.0, alpha: 1.0)

// Colors - Dark theme
let CELL_BACKGROUND_COLOR = UIColor(red: 35.0 / 255.0, green: 35.0 / 255.0, blue: 37.0 / 255.0, alpha: 1.0)
let DARK_CELL_TEXT_COLOR = UIColor(red: 199.0 / 255.0, green: 199.0 / 255.0, blue: 204.0 / 255.0, alpha: 1.0)
let CELL_TEXT_COLOR = UIColor(red: 199.0 / 255.0, green: 199.0 / 255.0, blue: 204.0 / 255.0, alpha: 1.0)
let CELL_SEPARATOR_COLOR_BLACK = UIColor(red: 24.0 / 255.0, green: 24.0 / 255.0, blue: 26.0 / 255.0, alpha: 1.0)
let CELL_TEXT_SPOILER_COLOR = UIColor(red: 199.0 / 255.0, green: 199.0 / 255.0, blue: 204.0 / 255.0, alpha: 0.3)

// URL schemes
let HTTPS_SCHEME = "https://"
let HTTP_SCHEME = "http://"
// URLs
let DVACH_DOMAIN = "2ch.hk"

// Network
let NETWORK_HEADER_USERAGENT_KEY = "User-Agent"

// Settings
let SETTING_ENABLE_DARK_THEME = "enableDarkTheme"
let SETTING_CLEAR_THREADS = "clearThreads"
let SETTING_BASE_DOMAIN = "domain"
let SETTING_FORCE_CAPTCHA = "forceCaptcha"
let USER_AGREEMENT_ACCEPTED = "userAgreementAccepted"
let PASSCODE = "passcode"
let USERCODE = "usercode"
let DEFAULTS_AGE_CHECK_STATUS = "defaultsAgeCheckStatus"
let DEFAULTS_USERAGENT_KEY = "UserAgent"

// Storyboards
let STORYBOARD_NAME_MAIN = "Main"

// Storyboard VC ID's
let STORYBOARD_ID_CREATE_POST_VIEW_CONTROLLER = "DVBCreateViewController"

// Segues
let SEGUE_TO_EULA = "segueToEula"

// Cells
let BOARD_CELL_IDENTIFIER = "boardEntryCell"

// Errors
let ERROR_DOMAIN_APP = "com.8of.dvach-browser.error"
let ERROR_USERINFO_KEY_IS_DDOS_PROTECTION = "NSErrorIsDDoSProtection"
let ERROR_USERINFO_KEY_URL_TO_CHECK_IN_BROWSER = "NSErrorUrlToCheckInBrowser"
let ERROR_CODE_DDOS_CHECK = 1001
let ERROR_OPERATION_HEADER_KEY_REFRESH = "refresh"
let ERROR_OPERATION_REFRESH_VALUE_SEPARATOR = "URL=/"
let WEBVIEW_PART_OF_THE_PAGE_TO_CHECK_MAIN_PAGE = ".ч"

// Notifications
let NOTIFICATION_NAME_BOOKMARK_THREAD = "kNotificationBookmarkThread"

// Keys
let AP_CAPTCHA_PUBLIC_KEY = "BiIWoUVlqn5AquNm1NY832D4Ljj0IOzR"
let AP_CAPTCHA_PRIVATE_KEY = ""


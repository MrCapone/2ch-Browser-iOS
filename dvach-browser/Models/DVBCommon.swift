//
//  DVBCommon.swift
//  dvach-browser
//
//  Created by Dmitry on 17.07.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import Foundation

func NSLS(_ key: String) ->String {
    return NSLocalizedString(key, comment: key)
}
let IS_IPAD = UI_USER_INTERFACE_IDIOM() == .pad

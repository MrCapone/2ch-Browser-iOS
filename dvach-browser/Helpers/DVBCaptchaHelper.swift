//
//  DVBCaptchaHelper.swift
//  dvach-browser
//
//  Created by Dmitry on 16.09.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import Foundation
import CommonCrypto

class DVBCaptchaHelper: NSObject {
    @objc class func appResponse(from appResponseId: String) -> String? {
        if AP_CAPTCHA_PRIVATE_KEY == "" {
            return nil
        }
        let fullString = "\(appResponseId)|\(AP_CAPTCHA_PRIVATE_KEY)"
        var s = fullString.cString(using: .ascii)
        let keyData = NSData(bytes: &s, length: strlen(s ?? []))

        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256(keyData.bytes, CC_LONG(keyData.count), &digest)
        let out = NSData(bytes: &digest, length: Int(CC_SHA256_DIGEST_LENGTH))
        var hash = out.description
        hash = hash.replacingOccurrences(of: " ", with: "")
        hash = hash.replacingOccurrences(of: "<", with: "")
        hash = hash.replacingOccurrences(of: ">", with: "")
        return hash
    }
}

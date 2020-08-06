//
//  DVBCaptchaManager.swift
//  dvach-browser
//
//  Created by Dmitry on 06.08.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import Foundation

@objc class DVBCaptchaManager: NSObject {
    private var networkManager: DVBNetworking

    override init() {
        networkManager = DVBNetworking()
        
        super.init()
    }

    @objc func getCaptchaImageUrl(_ threadNum: String?, andCompletion completion: @escaping (String?, String?) -> Void) {
        networkManager.getCaptchaImageUrl(
            threadNum,
            andCompletion: { fullUrl, captchaId in
                if fullUrl != nil {
                    completion(fullUrl, captchaId ?? "")
                } else {
                    completion(nil, nil)
                }

            })
    }
}

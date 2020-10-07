//
//  DVBAlertGenerator.swift
//  dvach-browser
//
//  Created by Dmitry on 07.10.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import Foundation
import UIKit

@objc protocol DVBAlertGeneratorDelegate: NSObjectProtocol {
    @objc func addBoard(withCode code: String?)
}

@objc class DVBAlertGenerator: NSObject {
    @objc weak var alertGeneratorDelegate: DVBAlertGeneratorDelegate?
    
    @objc class func ageCheckAlert() -> UIAlertController? {
        let title = NSLS("ALERT_AGE_CHECK_TITLE")
        let message = NSLS("ALERT_AGE_CHECK_MESSAGE")
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert)
        let cancelAction = UIAlertAction(
            title: NSLS("BUTTON_CANCEL"),
            style: .cancel,
            handler: { action in
            })
        alertController.addAction(cancelAction)
        let okAction = UIAlertAction(
            title: NSLS("ALERT_AGE_CHECK_CONFIRM"),
            style: .default,
            handler: { action in
                UserDefaults.standard.set(
                    true,
                    forKey: DEFAULTS_AGE_CHECK_STATUS)
                UserDefaults.standard.synchronize()
            })
        alertController.addAction(okAction)
        return alertController
    }
    
    @objc func boardCodeAlert() -> UIAlertController? {
        let title = NSLS("ALERT_BOARD_CODE_TITLE")
        let message = NSLS("ALERT_BOARD_CODE_MESSAGE")
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert)
        alertController.addTextField(configurationHandler: { textField in
            if UserDefaults.standard.bool(forKey: SETTING_ENABLE_DARK_THEME) {
                textField.keyboardAppearance = .dark
            }
        })
        let cancelAction = UIAlertAction(
            title: NSLS("BUTTON_CANCEL"),
            style: .cancel,
            handler: { action in
            })
        alertController.addAction(cancelAction)

        let okAction = UIAlertAction(
            title: NSLS("BUTTON_OK"),
            style: .default,
            handler: { [self] action in
                let textField = alertController.textFields?.first
                if textField == nil {
                    return
                }
                let code = textField?.text
                textField?.resignFirstResponder()

                let validation = DVBValidation()
                // checking shortcode for presence of not appropriate symbols
                if validation.checkBoardShortCode(with: code) {
                    if let alertGeneratorDelegate = alertGeneratorDelegate, alertGeneratorDelegate.responds(to: #selector(DVBAlertGeneratorDelegate.addBoard(withCode:))) {
                        alertGeneratorDelegate.addBoard(withCode: code)
                    }
                }
            })
        alertController.addAction(okAction)
        return alertController
    }
}

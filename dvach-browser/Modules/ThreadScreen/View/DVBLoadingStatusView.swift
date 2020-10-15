//
//  DVBLoadingStatusView.swift
//  dvach-browser
//
//  Created by Dmitry on 15.10.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import UIKit

private let IMAGE_NAME_LOAD = "LoadingStatus_1"
private let IMAGE_NAME_ERROR = "LoadingStatusError"

@objc enum DVBLoadingStatusViewStyle : Int {
    case loading
    case error
}

@objc enum DVBLoadingStatusViewColor : Int {
    case light
    case dark
}


@objc class DVBLoadingStatusView: UIView {
    private(set) var loadingStatusViewStyle: DVBLoadingStatusViewStyle!
    
    @IBOutlet private var statusIcon: UIImageView!
    @IBOutlet private var statusLabel: UILabel!
    
    @objc class func instanceFromNib() -> DVBLoadingStatusView? {
        let nibName = NSStringFromClass(DVBLoadingStatusView.self)
        if let last = Bundle.main.loadNibNamed(nibName, owner: nil, options: nil)?.last as? DVBLoadingStatusView {
            return last
        }
        return nil
    }
    
    @objc func initLoadingStatusView(withMessage message: String?, andStyle style: DVBLoadingStatusViewStyle, andColor color: DVBLoadingStatusViewColor) {
        statusLabel.text = message
        loadingStatusViewStyle = style
        
        switch style {
        case DVBLoadingStatusViewStyle.loading:
            statusIcon.image = UIImage(named: IMAGE_NAME_LOAD)?.withRenderingMode(.alwaysTemplate)
        case DVBLoadingStatusViewStyle.error:
            statusIcon.image = UIImage(named: IMAGE_NAME_ERROR)?.withRenderingMode(.alwaysTemplate)
        }
        
        switch color {
        case DVBLoadingStatusViewColor.light:
            statusLabel.textColor = UIColor.gray
            statusIcon.tintColor = UIColor.gray
        case DVBLoadingStatusViewColor.dark:
            statusLabel.textColor = UIColor.white
            statusIcon.tintColor = UIColor.white
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

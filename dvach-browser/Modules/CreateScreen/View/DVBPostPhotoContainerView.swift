//
//  DVBPostPhotoContainerView.swift
//  dvach-browser
//
//  Created by Dmitry on 13.10.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import UIKit

class DVBPostPhotoContainerView: UIView {
    override func awakeFromNib() {
        super.awakeFromNib()
        setupCustomDesign()
    }

    func setupCustomDesign() {
        layer.backgroundColor = DVACH_COLOR_CG
        layer.cornerRadius = 15.0
        clipsToBounds = true
    }
}

//
//  DVBCreatePostScrollView.swift
//  dvach-browser
//
//  Created by Dmitry on 13.10.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import UIKit

class DVBCreatePostScrollView: UIScrollView {
    override func touchesShouldCancel(in view: UIView) -> Bool {
        if view is UIButton {
            return true
        }

        return super.touchesShouldCancel(in: view)
    }
}

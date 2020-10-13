//
//  DVBMarkupButton.swift
//  dvach-browser
//
//  Created by Dmitry on 13.10.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import UIKit

class DVBMarkupButton: UIButton {
    override func awakeFromNib() {
        super.awakeFromNib()
        
        layer.cornerRadius = 5
        layer.borderWidth = 1
        layer.borderColor = DVACH_COLOR_CG
    }
    
    func setHighlighted(_ highlighted: Bool) {
        super.isHighlighted = highlighted
        
        if highlighted {
            layer.borderColor = DVACH_COLOR_HIGHLIGHTED_CG
        } else {
            layer.borderColor = DVACH_COLOR_CG
        }
    }
}

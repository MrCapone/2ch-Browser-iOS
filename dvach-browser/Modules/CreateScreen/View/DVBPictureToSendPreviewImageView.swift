//
//  DVBPictureToSendPreviewImageView.swift
//  dvach-browser
//
//  Created by Dmitry on 13.10.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import UIKit

class DVBPictureToSendPreviewImageView: UIImageView {
    override func awakeFromNib() {
        super.awakeFromNib()

        contentMode = .scaleAspectFill
        clipsToBounds = true
    }
}

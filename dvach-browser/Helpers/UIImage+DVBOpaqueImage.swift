//
//  UIImage+DVBOpaqueImage.swift
//  dvach-browser
//
//  Created by Dmitry on 16.09.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import UIKit

extension UIImage {
    @objc class func optimizedImage(from image: UIImage?) -> UIImage? {
        let imageSize = image?.size
        UIGraphicsBeginImageContextWithOptions(imageSize ?? CGSize.zero, true, UIScreen.main.scale)
        image?.draw(in: CGRect(x: 0, y: 0, width: imageSize?.width ?? 0.0, height: imageSize?.height ?? 0.0))
        let optimizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return optimizedImage
    }
}

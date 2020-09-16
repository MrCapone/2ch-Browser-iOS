//
//  UIImage+DVBImageExtention.swift
//  dvach-browser
//
//  Created by Dmitry on 16.09.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import UIKit
import ObjectiveC

extension UIImage {
    private struct AssociatedKeys {
        static var imageExtention: UInt8 = 0
    }
    
    @objc var imageExtention: String? {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.imageExtention, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        get {
            guard let value = objc_getAssociatedObject(self, &AssociatedKeys.imageExtention) as? String else {
                return nil
            }
            
            return value
        }
    }
}

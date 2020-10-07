//
//  DVBPostViewGenerator.swift
//  dvach-browser
//
//  Created by Dmitry on 06.10.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import AsyncDisplayKit
import Foundation

@objc class DVBPostViewGenerator: NSObject {
    @objc class func borderNode() -> ASDisplayNode {
        let node = ASDisplayNode()
        node.isOpaque = true
        node.borderColor = DVBPostStyler.borderColor()
        node.borderWidth = ONE_PIXEL
        node.backgroundColor = DVBPostStyler.postCellInsideBackgroundColor()
        node.cornerRadius = DVBPostStyler.cornerRadius()
        
        return node
    }
    
    @objc class func titleNode() -> ASTextNode {
        let node = ASTextNode()
        node.backgroundColor = DVBPostStyler.postCellInsideBackgroundColor()
        node.truncationMode = NSLineBreakMode.byTruncatingTail
        node.maximumNumberOfLines = 1
        return node
    }
    
    @objc class func textNode(withText text: NSAttributedString) -> ASTextNode {
        let node = ASTextNode()
        node.backgroundColor = DVBPostStyler.postCellInsideBackgroundColor()
        node.attributedText = text
        node.truncationMode = NSLineBreakMode.byWordWrapping
        node.maximumNumberOfLines = 0
        return node
    }
    
    @objc class func mediaNode(withURL url: String?, isWebm: Bool) -> ASNetworkImageNode? {
        let node = ASNetworkImageNode()
        let mediaWidth: CGFloat = DVBPostStyler.ageCheckNotPassed() ? 0 : DVBPostStyler.mediaSize()
        node.backgroundColor = DVBPostStyler.postCellInsideBackgroundColor()
        node.style.width = ASDimensionMakeWithPoints(mediaWidth)
        node.style.height = ASDimensionMakeWithPoints(DVBPostStyler.mediaSize())
        node.url = URL(string: url ?? "")
        node.imageModificationBlock = { [self] image, traitCollection in
            let rect = CGRect(x: 0, y: 0, width: image.size.width , height: image.size.height )
            let scale = UIScreen.main.scale
            UIGraphicsBeginImageContextWithOptions(image.size , true, scale)
            
            // Fill background with color
            DVBPostStyler.postCellInsideBackgroundColor()?.set()
            UIRectFill(CGRect(x: 0, y: 0, width: rect.size.width, height: rect.size.height))
            
            UIBezierPath(roundedRect: rect, cornerRadius: DVBPostStyler.cornerRadius()).addClip()
            image.draw(in: rect)
            if isWebm {
                let icon = self.webmIcon()
                let iconSide = (icon?.size.width ?? 0.0) * scale
                let iconX = (rect.size.width - iconSide) / 2
                let iconY = (rect.size.width - iconSide) / 2
                let iconRect = CGRect(x: iconX, y: iconY, width: iconSide, height: iconSide)
                icon?.draw(in: iconRect)
            }
            let modifiedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return modifiedImage!
        }
        return node
    }
    
    private class func webmIcon() -> UIImage? {
        return UIImage(named: "Video")
    }
    
    @objc class func answerButton() -> ASButtonNode? {
        let node = self.button()
        node?.backgroundColor = DVBPostStyler.postCellInsideBackgroundColor()
        let image = UIImage(named: "AnswerToPost")
        node?.setImage(image, for: .normal)
        node?.style.height = ASDimensionMake(22)
        return node
    }
    
    @objc class func showAnswersButton(withCount count: Int) -> ASButtonNode? {
        let node = self.button()
        node?.backgroundColor = DVBPostStyler.postCellInsideBackgroundColor()
        let title = String(format: "%li", count)
        let font = UIFont.systemFont(ofSize: UIFont.systemFontSize)
        node?.setTitle(
            title,
            with: font,
            with: DVACH_COLOR,
            for: UIControl.State.normal)
        node?.setTitle(
            title,
            with: font,
            with: DVACH_COLOR_HIGHLIGHTED,
            for: UIControl.State.highlighted)
        node?.style.height = ASDimensionMake(22)
        node?.style.minWidth = ASDimensionMake(33)
        node?.contentEdgeInsets = UIEdgeInsets(top: 0, left: DVBPostStyler.elementInset(), bottom: 0, right: DVBPostStyler.elementInset())
        return node
    }
    
    private class func button() -> ASButtonNode? {
        let node = ASButtonNode()
        node.tintColor = DVACH_COLOR
        node.borderColor = DVACH_COLOR_CG
        node.borderWidth = 1
        node.cornerRadius = DVBPostStyler.cornerRadius()
        return node
    }
}

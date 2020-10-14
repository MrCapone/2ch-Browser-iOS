//
//  DVBThreadNode.swift
//  dvach-browser
//
//  Created by Dmitry on 14.10.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import AsyncDisplayKit

class DVBThreadNode: ASCellNode, ASNetworkImageNodeDelegate {
    private var thread: DVBThread!
    private var postNode: ASTextNode!
    private var mediaNode: ASNetworkImageNode!
    private var borderNode: ASDisplayNode!
    
    // MARK: - Lifecycle
    init(thread: DVBThread) {
        super.init()
        
        self.thread = thread
        
        // Total border
        borderNode = ASDisplayNode()
        borderNode.borderColor = DVBBoardStyler.borderColor()
        borderNode.borderWidth = ONE_PIXEL
        borderNode.backgroundColor = DVBBoardStyler.threadCellInsideBackgroundColor()
        borderNode.cornerRadius = DVBBoardStyler.cornerRadius()
        addSubnode(borderNode)
        
        // Comment node
        postNode = ASTextNode()
        postNode.attributedText = fromComment(thread.comment, subject: thread.subject, posts: thread.postsCount)
        postNode.style.flexShrink = 1.0 //if name and username don't fit to cell width, allow username shrink
        postNode.truncationMode = NSLineBreakMode.byWordWrapping
        postNode.maximumNumberOfLines = 0
        postNode.textContainerInset = UIEdgeInsets(top: DVBBoardStyler.elementInset(), left: DVBBoardStyler.elementInset(), bottom: DVBBoardStyler.elementInset(), right: DVBBoardStyler.elementInset())
        addSubnode(postNode)
        
        // Media
        mediaNode = ASNetworkImageNode()
        let mediaWidth: CGFloat = DVBBoardStyler.ageCheckNotPassed() ? 0 : DVBBoardStyler.mediaSize()
        mediaNode.style.width = ASDimensionMakeWithPoints(mediaWidth)
        mediaNode.style.height = ASDimensionMakeWithPoints(DVBBoardStyler.mediaSize())
        mediaNode.url = URL(string: thread.thumbnail)
        mediaNode.delegate = self
        mediaNode.imageModificationBlock = { (image, traitCollection) -> UIImage? in
            var modifiedImage: UIImage?
            let rect = CGRect(x: 0, y: 0, width: image.size.width , height: image.size.height )
            UIGraphicsBeginImageContextWithOptions(image.size , false, UIScreen.main.scale)
            UIBezierPath(roundedRect: rect, byRoundingCorners: [.topLeft, .bottomLeft], cornerRadii: CGSize(width: DVBBoardStyler.cornerRadius(), height: DVBBoardStyler.cornerRadius())).addClip()
            image.draw(in: rect)
            modifiedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return modifiedImage
        }
        addSubnode(mediaNode)
    }
    
    func fromComment(_ comment: NSMutableString, subject: NSMutableString, posts: NSNumber) -> NSAttributedString {
        let textAttributes: [NSAttributedString.Key : Any] = [
            NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .subheadline),
            NSAttributedString.Key.foregroundColor: DVBBoardStyler.textColor()
        ]
        let string = String(format: "[%li] %@", posts.intValue , text(fromSubject: subject, andComment: comment))
        return NSAttributedString(string: string, attributes: textAttributes)
    }
    
    func text(fromSubject subject: NSMutableString, andComment comment: NSMutableString) -> String {
        if subject.length > 2 && comment.length > 2 {
            if subject.substring(to: 2) == comment.substring(to: 2) {
                return comment as String
            }
        }
        return "\(subject )\n\(comment)"
    }
    
    func setHighlighted(_ highlighted: Bool) {
        backgroundColor = DVBBoardStyler.threadCellBackgroundColor()
        if highlighted {
            borderNode.backgroundColor = DVBBoardStyler.threadCellBackgroundColor()
        } else {
            borderNode.backgroundColor = DVBBoardStyler.threadCellInsideBackgroundColor()
        }
    }
    
    func setSelected(_ selected: Bool) {
        backgroundColor = DVBBoardStyler.threadCellBackgroundColor()
        if selected {
            borderNode.backgroundColor = DVBBoardStyler.threadCellBackgroundColor()
        } else {
            borderNode.backgroundColor = DVBBoardStyler.threadCellInsideBackgroundColor()
        }
    }
    
    // MARK: - ASDisplayNode
    override func didLoad() {
        // enable highlighting now that self.layer has loaded -- see ASHighlightOverlayLayer.h
        layer.as_allowsHighlightDrawing = true
        super.didLoad()
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let horizontalStack = ASStackLayoutSpec.horizontal()
        horizontalStack.direction = ASStackLayoutDirection.horizontal
        horizontalStack.alignItems = ASStackLayoutAlignItems.stretch
        horizontalStack.style.height = ASDimensionMakeWithPoints(DVBBoardStyler.mediaSize())
        horizontalStack.children = [mediaNode, postNode]
        let insets = UIEdgeInsets(top: DVBBoardStyler.elementInset() / 2 + ONE_PIXEL, left: DVBBoardStyler.elementInset() + ONE_PIXEL, bottom: DVBBoardStyler.elementInset() / 2 + ONE_PIXEL, right: DVBBoardStyler.elementInset() + ONE_PIXEL)
        return ASInsetLayoutSpec(
            insets: insets,
            child: horizontalStack)
    }
    
    override func layout() {
        super.layout()
        // Manually layout the divider.
        borderNode.frame = CGRect(x: DVBBoardStyler.elementInset(), y: DVBBoardStyler.elementInset() / 2, width: calculatedSize.width - 2 * DVBBoardStyler.elementInset(), height: calculatedSize.height - DVBBoardStyler.elementInset())
    }
    
    // MARK: - ASNetworkImageNodeDelegate methods.
    func imageNode(_ imageNode: ASNetworkImageNode, didLoad image: UIImage) {
        setNeedsLayout()
    }
}

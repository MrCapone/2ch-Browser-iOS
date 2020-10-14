//
//  DVBPostNode.swift
//  dvach-browser
//
//  Created by Dmitry on 14.10.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import AsyncDisplayKit

@objc class DVBPostNode: ASCellNode, ASNetworkImageNodeDelegate, ASTextNodeDelegate {
    private weak var delegate: DVBThreadDelegate?
    private var index = 0
    private var timestamp: NSNumber = 0
    private var title: String!
    private var titleNode: ASTextNode!
    private var textNode: ASTextNode!
    private var mediaContainer: ASStackLayoutSpec?
    private var borderNode: ASDisplayNode!
    private var answerToPostButton: ASButtonNode!
    private var answersButton: ASButtonNode!
    private var buttonsContainer: ASStackLayoutSpec!
    private var dageAgoTimer: Timer!
    
    // MARK: - Lifecycle
    deinit {
        dageAgoTimer?.invalidate()
        dageAgoTimer = nil
    }

    @objc init(post: DVBPostViewModel, andDelegate delegate: DVBThreadDelegate?, width: CGFloat) {
        super.init()
        isOpaque = true
        self.delegate = delegate
        index = post.index
        timestamp = post.timestamp
        // Total border
        borderNode = DVBPostViewGenerator.borderNode()
        addSubnode(borderNode)
        // Post num, title, time
        title = post.title
        titleNode = DVBPostViewGenerator.titleNode()
        addSubnode(titleNode)
        // Post text
        if !(post.text.string == "") {
            textNode = DVBPostViewGenerator.textNode(withText: post.text!)
            textNode.delegate = self
            textNode.isUserInteractionEnabled = true
            addSubnode(textNode)
        }

        // Images
        if (post.thumbs?.count ?? 0) > 0 {
            mediaContainer = mediaRows(withThumbs: post.thumbs, fulls: post.pictures, width: width)
        }

        // Buttons

        // Answers buttons
        answerToPostButton = DVBPostViewGenerator.answerButton()
        answerToPostButton.addTarget(
            self,
            action: #selector(answer(_:)),
            forControlEvents: ASControlNodeEvent.touchUpInside)
        addSubnode(answerToPostButton)

        if (post.repliesCount) > 0 {
            answersButton = DVBPostViewGenerator.showAnswersButton(withCount: post.repliesCount)
            answersButton.addTarget(
                self,
                action: #selector(showAnswers(_:)),
                forControlEvents: ASControlNodeEvent.touchUpInside)
            addSubnode(answersButton)
        }
        
        let buttonsChildren = (answersButton != nil) ? [answerToPostButton, answersButton] : [answerToPostButton]
        buttonsContainer = ASStackLayoutSpec(
            direction: ASStackLayoutDirection.horizontal,
            spacing: DVBPostStyler.elementInset(),
            justifyContent: ASStackLayoutJustifyContent.spaceBetween,
            alignItems: ASStackLayoutAlignItems.stretch,
            children: buttonsChildren as! [ASLayoutElement])
        updateTitle()
    }
    
    // MARK: - View circle
    override func didEnterVisibleState() {
        super.didEnterVisibleState()
        // Update post time in 1 sec
        dageAgoTimer = Timer.scheduledTimer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(updateTitle),
            userInfo: nil,
            repeats: false)
    }

    override func didExitVisibleState() {
        super.didExitVisibleState()
        dageAgoTimer.invalidate()
        dageAgoTimer = nil
    }

    // MARK: - Layout/sizing
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let verticalStack = ASStackLayoutSpec.horizontal()
        verticalStack.direction = ASStackLayoutDirection.vertical
        verticalStack.alignItems = ASStackLayoutAlignItems.stretch
        verticalStack.spacing = DVBPostStyler.elementInset()
        verticalStack.children = mainStackChildren()
        let topInset: CGFloat = 1.5 * DVBPostStyler.elementInset()
        let insets = UIEdgeInsets(top: topInset, left: DVBPostStyler.innerInset(), bottom: topInset, right: DVBPostStyler.innerInset())
        return ASInsetLayoutSpec(
            insets: insets,
            child: verticalStack)
    }

    override func layout() {
        super.layout()
        // Manually layout the divider.
        borderNode.frame = CGRect(x: DVBPostStyler.elementInset(), y: DVBPostStyler.elementInset() / 2, width: calculatedSize.width - 2 * DVBPostStyler.elementInset(), height: calculatedSize.height - DVBPostStyler.elementInset())
    }
    
    // MARK: - Private
    func mediaRows(withThumbs thumbs: [String]?, fulls: [String]?, width: CGFloat) -> ASStackLayoutSpec? {
        var mediaNodesArray: [ASOverlayLayoutSpec] = []
        var mediaNodesArraySecond: [ASOverlayLayoutSpec] = []
        (thumbs as NSArray?)?.enumerateObjects({ [self] mediaUrl, idx, stop in

            let isVideo = ((fulls?.count ?? 0) > idx) && (fulls?[idx].contains(".webm") ?? false || fulls?[idx].contains(".mp4") ?? false)
            let media = DVBPostViewGenerator.mediaNode(withURL: mediaUrl as? String, isWebm: isVideo)
            let mediaButton = DVBMediaButtonNode(url: mediaUrl as! String)
            mediaButton.addTarget(
                self,
                action: #selector(pictureTap(_:)),
                forControlEvents: ASControlNodeEvent.touchUpInside)
            media?.delegate = self
            addSubnode(media!)
            addSubnode(mediaButton)
            let overlay = ASOverlayLayoutSpec(child: media!, overlay: mediaButton)
            let cellAndInsetWidth: CGFloat = DVBPostStyler.mediaSize() + DVBPostStyler.elementInset()
            let compare = width - 2 * DVBPostStyler.innerInset()
            if CGFloat(idx) * cellAndInsetWidth > compare {
                mediaNodesArraySecond.append(overlay)
            } else {
                mediaNodesArray.append(overlay)
            }
        })

        // Rows one below other
        var rows: [ASStackLayoutSpec] = []
        addOverlayLayout(from: mediaNodesArray, to: &rows)
        addOverlayLayout(from: mediaNodesArraySecond, to: &rows)

        return ASStackLayoutSpec(
            direction: ASStackLayoutDirection.vertical,
            spacing: DVBPostStyler.elementInset(),
            justifyContent: ASStackLayoutJustifyContent.start,
            alignItems: ASStackLayoutAlignItems.start,
            children: rows)
    }
    
    func mainStackChildren() -> [ASLayoutElement] {
        let vertStackChildren = [titleNode!] as NSMutableArray
        if (mediaContainer != nil) {
            vertStackChildren.add(mediaContainer!)
        }
        if (textNode != nil) {
            vertStackChildren.add(textNode!)
        }
        vertStackChildren.add(buttonsContainer!)
        return vertStackChildren as! [ASLayoutElement]
    }

    func addOverlayLayout(from mediaNodesArray: [ASOverlayLayoutSpec]?, to rows: inout [ASStackLayoutSpec]) {
        if (mediaNodesArray?.count ?? 0) > 0 {
            // From left to right
            rows.append(
                ASStackLayoutSpec(
                    direction: ASStackLayoutDirection.horizontal,
                    spacing: DVBPostStyler.elementInset(),
                    justifyContent: ASStackLayoutJustifyContent.start,
                    alignItems: ASStackLayoutAlignItems.start,
                    children: mediaNodesArray!))
        }
    }

    /// Recalc title, assign it and schedule timer
    @objc func updateTitle() {
        let dateAgo = DVDateFormatter.date(fromTimestamp: timestamp.intValue)
        let fullTitle = "\(title!)\(dateAgo!)"
        let textAttributes = [
            NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .subheadline),
            NSAttributedString.Key.foregroundColor: DVBPostStyler.textColor(),
            NSAttributedString.Key.backgroundColor: DVBPostStyler.postCellInsideBackgroundColor()
        ]
        let isTitleSame = titleNode.attributedText?.string == fullTitle
        if isTitleSame {
            return
        }
        titleNode.attributedText = NSAttributedString(string: fullTitle, attributes: textAttributes)
    }
    
    // MARK: - Actions
    @objc func answer(_ sender: Any?) {
        delegate?.quotePostIndex(index, andText: nil)
    }

    @objc func pictureTap(_ sender: DVBMediaButtonNode?) {
        delegate?.openGalleryWIthUrl(sender?.url ?? "")
    }

    @objc func showAnswers(_ sender: Any?) {
        delegate?.showAnswers(for: index)
    }

    // MARK: - ASNetworkImageNodeDelegate
    func imageNode(_ imageNode: ASNetworkImageNode, didLoad image: UIImage) {
        setNeedsLayout()
    }

    // MARK: - ASTextNodeDelegate
    func textNode(_ textNode: ASTextNode?, tappedLinkAttribute attribute: String?, value: Any?, at point: CGPoint, textRange: NSRange) {
        if (delegate == nil) || !(value is NSURL) {
            return
        }
        let url = value as? URL
        let urlNinja = UrlNinja.un(withUrl: url)

        
        if let isLocalPostLink = delegate?.isLinkInternal(withLink: urlNinja), isLocalPostLink {
            return
        }
        delegate?.share(withUrl: url?.absoluteString ?? "")
    }
}

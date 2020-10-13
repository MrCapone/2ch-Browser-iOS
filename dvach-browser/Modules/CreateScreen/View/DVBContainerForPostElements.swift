//
//  DVBContainerForPostElements.swift
//  dvach-browser
//
//  Created by Dmitry on 13.10.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import UIKit

private let IMAGE_CHANGE_ANIMATE_TIME: CGFloat = 0.3

class DVBContainerForPostElements: UIView, UITextViewDelegate {
    // UI elements
    @IBOutlet weak var commentTextView: UITextView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var subjectTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    
    // Values for  markup
    private var commentViewSelectedStartLocation = 0
    private var commentViewSelectedLength = 0
    private var commentViewNeedToSetCarretToPosition = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupAppearance()
        
        let scrollView = superview as? DVBCreatePostScrollView
        scrollView?.canCancelContentTouches = true
        
        commentViewSelectedStartLocation = 0
        commentViewSelectedLength = 0
    }
    
    func setupAppearance() {
        let arrayOfTextFields = [subjectTextField, nameTextField, emailTextField]
        
        let textFieldPlaceholders = [
            NSLS("FIELD_POST_THEME"),
            NSLS("FIELD_POST_NAME"),
            NSLS("FIELD_POST_EMAIL")
        ]
        
        (arrayOfTextFields as NSArray).enumerateObjects({ textField, idx, stop in
            (textField as! UITextField).attributedPlaceholder = NSAttributedString(
                string: textFieldPlaceholders[idx],
                attributes: [
                    NSAttributedString.Key.foregroundColor: UIColor.lightGray
                ])
        })
        
        // Dark theme
        if UserDefaults.standard.bool(forKey: SETTING_ENABLE_DARK_THEME) {
            backgroundColor = CELL_BACKGROUND_COLOR
            commentTextView.backgroundColor = CELL_BACKGROUND_COLOR
            
            for textField in arrayOfTextFields {
                textField?.backgroundColor = CELL_BACKGROUND_COLOR
                textField?.textColor = UIColor.white
                textField?.keyboardAppearance = .dark
            }
            
            commentTextView.keyboardAppearance = .dark
            commentTextView.textColor = UIColor.white
        }
        
        // Setup commentTextView appearance to look like textField.
        commentTextView.delegate = self
        
        // Delete textView insets.
        commentTextView.textContainer.lineFragmentPadding = 0
        commentTextView.textContainerInset = UIEdgeInsets(top: 0.0, left: 15.0, bottom: 0.0, right: 15.0)
        
        // Setup dynamic font sizes.
        
        let defaultFont = UIFont.preferredFont(forTextStyle: .subheadline)
        
        nameTextField.font = defaultFont
        subjectTextField.font = defaultFont
        emailTextField.font = defaultFont
        
        commentTextView.font = defaultFont
        
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(hideKeyBoard))
        
        addGestureRecognizer(tapGesture)
    }
    
    // MARK: - UITextViewDelegate
    func isCommentPlaceholderNow() -> Bool {
        let placeholder = NSLS("PLACEHOLDER_COMMENT_FIELD")
        
        if commentTextView.text == placeholder {
            return true
        }
        
        return false
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if isCommentPlaceholderNow() {
            textView.text = ""
            textView.textColor = UIColor.black
            
            // Dark theme
            if UserDefaults.standard.bool(forKey: SETTING_ENABLE_DARK_THEME) {
                textView.textColor = UIColor.white
            }
        }
        textView.becomeFirstResponder()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" {
            textView.text = NSLS("PLACEHOLDER_COMMENT_FIELD")
            textView.textColor = UIColor.lightGray
        }
        textView.resignFirstResponder()
    }
    
    // MARK: - Keyboard
    @objc func hideKeyBoard() {
        endEditing(true)
    }
    
    // MARK: - 2ch // MARK:up
    func textViewDidChangeSelection(_ textView: UITextView) {
        let selectedRange = commentTextView.selectedRange
        commentViewSelectedStartLocation = selectedRange.location
        commentViewSelectedLength = selectedRange.length
    }
    
    /// Wrap comment in commentTextView
    func wrapText(withSender sender: Any?, andTagToInsert tagToInsert: String?) {
        if !isCommentPlaceholderNow() {
            let locationForOpenTag = commentViewSelectedStartLocation
            let locationForCloseTag = locationForOpenTag + commentViewSelectedLength
            
            let tagToinsertBefore = "[\(tagToInsert ?? "")]"
            let tagToinsertAfter = "[/\(tagToInsert ?? "")]"
            
            let mutableCommentString = NSMutableString(string: commentTextView.text)
            
            // Insert close tag first because otherwise its position will change and we'll need to recalculate it
            mutableCommentString.insert(tagToinsertAfter, at: locationForCloseTag)
            mutableCommentString.insert(tagToinsertBefore, at: locationForOpenTag)
            
            let newCommentString = mutableCommentString as String
            
            commentViewNeedToSetCarretToPosition = commentViewSelectedStartLocation + tagToinsertBefore.count
            
            commentTextView.text = newCommentString
            
            commentTextView.selectedRange = NSRange(location: commentViewNeedToSetCarretToPosition, length: 0)
        }
    }
    
    @IBAction func insertBoldTagAction(_ sender: Any) {
        wrapText(withSender: sender, andTagToInsert: "b")
    }
    
    @IBAction func insertItalicTagAction(_ sender: Any) {
        wrapText(withSender: sender, andTagToInsert: "i")
    }
    
    @IBAction func insertSpoilerTagAction(_ sender: Any) {
        wrapText(withSender: sender, andTagToInsert: "spoiler")
    }
    
    @IBAction func insertUnderlineTagAction(_ sender: Any) {
        wrapText(withSender: sender, andTagToInsert: "u")
    }
    
    @IBAction func insertStrikeTagAction(_ sender: Any) {
        wrapText(withSender: sender, andTagToInsert: "s")
    }
    
    // MARK: - Upload/Delete button Animation
    func changeUploadView(toDelete view: UIView?, andsetImage image: UIImage?, for imageView: UIImageView?) {
        layoutIfNeeded()
        // animate plus
        UIView.animate(
            withDuration: TimeInterval(IMAGE_CHANGE_ANIMATE_TIME),
            delay: 0,
            options: .curveEaseOut,
            animations: { [self] in
                autoresizesSubviews = false
                if let transform = view?.transform.rotated(by: .pi / 4) {
                    view?.transform = transform
                }
                view?.backgroundColor = UIColor.red
            })
        
        // animate image change
        if let imageView = imageView {
            UIView.transition(
                with: imageView,
                duration: TimeInterval(IMAGE_CHANGE_ANIMATE_TIME),
                options: .transitionCrossDissolve,
                animations: {
                    imageView.image = image
                })
        }
    }
    
    func changeDeleteView(toUploadView view: UIView?, andClear imageView: UIImageView?) {
        layoutIfNeeded()
        // animate plus
        UIView.animate(
            withDuration: TimeInterval(IMAGE_CHANGE_ANIMATE_TIME),
            delay: 0,
            options: .curveEaseOut,
            animations: { [self] in
                autoresizesSubviews = false
                if let transform = view?.transform.rotated(by: -.pi / 4) {
                    view?.transform = transform
                }
                view?.backgroundColor = UIColor.clear
            })
        // animate image change
        if let imageView = imageView {
            UIView.transition(
                with: imageView,
                duration: TimeInterval(IMAGE_CHANGE_ANIMATE_TIME),
                options: .transitionCrossDissolve,
                animations: {
                    imageView.image = nil
                })
        }
    }
}

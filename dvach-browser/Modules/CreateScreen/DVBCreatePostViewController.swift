//
//  DVBCreatePostViewController.swift
//  dvach-browser
//
//  Created by Dmitry on 17.09.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import UIKit
import AFNetworking
import Mantle

@objc class DVBCreatePostViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIScrollViewDelegate, DVBDvachCaptchaViewControllerDelegate {
    weak var createPostViewControllerDelegate: DVBCreatePostViewControllerDelegate?
    /// Board's shortcode
    var boardCode: String?
    /// OP number
    var threadNum: String?

    private var networking: DVBNetworking?
    private var sharedComment: DVBComment!
    /// Captcha
    private var captchaValue: String?
    /// Usercode for posting without captcha
    private var usercode: String?
    // Mutable array of UIImage objects we need to attach to post
    private var imagesToUpload: [UIImage]?
    private var createdThreadNum: String?
    private var postSuccessfull = false
    // UI elements
    @objc @IBOutlet weak var containerForPostElementsView: DVBContainerForPostElements!
    @objc @IBOutlet weak var createPostScrollView: UIScrollView!
    @objc @IBOutlet weak var sendPostButton: UIBarButtonItem!
    @objc @IBOutlet weak var closeButton: UIBarButtonItem!
    // Tempopary storage for add/remove picture button we just pressed
    var addPictureButton: UIButton?
    // New captcha
    var captchaId: String?
    var captchaCode: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareViewController()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveCommentForLater()
    }

    /// All View Controller tuning
    func prepareViewController() {
        darkThemeHandler()
        networking = DVBNetworking()

        closeButton.title = NSLS("BUTTON_CLOSE")
        sendPostButton.title = NSLS("BUTTON_SEND")

        // If threadNum is 0 - then we creating new thread and need to set View Controller's Title accordingly.
        let isThreadNumZero = threadNum == "0"
        if isThreadNumZero {
            title = NSLS("TITLE_NEW_THREAD")
        } else {
            title = NSLS("TITLE_NEW_POST")
        }
        // Set comment field text from sharedComment.
        sharedComment = DVBComment.sharedComment()
        let commentText = sharedComment.comment

        if commentText.count > 0 {
            containerForPostElementsView.commentTextView.text = commentText
        } else {
            containerForPostElementsView.commentTextView.text = NSLS("PLACEHOLDER_COMMENT_FIELD")
            containerForPostElementsView.commentTextView.textColor = UIColor.lightGray
        }

        // Prepare usercode (aka passcode) from default.
        usercode = UserDefaults.standard.string(forKey: USERCODE)

        imagesToUpload = []
    }

    func darkThemeHandler() {
        if UserDefaults.standard.bool(forKey: SETTING_ENABLE_DARK_THEME) {
            navigationController?.navigationBar.barStyle = .blackTranslucent
            view.backgroundColor = CELL_BACKGROUND_COLOR
            createPostScrollView.backgroundColor = CELL_BACKGROUND_COLOR
        }
    }
    
    // MARK: - Captcha
    func showDvachCaptchaController() {
        let captchaVC = DVBDvachCaptchaViewController(nibName: nil, bundle: nil)
        captchaVC.dvachCaptchaViewControllerDelegate = self
        if !(threadNum == "0") {
            captchaVC.threadNum = threadNum
        }
        navigationController?.pushViewController(
            captchaVC,
            animated: true)
    }

    // MARK: - Actions

    /// Button action to fire post sending method
    @objc @IBAction func makePostAction(_ sender: Any) {
        // Clear any prompt messages
        navigationItem.prompt = nil

        // Check usercode - send post if needed
        let isUsercodeNotEmpty = !(usercode == "")

        if UserDefaults.standard.bool(forKey: SETTING_FORCE_CAPTCHA) {
            showDvachCaptchaController()
            return
        }

        if isUsercodeNotEmpty && !(threadNum == "0") {
            sendPostWithoutCaptcha(true, andAppResponseId: nil)
        } else {
            if threadNum == "0" {
                showDvachCaptchaController()
                return
            } else {
                networking?.tryApCaptcha(withCompletion: { appResponseId in
                    if appResponseId == nil {
                        // Can't get APCaptcha, show regular captcha
                        self.showDvachCaptchaController()
                        return
                    }
                    self.sendPostWithoutCaptcha(true, andAppResponseId: appResponseId)
                })
            }
        }
    }

    @objc @IBAction func pickPhotoAction(_ sender: UIButton) {
        addPictureButton = sender

        let imageViewToCheckImage = imageViewToShowUploadingImage(withArrayOfViews: addPictureButton?.superview?.subviews)

        if imageViewToCheckImage?.image != nil {
            deletePicture()
        } else {
            pickPicture()
        }
    }
    
    @objc @IBAction func cancelPostAction(_ sender: Any) {
        // Dismiss keyboard before dismissing View Controller.
        view.endEditing(true)
        // Fire actual dismissing method.
        goBackToThread()
    }
    
    func sendPostWithoutCaptcha(_ noCaptcha: Bool, andAppResponseId appResponseId: String?) {
        // Turn off POST button
        sendPostButton.isEnabled = false
        
        // Get values from fields
        let name = containerForPostElementsView.nameTextField.text
        let subject = containerForPostElementsView.subjectTextField.text
        let email = containerForPostElementsView.emailTextField.text
        let comment = containerForPostElementsView.commentTextView.text
        let imagesToUpload = self.imagesToUpload
        
        var captchaParameters: [String : Any] = [:]
        
        // Check server response and our app response
        if let appResponseId = appResponseId, let appResponse = DVBCaptchaHelper.appResponse(from: appResponseId) {
            captchaParameters = [
                "captcha_type": "app",
                "app_response_id": appResponseId,
                "app_response": appResponse
            ]
        } else if let captchaId = captchaId, let captchaCode = captchaCode {
            // Check manually entered captcha
            captchaParameters = [
                "2chaptcha_id": captchaId,
                "2chaptcha_value": captchaCode
            ]
        } else {
            // No right app response from server, and entered manual captcha yet
            showDvachCaptchaController()
        }
        
        networking?.postMessage(withBoard: boardCode, andThreadnum: threadNum, andName: name, andEmail: email, andSubject: subject, andComment: comment, andUsercode: usercode, andImagesToUpload: imagesToUpload, andCaptchaParameters: captchaParameters, andCompletion: { messagePostServerAnswer in
            // Set Navigation prompt accordingly to server answer.
            let serverStatusMessage = messagePostServerAnswer?.statusMessage
            self.navigationItem.prompt = serverStatusMessage
            
            let isPostWasSuccessful = messagePostServerAnswer?.success ?? false
            
            if isPostWasSuccessful {
                let threadToRedirectTo = messagePostServerAnswer?.threadToRedirectTo
                let isThreadToRedirectToNotEmpty = !(threadToRedirectTo == "")
                
                if threadToRedirectTo != "" && isThreadToRedirectToNotEmpty {
                    self.createdThreadNum = threadToRedirectTo
                }
                
                // Clear comment text and saved comment if post was successfull.
                self.containerForPostElementsView.commentTextView.text = ""
                self.sharedComment.comment = ""
                
                // Dismiss View Controller if post was successfull.
                self.perform(
                    #selector(self.goBackToThread),
                    with: nil,
                    afterDelay: 1.0)
            } else {
                // Enable Post button back.
                self.sendPostButton.isEnabled = true
            }
        })
    }
    
    // MARK: - Image(s) picking

    /// Pick picture from gallery
    func pickPicture() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        present(
            imagePicker,
            animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true) { [self] in
            let imageReferenceUrl = (info[UIImagePickerController.InfoKey.referenceURL] as? URL)?.absoluteString ?? ""
            let imageReferenceUrlArray = imageReferenceUrl.components(separatedBy: "ext=")
            let imageExtention = imageReferenceUrlArray.last

            let imageToLoad = info[UIImagePickerController.InfoKey.originalImage] as? UIImage

            // Set image extention to prepare image the right way before uplaoding
            imageToLoad?.imageExtention = imageExtention?.lowercased()

            let imageViewToShowIn = self.imageViewToShowUploadingImage(withArrayOfViews: self.addPictureButton?.superview?.subviews)

            if let imageToLoad = imageToLoad {
                self.imagesToUpload?.append(imageToLoad)
            }

            let plusContainerView = self.viewPlusContainer(withArrayOfViews: self.addPictureButton?.superview?.subviews)

            self.containerForPostElementsView.changeUploadView(toDelete: plusContainerView, andsetImage: imageToLoad, for: imageViewToShowIn)

            self.addPictureButton = nil
        }
    }
    
    /// Delete all pointers/refs to photo.
    func deletePicture() {
        let imageViewToDeleteIn = imageViewToShowUploadingImage(withArrayOfViews: addPictureButton?.superview?.subviews)

        let imageToDeleteFromEverywhere = imageViewToDeleteIn?.image

        if let imageToDeleteFromEverywhere = imageToDeleteFromEverywhere {
            guard let isImagePresentedInArray = imagesToUpload?.contains(imageToDeleteFromEverywhere) else { return }

            if isImagePresentedInArray {
                imagesToUpload?.removeAll { $0 as AnyObject === imageToDeleteFromEverywhere as AnyObject }
            }
        }

        let plusContainerView = viewPlusContainer(withArrayOfViews: addPictureButton?.superview?.subviews)

        containerForPostElementsView.changeDeleteView(toUploadView: plusContainerView, andClear: imageViewToDeleteIn)
        addPictureButton = nil
    }

    /// Find image view to show image to upload in
    func imageViewToShowUploadingImage(withArrayOfViews arrayOfViews: [AnyHashable]?) -> DVBPictureToSendPreviewImageView? {
        for view in arrayOfViews ?? [] {
            guard let view = view as? UIView else {
                continue
            }
            let isItImageView = type(of: view) === DVBPictureToSendPreviewImageView.self
            if isItImageView {
                let imageView = view as? DVBPictureToSendPreviewImageView

                return imageView
            }
        }

        return nil
    }
    
    /// Find image view's with PLUS icon container
    func viewPlusContainer(withArrayOfViews arrayOfViews: [AnyHashable]?) -> UIView? {
        for view in arrayOfViews ?? [] {
            guard let view = view as? UIView else {
                continue
            }
            let isItImageView = type(of: view) === DVBAddPhotoIconImageViewContainer.self
            if isItImageView {

                return view
            }
        }

        return nil
    }

    // MARK: - Navigation
    @objc func goBackToThread() {
        navigationItem.prompt = nil
        let isThreadNumZero = threadNum == "0"

        if isThreadNumZero {
            if let createdThreadNum = createdThreadNum {
                weak var strongDelegate = createPostViewControllerDelegate
                if strongDelegate?.responds(to: #selector(DVBCreatePostViewControllerDelegate.openThred(withCreatedThread:))) ?? false {
                    strongDelegate?.openThred(withCreatedThread: createdThreadNum)
                }
            }
        } else {
            weak var strongDelegate = createPostViewControllerDelegate
            // Update thread in any case (was post successfull or not)
            if strongDelegate?.responds(to: #selector(DVBCreatePostViewControllerDelegate.updateThreadAfterPosting)) ?? false {
                strongDelegate?.updateThreadAfterPosting()
            }
        }
        dismiss(animated: true)
    }
    
    /// Write comment text to singleton
    func saveCommentForLater() {
        // Save comment for later if it is not a placeholder.
        if !(containerForPostElementsView.commentTextView.text == NSLS("PLACEHOLDER_COMMENT_FIELD")) {
            sharedComment.comment = containerForPostElementsView.commentTextView.text
        }
    }

    // MARK: - UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if UI_USER_INTERFACE_IDIOM() == .pad {
        } else {
            view.endEditing(true)
        }
    }

    // MARK: - DVBDvachCaptchaViewControllerDelegate
    func captchaBeenChecked(withCode code: String, andWithId captchaId: String) {
        self.captchaId = captchaId
        captchaCode = code
        sendPostWithoutCaptcha(false, andAppResponseId: nil)
    }
}

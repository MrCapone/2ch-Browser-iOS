//
//  DVBDvachCaptchaViewController.swift
//  dvach-browser
//
//  Created by Dmitry Lukianov on 09.10.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import UIKit
import AFNetworking
import QuartzCore

@objc protocol DVBDvachCaptchaViewControllerDelegate: NSObjectProtocol {
    @objc func captchaBeenChecked(withCode code: String, andWithId captchaId: String)
}

class DVBDvachCaptchaViewController: UIViewController {
    weak var dvachCaptchaViewControllerDelegate: DVBDvachCaptchaViewControllerDelegate?
    var threadNum: String?
    
    private var captchaManager: DVBCaptchaManager?
    private var captchaId: String?
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var textField: UITextField!
    @IBOutlet private weak var reloadButton: UIButton!
    @IBOutlet private weak var submitButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        captchaManager = DVBCaptchaManager()
        reloadButton.setTitle("", for: .normal)
        
        if UserDefaults.standard.bool(forKey: SETTING_ENABLE_DARK_THEME) {
            view.backgroundColor = CELL_BACKGROUND_COLOR
            textField.backgroundColor = CELL_BACKGROUND_COLOR
            textField.textColor = UIColor.white
            textField.keyboardAppearance = .dark
            
            textField.layer.cornerRadius = 8.0
            textField.layer.masksToBounds = true
            textField.layer.borderColor = UIColor.lightGray.cgColor
            textField.layer.borderWidth = 1.0
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        textField.becomeFirstResponder()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        loadImage()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        textField.resignFirstResponder()
    }
    
    func loadImage() {
        imageView.image = nil
        textField.text = ""
        captchaManager?.getCaptchaImageUrl(
            threadNum,
            andCompletion: { [self] captchaImageUrl, captchaId in
                self.captchaId = captchaId
                var request: URLRequest? = nil
                if let url = URL(string: captchaImageUrl ?? "") {
                    request = URLRequest(url: url)
                }
                if let request = request {
                    imageView.setImageWith(
                        request,
                        placeholderImage: nil,
                        success: { [self] request, response, image in
                            if UserDefaults.standard.bool(forKey: SETTING_ENABLE_DARK_THEME) {
                                imageView.image = inverseColor(image)
                            } else {
                                imageView.image = image
                            }
                        },
                        failure: nil)
                }
            })
    }
    
    // MARK: - Private image stuff
    func inverseColor(_ image: UIImage?) -> UIImage? {
        var coreImage: CIImage? = nil
        if let CGImage = image?.cgImage {
            coreImage = CIImage(cgImage: CGImage)
        }
        let filter = CIFilter(name: "CIColorInvert")
        filter?.setValue(coreImage, forKey: kCIInputImageKey)
        var result = filter?.value(forKey: kCIOutputImageKey) as? CIImage
        
        let filterBrightness = CIFilter(name: "CIColorControls")
        filterBrightness?.setValue(result, forKey: kCIInputImageKey)
        filterBrightness?.setValue(NSNumber(value: 0.017), forKey: kCIInputBrightnessKey)
        result = filterBrightness?.value(forKey: kCIOutputImageKey) as? CIImage
        
        if let result = result {
            return UIImage(ciImage: result)
        }
        return nil
    }
    
    func submitCaptcha() {
        navigationController?.popViewController(animated: true)
        if let dvachCaptchaViewControllerDelegate = dvachCaptchaViewControllerDelegate, dvachCaptchaViewControllerDelegate.responds(to: #selector(DVBDvachCaptchaViewControllerDelegate.captchaBeenChecked(withCode:andWithId:))) {
            guard let code = textField.text, !code.isEmpty, let captchaId = captchaId else {
                return
            }
            dvachCaptchaViewControllerDelegate.captchaBeenChecked(
                withCode: code,
                andWithId: captchaId)
        }
    }
    
    // MARK: - Actions
    @IBAction func reloadButtonAction(_ sender: Any) {
        loadImage()
    }
    
    @IBAction func submitButtonAction(_ sender: Any) {
        submitCaptcha()
    }
}

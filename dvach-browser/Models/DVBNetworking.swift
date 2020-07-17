//
//  DVBNetworking.swift
//  dvach-browser
//
//  Created by Dmitry on 17.07.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import Foundation
import UIKit
import AFNetworking

@objc class DVBNetworking: NSObject {
    private let NO_CAPTCHA_ANSWER_CODE = "disabled"
    
    // MARK: - Boards list
    
    @objc func getBoardsFromNetwork(withCompletion completion: @escaping ([String : Any]?) -> Void) {
        let manager = AFHTTPSessionManager()
        manager.responseSerializer.acceptableContentTypes = Set<String>(["text/html", "application/json"])
        manager.get(DVBUrls.boardsList, parameters: nil, headers: nil, progress: nil, success: { task, responseObject in
            completion(responseObject as? [String : Any])
        }, failure: { task, error in
            print("error: \(error)")
            completion(nil)
        })
    }
    
    // MARK: - Single Board
    
    /// Get threads for single page of single board
    func getThreadsWithBoard(_ board: String, andPage page: UInt, andCompletion completion: @escaping ([String : Any]?, Error?) -> Void) {
        var pageStringValue: String
        
        if page == 0 {
            pageStringValue = "index"
        } else {
            pageStringValue = String(page)
        }
        let requestAddress = "\(DVBUrls.base)/\(board)/\(pageStringValue).json"
        let manager = AFHTTPSessionManager()
        manager.responseSerializer.acceptableContentTypes = Set<String>(["application/json"])
        
        manager.get(requestAddress, parameters: nil, headers: nil, progress: nil, success: { task, responseObject in
            completion(responseObject as? [String : Any], nil)
        }, failure: { task, error in
            let finalError = self.updateError(
                with: task,
                andError: error)
            if let finalError = finalError {
                print("error while threads: \(finalError)")
            }
            completion(nil, finalError!)
        })
    }
    
    // MARK: - Single thread
    
    /// Get posts for single thread
    @objc func getPostsWithBoard(_ board: String, andThread threadNum: String, andPostNum postNum: String?, andCompletion completion: @escaping ([String: Any]?) -> Void) {
        // building URL for getting JSON-thread-answer from multiple strings
        var requestAddress = "\(DVBUrls.base)/\(board)/res/\(threadNum).json"
        if let postNum = postNum {
            requestAddress = "\(DVBUrls.base)/makaba/mobile.fcgi?task=get_thread&board=\(board)&thread=\(threadNum)&num=\(postNum)"
        }
        
        let manager = AFHTTPSessionManager()
        manager.responseSerializer.acceptableContentTypes = Set<String>(["application/json"])
        
        manager.get(requestAddress, parameters: nil, headers: nil, progress: nil, success: { task, responseObject in
            completion(responseObject as? [String : Any])
        }, failure: { task, error in
            print("error: \(error)")
            completion(nil)
        })
    }
    
    // MARK: - Passcode
    
    /// Get usercode cookie in exchange to user's passcode
    func getUserCode(withPasscode passcode: String, andCompletion completion: @escaping (String?) -> Void) {
        let requestAddress = DVBUrls.getUsercode
        
        let manager = AFHTTPSessionManager()
        manager.responseSerializer.acceptableContentTypes = Set<String>(["text/html"])
        
        let params = [
            "task": "auth",
            "usercode": passcode
        ]
        
        manager.post(requestAddress, parameters: params, headers: nil, progress: nil, success: { task, responseObject in
            let usercode = self.getUsercodeFromCookies()
            completion(usercode)
        }, failure: { task, error in
            // print(error);
            // error here is OK we just need to extract usercode from cookies
            let usercode = self.getUsercodeFromCookies()
            completion(usercode)
        })
    }
    
    /// Return usercode from cookie or nil if there is no usercode in cookies
    func getUsercodeFromCookies() -> String? {
        let cookiesArray = HTTPCookieStorage.shared.cookies
        for cookie in cookiesArray ?? [] {
            let isThisUsercodeCookie = cookie.name == "usercode_nocaptcha"
            if isThisUsercodeCookie {
                let usercode = cookie.value
                print("usercode success")
                return usercode
            }
        }
        return nil
    }
    
    // MARK: - Posting
    
    /// Post user message to server and return server answer
    @objc func postMessage(withBoard board: String?, andThreadnum threadNum: String?, andName name: String?, andEmail email: String?, andSubject subject: String?, andComment comment: String?, andUsercode usercode: String?, andImagesToUpload imagesToUpload: [UIImage]?, andCaptchaParameters captchaParameters: [String : Any]?, andCompletion completion: @escaping (DVBMessagePostServerAnswer?) -> Void) {
        // Prevent crashing
        guard let board = board, let threadNum = threadNum else {
            return
        }
        
        let manager = AFHTTPSessionManager()
        manager.responseSerializer = AFHTTPResponseSerializer()
        
        let address = "\(DVBUrls.base)/\("makaba/posting.fcgi")"
        
        var params: [String: Any] = [
            "task": "post",
            "json": "1",
            "board": board,
            "thread": threadNum
        ]
        
        // if new captcha
        if let captchaParameters = captchaParameters  {
            for (k, v) in captchaParameters { params[k] = v }
        } else {
            // Check userCode
            let isUsercodeNotEmpty = !(usercode == "")
            if isUsercodeNotEmpty {
                // If usercode presented then use as part of the message
                // print("usercode way: \(usercode));
                params["usercode"] = usercode
            }
        }
        
        manager.responseSerializer.acceptableContentTypes = Set<String>(["application/json"])
        
        manager.post(address, parameters: params, headers: nil, constructingBodyWith: { formData in
            ///  Added comment field this way because makaba don't handle it right otherwise
            ///  and name
            ///  and subject
            ///  and e-mail
            var commentToSend = comment
            if comment == NSLS("PLACEHOLDER_COMMENT_FIELD") {
                commentToSend = ""
            }
            formData.appendPart(
                withForm: commentToSend!.data(using: .utf8)!,
                name: "comment")
            formData.appendPart(
                withForm: name!.data(using: .utf8)!,
                name: "name")
            formData.appendPart(
                withForm: subject!.data(using: .utf8)!,
                name: "subject")
            formData.appendPart(
                withForm: email!.data(using: .utf8)!,
                name: "email")
            
            // Check if we have images to upload
            if let imagesToUpload = imagesToUpload {
                var imageIndex = 1
                for imageToLoad in imagesToUpload {
                    var fileData: Data?
                    let imageName = String(format: "image%ld", UInt(imageIndex))
                    let imageFilename = "image.\(imageToLoad.imageExtention!)"
                    var imageMimeType: String?
                    let isThisJpegImage = imageToLoad.imageExtention == "jpg"
                    
                    // Mime type for jpeg differs from its file extention string
                    if isThisJpegImage {
                        imageMimeType = "image/jpeg"
                        fileData = imageToLoad.jpegData(compressionQuality: 1.0)
                    } else {
                        imageMimeType = "image/\(imageToLoad.imageExtention!)"
                        fileData = imageToLoad.pngData()
                    }
                    formData.appendPart(
                        withFileData: fileData!,
                        name: imageName,
                        fileName: imageFilename,
                        mimeType: imageMimeType!)
                    imageIndex += 1
                }
            }
        }, progress: nil, success: { task, responseObject in
            guard let  responseData = responseObject as? Data else {
                return
            }
            let responseString = String(
                data: responseData,
                encoding: .utf8)!
            print("Success: \(responseString)")
            
            var responseDictionary: [AnyHashable : Any]? = nil
            do {
                responseDictionary = try JSONSerialization.jsonObject(
                    with: responseData,
                    options: []) as? [AnyHashable : Any]
            } catch {
            }
            ///  Status field from response.
            let status = responseDictionary?["Status"] as? String
            ///  Reason field from response.
            let reason = responseDictionary?["Reason"] as? String
            
            ///  Compare answer to predefined values;
            let isOKanswer: Bool = (status == "OK")
            let isRedirectAnswer: Bool = (status == "Redirect")
            
            if isOKanswer || isRedirectAnswer {
                // If answer is good - make preparations in current ViewController
                let successTitle = NSLS("POST_STATUS_SUCCESS")
                
                let postNum = responseDictionary!["Num"] as! String
                
                var messagePostServerAnswer = DVBMessagePostServerAnswer(
                    success: true,
                    andStatusMessage: successTitle,
                    andNum: postNum,
                    andThreadToRedirectTo: nil)
                
                if isRedirectAnswer {
                    let threadNumToRedirect = responseDictionary!["Target"] as! String
                    
                    if !threadNumToRedirect.isEmpty {
                        messagePostServerAnswer = DVBMessagePostServerAnswer(
                            success: true,
                            andStatusMessage: successTitle,
                            andNum: nil,
                            andThreadToRedirectTo: threadNumToRedirect)
                    }
                }
                completion(messagePostServerAnswer)
            } else {
                
                // If post wasn't successful. Change prompt to error reason.
                let messagePostServerAnswer = DVBMessagePostServerAnswer(
                    success: false,
                    andStatusMessage: reason,
                    andNum: nil,
                    andThreadToRedirectTo: nil)
                completion(messagePostServerAnswer)
            }
        }, failure: { task, error in
            print("Error: \(error)")
            
            let cancelTitle = NSLS("ERROR")
            let messagePostServerAnswer = DVBMessagePostServerAnswer(
                success: false,
                andStatusMessage: cancelTitle,
                andNum: nil,
                andThreadToRedirectTo: nil)
            completion(messagePostServerAnswer)
        })
    }
    
    // MARK: - Thread reporting
    
    /// Report thread
    @objc func reportThread(withBoardCode board: String, andThread thread: String, andComment comment: String?) {
        let reportManager = AFHTTPSessionManager()
        reportManager.responseSerializer = AFHTTPResponseSerializer()
        reportManager.responseSerializer.acceptableContentTypes = Set<String>(["text/html"])
        
        reportManager.post(
            DVBUrls.reportThread,
            parameters: nil,
            headers: nil,
            progress: nil,
            success: { task, responseObject in
                print("Report sent")
        }, failure: { task, error in
                print("Error: \(error)")
        })
    }
    
    // MARK: - single post
    
    /// After posting we trying to get our new post and parse it from the scratch
    func getPostWithBoardCode(_ board: String, andThread thread: String, andPostNum postNum: String, andCompletion completion: @escaping ([[String: Any]]?) -> Void) {
        let address = "\(DVBUrls.base)/\("makaba/mobile.fcgi")"
        
        let params = [
            "task": "get_thread",
            "board": board,
            "thread": thread,
            "num": postNum
        ]
        
        let manager = AFHTTPSessionManager()
        manager.responseSerializer.acceptableContentTypes = Set<String>(["text/html", "application/json"])
        
        manager.get(
            address,
            parameters: params,
            headers: nil,
            progress: nil,
            success: { task, responseObject in
                completion(responseObject as? [[String : Any]])
        }, failure: { task, error in
                print("error while getting new post in thread: \(error.localizedDescription)")
                completion(nil)
        })
    }
    
    /// Check if we can post without captcha
    func canPostWithoutCaptcha(_ completion: @escaping (Bool) -> Void) {
        let address = "\(DVBUrls.base)/\("makaba/captcha.fcgi?type=2chaptcha&action=thread")"
        let manager = AFHTTPSessionManager()
        manager.responseSerializer.acceptableContentTypes = Set<String>(["text/plain"])
        
        manager.get(
            address,
            parameters: nil,
            headers: nil,
            progress: nil,
            success: { task, responseObject in
                completion(false)
        }, failure: { task, error in
                if (error as NSError?)?.userInfo[self.NO_CAPTCHA_ANSWER_CODE] == nil {
                    completion(false)
                } else {
                    completion(true)
                }
        })
    }
    
    @objc func getCaptchaImageUrl(_ threadNum: String?, andCompletion completion: @escaping (String?, String?) -> Void) {
        var address = "\(DVBUrls.base)/\("api/captcha/2chaptcha/id")"
        if let threadNum = threadNum {
            address = "\(address)?thread=\(threadNum)"
        }
        let manager = AFHTTPSessionManager()
        
        manager.get(
            address,
            parameters: nil,
            headers: nil,
            progress: nil,
            success: { task, responseObject in
                if let responseObject = responseObject as? [String: Any], let captchaId = responseObject["id"] as? String {
                    let captchaImageAddress = "\(DVBUrls.base)/\("api/captcha/2chaptcha/image/")\(captchaId)"
                    completion(captchaImageAddress, captchaId)
                } else {
                    completion(nil, nil)
                }
        }, failure: { task, error in
                completion(nil, nil)
        })
    }
    
    func userAgent() -> String? {
        let manager = AFHTTPSessionManager()
        let userAgent = manager.requestSerializer.value(forHTTPHeaderField: NETWORK_HEADER_USERAGENT_KEY)
        
        return userAgent
    }
    
    /// AP captcha
    @objc func tryApCaptcha(withCompletion completion: @escaping (String?) -> Void) {
        let address = "\(DVBUrls.base)/\("api/captcha/app/id/")\(AP_CAPTCHA_PUBLIC_KEY)"
        AFHTTPSessionManager().get(
            address,
            parameters: nil,
            headers: nil,
            progress: nil,
            success: { operation, responseObject in
                if let responseObject = responseObject as? [String: Any], let appResponseId = responseObject["id"] as? String {
                    completion(appResponseId)
                } else {
                    completion(nil)
                }
        }, failure: { operation, error in
                completion(nil)
        })
    }
    
    // MARK: - Error handling
    private func updateError(with task: URLSessionDataTask?, andError error: Error?) -> Error? {
        let httpResponse = task?.response as? HTTPURLResponse
        if httpResponse?.responds(to: #selector(getter: HTTPURLResponse.allHeaderFields)) ?? false {
            let dictionary = httpResponse?.allHeaderFields as? [String: String]
            
            let isServerHeaderCloudflareOne = (dictionary?["Server"] as NSString?)?.range(of: "cloudflare").location != NSNotFound
            
            // Two checks:
            // Have refresh header and it's empty
            // Or have cloudflare ref in Server header
            if (dictionary?[ERROR_OPERATION_HEADER_KEY_REFRESH] != nil && !(dictionary?[ERROR_OPERATION_HEADER_KEY_REFRESH] == "")) || isServerHeaderCloudflareOne {
                let refreshUrl = dictionary?[ERROR_OPERATION_HEADER_KEY_REFRESH]
                let range = (refreshUrl as NSString?)?.range(of: ERROR_OPERATION_REFRESH_VALUE_SEPARATOR)
                if range?.location != NSNotFound {
                    var secondpartOfUrl: String? = nil
                    if let range = range {
                        secondpartOfUrl = (refreshUrl as NSString?)?.substring(from: NSMaxRange(range))
                    }
                    let fullUrlToReturn = "\(DVBUrls.base)/\(secondpartOfUrl ?? "")"
                    
                    var userInfo = (error as NSError?)?.userInfo
                    
                    var newErrorDictionary = [
                        ERROR_USERINFO_KEY_IS_DDOS_PROTECTION: NSNumber(value: true),
                        ERROR_USERINFO_KEY_URL_TO_CHECK_IN_BROWSER: fullUrlToReturn
                        ] as [String : Any]
                    
                    for (k, v) in userInfo! { newErrorDictionary[k] = v }
                    userInfo = newErrorDictionary
                    
                    
                    
                    let errorToReturn = NSError(domain: ERROR_DOMAIN_APP, code: ERROR_CODE_DDOS_CHECK, userInfo: userInfo)
                    
                    return errorToReturn
                }
            }
        }
        
        return nil
    }
    
}

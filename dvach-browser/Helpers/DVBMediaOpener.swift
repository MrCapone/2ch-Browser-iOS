//
//  DVBMediaOpener.swift
//  dvach-browser
//
//  Created by Dmitry on 14.08.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import Foundation
import UIKit

@objc class DVBMediaOpener: NSObject {
    private weak var viewController: UIViewController?
    
    convenience override init() {
        NSException(name: NSExceptionName("Not enough info"), reason: "Use +[DVBMediaOpener initWith...]", userInfo: nil).raise()
        fatalError()
    }

    @objc  init(viewController: UIViewController?) {
        self.viewController = viewController
        
        super.init()
    }

    @objc  func openMedia(withUrlString fullUrlString: String, andThumbImagesArray thumbImagesArray: [AnyHashable], andFullImagesArray fullImagesArray: [AnyHashable]) {
        if fullUrlString == "" {
            // Empty link case
            return
        }
        // if contains .webm
        if fullUrlString.contains(".webm") {
            let url = URL(string: fullUrlString)!
            openInternalWebm(with: url)
            // if contains .mp4
        } else if fullUrlString.contains(".mp4") {
            let url = URL(string: fullUrlString)!
            openAVPlayer(with: url)
        } else {
            createAndPushGallery(
                withUrlString: fullUrlString,
                andThumbImagesArray: thumbImagesArray,
                andFullImagesArray: fullImagesArray)
        }
    }
    
    func createAndPushGallery(withUrlString urlString: String, andThumbImagesArray thumbImagesArray: [AnyHashable], andFullImagesArray fullImagesArray: [AnyHashable]) {
        let indexForImageShowing = fullImagesArray.firstIndex(of: urlString)!

        if indexForImageShowing < (fullImagesArray.count) {

            let galleryBrowser = DVBBrowserViewControllerBuilder(delegate: nil)!

            galleryBrowser.prepare(
                with: UInt(indexForImageShowing),
                andThumbImagesArray: thumbImagesArray,
                andFullImagesArray: fullImagesArray)

            viewController?.navigationController?.definesPresentationContext = true
            galleryBrowser.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            viewController?.navigationController?.present(
                galleryBrowser,
                animated: true)
        }
    }

    // MARK: - Webm
    func openInternalWebm(with url: URL) {
        DVBRouter.openWebm(from: viewController, url: url)
    }

    // MARK: - MP4
    func openAVPlayer(with url: URL) {
        DVBRouter.openAVPlayer(from: viewController, url: url)
    }

    /// Clear prompt from any status / error messages.
    func clearPrompt() {
        viewController?.navigationItem.prompt = nil
    }
}

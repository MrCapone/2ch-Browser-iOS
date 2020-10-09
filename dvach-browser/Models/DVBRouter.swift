//
//  DVBRouter.swift
//  dvach-browser
//
//  Created by Dmitry on 28.07.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import AVFoundation
import AVKit
import Foundation
import UIKit

@objc class DVBRouter: NSObject {
    @objc class func pushBoard(from viewController: UIViewController?, boardCode: String, pages: Int) {
        let boardViewController = DVBAsyncBoardViewController.init(boardCode: boardCode, pages: pages)
        if let boardViewController = boardViewController {
            viewController?.navigationController?.pushViewController(
                boardViewController,
                animated: true)
        }
    }

    /// Full thread
    @objc class func pushThread(from viewController: UIViewController?, board: String, thread: String, subject: String?, comment: String?) {
        let vcSubject = DVBThread.threadControllerTitle(
            fromTitle: subject,
            andNum: thread,
            andComment: comment)
        let vc = DVBAsyncThreadViewController(boardCode: board, andThreadNumber: thread, andThreadSubject: vcSubject)
        viewController?.navigationController?.pushViewController(
            vc,
            animated: true)
    }

    /// Answers only
    @objc class func pushAnswers(from viewController: UIViewController?, postNum: String, answers: [DVBPostViewModel], allPosts: [DVBPostViewModel]) {
        let vc = DVBAsyncThreadViewController(postNum: postNum, answers: answers, allPosts: allPosts)
        viewController?.navigationController?.pushViewController(
            vc,
            animated: true)
    }

    @objc class func openCreateThread(from vc: UIViewController?, boardCode: String) {
        self.showCompose(from: vc, boardCode: boardCode, threadNum: "0")
    }

    @objc class func showCompose(from vc: UIViewController?, boardCode: String, threadNum: String) {
        let storyboard = UIStoryboard(
            name: STORYBOARD_NAME_MAIN,
            bundle: nil)
        let createPostViewController = storyboard.instantiateViewController(withIdentifier: STORYBOARD_ID_CREATE_POST_VIEW_CONTROLLER) as? DVBCreatePostViewController
        createPostViewController?.createPostViewControllerDelegate = vc as! DVBCreatePostViewControllerDelegate?
        createPostViewController?.threadNum = threadNum
        createPostViewController?.boardCode = boardCode
        var navigationController: UINavigationController? = nil
        if let createPostViewController = createPostViewController {
            navigationController = UINavigationController(rootViewController: createPostViewController)
        }

        if IS_IPAD {
            navigationController?.modalPresentationStyle = .popover
            createPostViewController?.preferredContentSize = CGSize(width: 320, height: 480)
            navigationController?.popoverPresentationController?.delegate = vc as! UIPopoverPresentationControllerDelegate?
            navigationController?.popoverPresentationController?.barButtonItem = vc?.navigationItem.rightBarButtonItem
            if UserDefaults.standard.bool(forKey: SETTING_ENABLE_DARK_THEME) {
                // Fix ugly white popover arrow on Popover Controller when dark theme enabled
                navigationController?.popoverPresentationController?.backgroundColor = UIColor.black
            }
        }

        if let navigationController = navigationController {
            vc?.present(
                navigationController,
                animated: true)
        }
    }

    @objc class func openWebm(from vc: UIViewController?, url: URL) {
        let webmVC = DVBWebmViewController(url: url)
        let nc = UINavigationController(rootViewController: webmVC)
        vc?.present(
            nc,
            animated: true)
    }

    @objc class func openAVPlayer(from vc: UIViewController?, url: URL) {
        let avPlayerVC = AVPlayerViewController()
        var player: AVPlayer? = nil
        player = AVPlayer(url: url)
        player?.isMuted = true
        avPlayerVC.player = player
        vc?.present(avPlayerVC, animated: true) {
            player?.play()
        }
    }
}

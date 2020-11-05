//
//  DVBThreadUIGenerator.swift
//  dvach-browser
//
//  Created by Dmitry on 16.10.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import AsyncDisplayKit
import TUSafariActivity
import ARChromeActivity

@objc class DVBThreadUIGenerator: NSObject {
    @objc class func styleTableNode(_ tableNode: ASTableNode?) {
        UIApplication.shared.keyWindow?.backgroundColor = DVBPostStyler.postCellBackgroundColor()
        
        tableNode?.view.separatorStyle = .none
        tableNode?.view.contentInset = UIEdgeInsets(top: DVBPostStyler.elementInset() / 2, left: 0, bottom: DVBPostStyler.elementInset() / 2, right: 0)
        tableNode?.allowsSelection = false
        tableNode?.backgroundColor = DVBPostStyler.postCellBackgroundColor()
        tableNode?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableNode?.view.showsVerticalScrollIndicator = false
        tableNode?.view.showsHorizontalScrollIndicator = false
    }
    
    @objc class func refreshControl(for tableView: ASTableView?, target: Any?, action: Selector) -> UIRefreshControl? {
        let refresh = UIRefreshControl()
        tableView?.addSubview(refresh)
        tableView?.sendSubviewToBack(refresh)
        refresh.addTarget(
            target,
            action: action,
            for: .valueChanged)
        return refresh
    }
    
    // MARK: - Buttons & actions
    
    /// Share
    @objc class func shareUrl(_ urlString: String?, fromVC vc: UIViewController?, fromButton button: UIBarButtonItem?) {
        let url = URL(string: urlString ?? "")
        let objectsToShare = [url]
        let safariActivity = TUSafariActivity()
        let chromeActivity = ARChromeActivity()
        let openInChromActivityTitle = NSLS("ACTIVITY_OPEN_IN_CHROME")
        chromeActivity.activityTitle = openInChromActivityTitle
        let activityViewController = UIActivityViewController(activityItems: objectsToShare.compactMap { $0 }, applicationActivities: [safariActivity, chromeActivity])
        
        // Only for iPad
        if activityViewController.responds(to: #selector(getter: UIViewController.popoverPresentationController)) {
            
            if button == nil {
                activityViewController.popoverPresentationController?.sourceView = vc?.navigationController?.navigationBar
                activityViewController.popoverPresentationController?.sourceRect = vc?.navigationController?.navigationBar.frame ?? CGRect.zero
            } else {
                activityViewController.popoverPresentationController?.barButtonItem = button
            }
        }
        vc?.present(activityViewController, animated: true)
    }
    
    /// Flag
    @objc class func flag(fromVC vc: UIViewController?, handler: @escaping (UIAlertAction?) -> Void) {
        let controller = UIAlertController()
        let flag = UIAlertAction(
            title: NSLS("BUTTON_REPORT"),
            style: .destructive,
            handler: handler)
        controller.addAction(flag)
        let cancel = UIAlertAction(
            title: NSLS("BUTTON_CANCEL"),
            style: .cancel,
            handler: { action in
            })
        controller.addAction(cancel)
        vc?.present(
            controller,
            animated: true)
    }
    
    @objc class func composeItemTarget(_ target: Any?, action: Selector) -> UIBarButtonItem? {
        let item = UIBarButtonItem(
            image: UIImage(named: "Compose"),
            style: .plain,
            target: target,
            action: action)
        return item
    }
    
    @objc class func toolbarItemsTarget(_ target: Any?, scrollBottom: Selector, bookmark: Selector, share: Selector, flag: Selector, reload: Selector) -> [UIBarButtonItem]? {
        let scrollItem = UIBarButtonItem(
            image: UIImage(named: "Bottompage"),
            style: .plain,
            target: target,
            action: scrollBottom)
        let bookmarkItem = UIBarButtonItem(
            barButtonSystemItem: .bookmarks,
            target: target,
            action: bookmark)
        let shareItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: target,
            action: share)
        let flagItem = UIBarButtonItem(
            image: UIImage(named: "ReportFlag"),
            style: .plain,
            target: target,
            action: flag)
        let reloadItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: target,
            action: reload)
        let items = [
            scrollItem,
            self.flexItem(withTarget: target),
            bookmarkItem,
            self.flexItem(withTarget: target),
            shareItem,
            self.flexItem(withTarget: target),
            flagItem,
            self.flexItem(withTarget: target),
            reloadItem
        ]
        return items as? [UIBarButtonItem]
    }
    
    /// Empty space between toolbar items
    private class func flexItem(withTarget target: Any?) -> UIBarButtonItem? {
        let item = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: target, action: nil)
        return item
    }
    
    @objc class func title(withSubject subject: String?, andThreadNum num: String?) -> String? {
        /// If thread Subject is empty - return OP post number
        let isSubjectEmpty = subject == ""
        if isSubjectEmpty {
            return num
        }
        
        return subject
    }
    
    @objc class func errorView() -> UIView? {
        let color = (UserDefaults.standard.bool(forKey: SETTING_ENABLE_DARK_THEME) ? DVBLoadingStatusViewColor.dark : DVBLoadingStatusViewColor.light)
        let view = DVBLoadingStatusView.instanceFromNib()
        view?.initLoadingStatusView(withMessage: NSLS("STATUS_LOADING_ERROR"), andStyle: DVBLoadingStatusViewStyle.error, andColor: color)
        return view
    }
    
    @objc class func footerView() -> UIActivityIndicatorView? {
        let activity = UIActivityIndicatorView(style: .gray)
        activity.tintColor = UIColor.gray
        activity.frame = CGRect(x: 0, y: 0, width: 0, height: 40)
        activity.startAnimating()
        return activity
    }
}

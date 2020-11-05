//
//  UrlNinja.swift
//  dvach-browser
//
//  Created by Dmitry on 29.07.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import Foundation

enum linkType : Int {
    case externalLink
    case boardLink
    case boardThreadLink
    case boardThreadPostLink
    case none
}


class UrlNinja: NSObject {
    var type: linkType
    var boardId: String?
    var threadId: String?
    var postId: String?
    var threadTitle: String?
    weak var urlOpener: DVBThreadDelegate?
    
    override init() {
        self.type = .none
        
        super.init()
    }
    
    convenience init(url: URL?) {
        self.init()
        
        let basicUrlPm = DVBUrls.baseWithoutSchemeForUrlNinja
        let basicUrlHk = DVBUrls.baseWithoutSchemeForUrlNinjaHk
        
        // Check host - if it's not 2ch - just return external type
        if !((url?.host == basicUrlPm) || (url?.host == basicUrlHk) || (url?.host == "www." + basicUrlPm) || (url?.host == "www." + basicUrlHk)), let _ = url?.host {
            type = .externalLink
        }
        
        //компоненты урла
        let source = url?.pathComponents
        
        if (source?.count ?? 0) > 1 {
            boardId = source?[1]
        }
        
        if (source?.count ?? 0) > 3 {
            threadId = source?[3]
        }
        
        //проверка на валидность полей
        var boardCheck: NSRegularExpression? = nil
        do {
            boardCheck = try NSRegularExpression(pattern: "[a-z, A-Z]+", options: [])
        } catch {
        }
        var threadCheck: NSRegularExpression? = nil
        do {
            threadCheck = try NSRegularExpression(pattern: "[0-9]+.html", options: [])
        } catch {
        }
        var postCheck: NSRegularExpression? = nil
        do {
            postCheck = try NSRegularExpression(pattern: "[0-9]+", options: [])
        } catch {
        }
        
        if let boardId = boardId {
            let boardResult = boardCheck?.firstMatch(in: boardId, options: [], range: NSRange(location: 0, length: boardId.count))
            if boardResult?.range.length != boardId.count {
                type = .externalLink
                return
            }
        }
        
        if let threadId = threadId {
            let threadResult = threadCheck?.firstMatch(in: threadId, options: [], range: NSRange(location: 0, length: threadId.count))
            if threadResult?.range.length != threadId.count {
                type = .externalLink
                return
            }
            //отпиливаем .html
            self.threadId = (threadId as NSString).substring(with: NSRange(location: 0, length: threadId.count-5))
        }
        
        if let postId = postId {
            let postResult = postCheck?.firstMatch(in: postId, options: [], range: NSRange(location: 0, length: postId.count))
            if postResult?.range.length != postId.count {
                type = .externalLink
                return
            }
        }
        
        //присваивание и проверка на валидность количества компонентов
        postId = url?.fragment
        
        if let _ = boardId, let _ = threadId, let _ = postId, source?.count == 4 {
            type = .boardThreadPostLink
            return
        } else if let _ = boardId, let _ = threadId, source?.count == 4 {
            type = .boardThreadLink
            return
        } else if let _ = boardId, source?.count == 2 {
            type = .boardLink
            return
        } else {
            type = .externalLink
        }
    }
    
    class func un(withUrl url: URL?) -> UrlNinja {
        return UrlNinja(url: url)
    }
    
    func isLinkInternal(withLink url: UrlNinja, andThreadNum threadNum: String?, andBoardCode boardCode: String?) -> Bool {
        var threadNum = threadNum
        var boardCode = boardCode
        if urlOpener == nil {
            return false
        }
        switch url.type {
        case .boardLink:
            // Open board
            /*
             BoardViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"BoardTag"];
             controller.boardId = urlNinja.boardId;
             [self.navigationController pushViewController:controller animated:YES];
             */
            
            return false
        case .boardThreadLink:
            // Open another thread
            if urlOpener?.responds(to: #selector(DVBThreadDelegate.openThread(withUrlNinja:))) ?? false {
                urlOpener?.openThread(withUrlNinja: url)
            }
        case .boardThreadPostLink:
            
            // if we do not have boardId of threadNum assidned - we take them from passed url
            if threadNum == nil {
                threadNum = url.threadId
            }
            if boardCode == nil {
                boardCode = url.boardId
            }
            
            // If its the same thread - open it locally from existing posts
            if (threadNum == url.threadId) && (boardCode == url.boardId) {
                if urlOpener?.responds(to: #selector(DVBThreadDelegate.openPost(withUrlNinja:))) ?? false {
                    urlOpener?.openPost(withUrlNinja: url)
                }
                
                return true
            } else {
                // Open another thread
                if urlOpener?.responds(to: #selector(DVBThreadDelegate.openThread(withUrlNinja:))) ?? false {
                    urlOpener?.openThread(withUrlNinja: url)
                }
            }
        default:
            
            return false
        }
        
        return true
    }
}

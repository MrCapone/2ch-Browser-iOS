//
//  DVBBoardModel.swift
//  dvach-browser
//
//  Created by Dmitry Lukianov on 16.07.2020.
//  Copyright © 2020 8of. All rights reserved.
//

import Foundation
import UIKit

@objc class DVBBoardModel: NSObject {
    /// Array contains all threads' OP posts for one page.
    @objc private(set) public var threadsArray: [DVBThread]?
    
    private var boardCode: String
    private var currentPage: UInt = 0
    private var maxPage: Int
    private var privateThreadsArray: [DVBThread]
    private var networking: DVBNetworking
    /// Dictionary of threads already showed in current cycle
    private var threadsAlreadyLoaded: [String : Any]?
    
    convenience override init() {
        NSException(name: NSExceptionName("Need board code"), reason: "Use -[[DVBBoardModel alloc] initWithBoardCode:]", userInfo: nil).raise()
        self.init()
    }
    
    @objc init(boardCode: String, andMaxPage maxPage: Int) {
        self.boardCode = boardCode
        self.maxPage = maxPage
        networking = DVBNetworking()
        privateThreadsArray = [DVBThread]()
        super.init()
    }
    
    /// Load next page for the current board
    @objc func loadNextPage(withCompletion completion: @escaping ([DVBThread], Error?) -> Void) {
        networking.getThreadsWithBoard(
            boardCode,
            andPage: currentPage,
            andCompletion: { resultDict, error in
                DispatchQueue.global(qos: .default).async(execute: {
                    
                    if self.currentPage == 0 {
                        self.threadsAlreadyLoaded = [String : Any]()
                    }
                    let threadsArray = resultDict?["threads"] as? [[String: Any]]
                    
                    for thread in threadsArray ?? [[String: Any]]() {
                        guard let threadNum = thread["thread_num"] as? String else {
                            continue
                        }
                        if self.threadsAlreadyLoaded?[threadNum] == nil {
                            self.threadsAlreadyLoaded?[threadNum] = ""
                            let threadPosts = thread["posts"] as? [[String: Any]]
                            let threadDict = threadPosts?.first
                            do {
                                let thread = try MTLJSONAdapter.model(of: DVBThread.self, fromJSONDictionary: threadDict) as! DVBThread
                                thread.postsCount = NSNumber(value: (threadPosts?.count ?? 0) + thread.postsCount.intValue)
                                let notInRestrictedMode = UserDefaults.standard.bool(forKey: DEFAULTS_AGE_CHECK_STATUS)
                                
                                if notInRestrictedMode {
                                    if let files = threadDict?["files"] as? [[String: Any]] {
                                        if files.count > 0 {
                                            if let tmpThumbnail = files.first?["thumbnail"] as? String {
                                                let thumbPath = "\(DVBUrls.base)\(tmpThumbnail)"
                                                thread.thumbnail = thumbPath
                                            }
                                        }
                                    }
                                }
                                self.privateThreadsArray.append(thread)
                            } catch {
                                print("error while parsing threads: \(error.localizedDescription)")
                            }
                        }
                    }
                    let resultArr = self.privateThreadsArray
                    self.threadsArray = resultArr
                    self.currentPage = self.currentPage + 1
                    if self.currentPage == self.maxPage {
                        self.currentPage = 0
                    }

                    completion(resultArr, error)
                })
        })
    }
    
    /// Entirely reload threads list in the board
    @objc func reloadBoard(withCompletion completion: @escaping ([DVBThread]?) -> Void) {
        privateThreadsArray.removeAll()
        currentPage = 0
        loadNextPage(withCompletion: { threadsCompletion, error in
            completion(threadsCompletion)
        })
    }

    func emptyThreadsArray() {
        threadsArray?.removeAll()
        privateThreadsArray.removeAll()
    }
}

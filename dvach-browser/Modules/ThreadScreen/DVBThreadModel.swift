//
//  DVBThreadModel.swift
//  dvach-browser
//
//  Created by Dmitry on 15.10.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import Foundation
import Mantle
import YapDatabase

@objc class DVBThreadModel: NSObject {
    @objc private(set) var boardCode: String?
    @objc private(set) var threadNum: String?
    /// Array contains all posts in the thread
    @objc private(set) var postsArray: [DVBPost]?
    /// Array of all post thumb images in thread
    @objc var thumbImagesArray: [String] = []
    /// Array of all post full images in thread
    @objc var fullImagesArray: [String] = []
    
    private var privatePostsArray: [DVBPost] = []
    private var privateThumbImagesArray: [String] = []
    private var privateFullImagesArray: [String] = []
    private var networking: DVBNetworking?
    private var postPreparation: DVBPostPreparation?
    private var postNumArray: [String]?
    /// Id of the last post for loading from it
    private var lastPostNum: String?
    private var database: YapDatabase?
    
    @objc init(boardCode: String?, andThreadNum threadNum: String?) {
        super.init()
        let dbManager = DVBDatabaseManager.sharedDatabase()
        database = dbManager.database
        
        self.boardCode = boardCode
        self.threadNum = threadNum
        networking = DVBNetworking()
        postPreparation = DVBPostPreparation(
            boardId: boardCode,
            andThreadId: threadNum)
    }
    
    /// Check if there are any posts in DB for thread num (thread num is stored inside DVBThreadModel instance)
    @objc func checkPostsInDbForThisThread(withCompletion completion: @escaping ([DVBPost]?) -> Void) {
        let connection = database?.newConnection()
        // Heavy work dispatched to a separate thread
        DispatchQueue.global(qos: .default).async(execute: { [self] in
            // Load posts from DB
            connection?.read({ [self] transaction in
                if let arrayOfPosts = transaction.object(forKey: threadNum!, inCollection: DVBDatabaseManager.dbCollectionThreads) as? [DVBPost] {
                    privatePostsArray = arrayOfPosts
                    privateThumbImagesArray = thumbImagesArray(forPostsArray: arrayOfPosts)
                    privateFullImagesArray = fullImagesArray(forPostsArray: arrayOfPosts)
                    
                    if privatePostsArray.count != 0 {
                        let lastPost = privatePostsArray.last
                        lastPostNum = lastPost?.num
                    }
                    
                    postsArray = arrayOfPosts
                    
                    DispatchQueue.main.async(execute: {
                        completion(arrayOfPosts)
                    })
                } else {
                    DispatchQueue.main.async(execute: {
                        completion(nil)
                    })
                }
            })
        })
    }
    
    /// Entirely reload post list in the thread
    @objc func reloadThread(withCompletion completion: @escaping ([DVBPost]?) -> Void) {
        guard let boardCode = boardCode, let threadNum = threadNum else {
            print("No Board code or Thread number")
            completion(nil)
            return
        }
        
        networking?.getPostsWithBoard(boardCode,
                                      andThread:threadNum,
                                      andPostNum:lastPostNum,
                                      andCompletion:{ [self] postsDictionary in
                                        // Heavy work dispatched to a separate thread
                                        DispatchQueue.global(qos: .default).async(execute: { [self] in
                                            // Do heavy or time consuming work
                                            // Task 1: Read the data from sqlite
                                            // Task 2: Process the data with a flag to stop the process if needed (only if this takes very long and may be cancelled often).
                                            var postNumMutableArray: [String] = []
                                            // If it's first load - do not include post
                                            if (lastPostNum == nil) {
                                                self.privatePostsArray = []
                                                self.privateThumbImagesArray = []
                                                self.privateFullImagesArray = []
                                            } else {
                                                // update dates to relevant values
                                                for earlierPost in privatePostsArray {
                                                    if let num = earlierPost.num {
                                                        postNumMutableArray.append(num)
                                                    }
                                                    earlierPost.replies = []
                                                }
                                            }
                                            
                                            var posts2Array: [[String : Any]]?
                                            
                                            if let postsDictionary = postsDictionary as? [String: Any], let threads = postsDictionary["threads"] as? [[String: Any]] {
                                                posts2Array = threads[0]["posts"] as? [[String : Any]]
                                            } else {
                                                posts2Array = postsDictionary as? [[String : Any]]
                                            }
                                            
                                            var postIndexNumber = 0
                                            
                                            for postDictionary in posts2Array! {
                                                // Check if currently loading not the entire thread from the sratch but only from specific post
                                                // just skip first element because it will be the same as the last element from previous loading
                                                if (postIndexNumber == 0) && ((self.lastPostNum) != nil) {
                                                    postIndexNumber += 1
                                                    continue
                                                }
                                                
                                                var post: DVBPost?
                                                do {
                                                    post = try MTLJSONAdapter.model(
                                                        of: DVBPost.self,
                                                        fromJSONDictionary: postDictionary) as? DVBPost
                                                } catch {
                                                    print("error: %@", error.localizedDescription)
                                                }
                                                
                                                var comment = postDictionary["comment"] as? String
                                                
                                                // Fix bug with crash
                                                if (comment! as NSString).range(of: "ررً").location != NSNotFound {
                                                    let brokenStringHere:String! = NSLS("POST_BAD_SYMBOLS_IN_POST")
                                                    comment = brokenStringHere
                                                }
                                                
                                                let attributedComment = self.postPreparation?.commentWithMarkdown(withComments: comment)
                                                
                                                post?.comment = attributedComment
                                                
                                                postNumMutableArray.append(post!.num!)
                                                
                                                let repliesToArray = postPreparation?.repliesTo
                                                
                                                let files = postDictionary["files"]
                                                var singlePostPathesArrayMutable: [String] = []
                                                var singlePostThumbPathesArrayMutable: [String] = []
                                                
                                                let ageCheckOk = UserDefaults.standard.bool(forKey: DEFAULTS_AGE_CHECK_STATUS)
                                                
                                                if let files = files as? [[String : Any]], ageCheckOk{
                                                    for fileDictionary in files {
                                                        let fullFileName = fileDictionary["path"] as? String
                                                        
                                                        let thumbPath = "\(DVBUrls.base)\(fileDictionary["thumbnail"] as! String)"
                                                        
                                                        singlePostThumbPathesArrayMutable.append(thumbPath)
                                                        privateThumbImagesArray.append(thumbPath)
                                                        
                                                        let picPath = "\(DVBUrls.base)\(fullFileName!)"
                                                        
                                                        singlePostPathesArrayMutable.append(picPath)
                                                        privateFullImagesArray.append(picPath)
                                                    }
                                                }
                                                
                                                if let repliesToArray = repliesToArray {
                                                    post?.repliesTo = repliesToArray
                                                }
                                                
                                                post?.thumbPathesArray = singlePostThumbPathesArrayMutable
                                                
                                                post?.pathesArray = singlePostPathesArrayMutable
                                                
                                                privatePostsArray.append(post!)
                                                
                                                postIndexNumber += 1
                                            }
                                            
                                            thumbImagesArray = privateThumbImagesArray
                                            fullImagesArray = privateFullImagesArray
                                            
                                            postNumArray = postNumMutableArray
                                            
                                            // array with almost all info - BUT without final ANSWERS array for every post
                                            let semiResultArray = privatePostsArray
                                            
                                            var semiResultMutableArray = semiResultArray
                                            
                                            var currentPostIndex = 0
                                            
                                            for post in semiResultArray {
                                                var delete: [String] = []
                                                for replyTo in post.repliesTo! {
                                                    let index = postNumArray!.firstIndex(of: replyTo ) ?? NSNotFound
                                                    
                                                    if index != NSNotFound {
                                                        let replyPost = semiResultMutableArray[index]
                                                        replyPost.replies.append(post)
                                                    } else {
                                                        delete.append(replyTo)
                                                    }
                                                }
                                                
                                                let postForChangeReplyTo = semiResultMutableArray[currentPostIndex]
                                                if let repliesTo = postForChangeReplyTo.repliesTo {
                                                    for replyTo in delete {
                                                        postForChangeReplyTo.repliesTo? = repliesTo.filter({ $0 != replyTo })
                                                    }
                                                }
                                                semiResultMutableArray[currentPostIndex] = postForChangeReplyTo
                                                
                                                currentPostIndex += 1
                                            }
                                            
                                            assignPostsArray(fromWeak: semiResultMutableArray)
                                            let lastPost = postsArray?.last
                                            lastPostNum = lastPost?.num
                                            
                                            if let postsArray = postsArray {
                                                if postsArray.count == 0 {
                                                    dropPostsArray()
                                                    
                                                    // back to main
                                                    DispatchQueue.main.async(execute: { [] in
                                                        completion(postsArray)
                                                    })
                                                } else {
                                                    writeToDb(withPosts: postsArray, andThreadNum: threadNum, andCompletion: { [] in
                                                        // back to main
                                                        DispatchQueue.main.async(execute: { [] in
                                                            completion(postsArray)
                                                        })
                                                    })
                                                }
                                            }
                                        })
                                      })
    }
    
    func assignPostsArray(fromWeak array: [DVBPost]?) {
        postsArray = array
    }

    func dropPostsArray() {
        postsArray = nil
    }
    
    /// Report thread to admins
    @objc func reportThread() {
        networking?.reportThread(
            withBoardCode: boardCode!,
            andThread: threadNum!,
            andComment: "нарушение правил")
    }
    
    @objc func bookmarkThread(withTitle title: String?) {
        let urlToShare = "/\(boardCode!)/res/\(threadNum!).html"
        let userInfo = [
            "url": urlToShare,
            "title": (title ?? threadNum!)
        ]

        NotificationCenter.default.post(
            name: NSNotification.Name(rawValue: NOTIFICATION_NAME_BOOKMARK_THREAD),
            object: self,
            userInfo: userInfo)
    }
    
    ///  Generate array of thumbnail images from posts
    ///
    ///  - Parameter postsArray: array of posts
    ///
    ///  - Returns: array of thumbnail images
    @objc func thumbImagesArray(forPostsArray postsArray: [DVBPost]?) -> [String] {
        privateThumbImagesArray = []
        for post in postsArray! {
            let postThumbsArray = post.thumbPathesArray
            for thumbPath in postThumbsArray! {
                privateThumbImagesArray.append(thumbPath)
            }
        }
        thumbImagesArray = privateThumbImagesArray

        return thumbImagesArray
    }
    
    ///  Generate array of full images from posts
    ///
    ///  - Parameter postsArray: array of posts
    ///
    ///  - Returns: array of full images
    @objc func fullImagesArray(forPostsArray postsArray: [DVBPost]?) -> [String] {
        privateFullImagesArray = []
        for post in postsArray! {
            let postThumbsArray = post.pathesArray
            for thumbPath in postThumbsArray! {
                privateFullImagesArray.append(thumbPath)
            }
        }
        fullImagesArray = privateFullImagesArray

        return fullImagesArray
    }
    
    // MARK: - Scroll position
    @objc func storedThreadPosition(_ completion: @escaping (IndexPath?) -> Void) {
        let connection = database?.newConnection()
        DispatchQueue.global(qos: .default).async(execute: { [self] in
            connection?.asyncRead({ [self] transaction in
                let visibleIndex = transaction.object(forKey: threadNum!, inCollection: DVBDatabaseManager.dbCollectionThreadPositions)
                if visibleIndex == nil {
                    return
                }
                DispatchQueue.main.async(execute: {
                    completion(visibleIndex as? IndexPath)
                })
            })
        })
    }
    
    @objc func storeThreadPosition(_ indexPath: IndexPath?) {
        let connection = database?.newConnection()
        DispatchQueue.global(qos: .default).async(execute: { [self] in
            connection?.asyncReadWrite({ [self] transaction in
                transaction.setObject(indexPath, forKey: threadNum!, inCollection: DVBDatabaseManager.dbCollectionThreadPositions)
            })
        })
    }
    
    // MARK: - DB
    func writeToDb(withPosts posts: [DVBPost], andThreadNum threadNumb: String, andCompletion callback: @escaping () -> Void) {
        // Get a connection to the database (can have multiple for concurrency)
        let connection = database?.newConnection()
        // Add an object
        connection?.readWrite({ transaction in
            transaction.setObject(posts, forKey: threadNumb, inCollection: DVBDatabaseManager.dbCollectionThreads)
            callback()
        })
    }
}

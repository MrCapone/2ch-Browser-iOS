//
//  DVBAsyncThreadViewController.swift
//  dvach-browser
//
//  Created by Dmitry on 05.11.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import AsyncDisplayKit

private let MAX_OFFSET_DIFFERENCE_TO_SCROLL_AFTER_POSTING: CGFloat = 500.0


class DVBAsyncThreadViewController: ASDKViewController<ASDisplayNode>, ASTableDataSource, ASTableDelegate, DVBCreatePostViewControllerDelegate, DVBThreadDelegate {
    private var threadModel: DVBThreadModel?
    private var tableNode: ASTableNode?
    private var refreshControl: UIRefreshControl?
    private var bottomRefreshControl: UIRefreshControl?
    private var posts: [DVBPostViewModel] = []
    private var allPosts: [DVBPostViewModel]?
    private var autoScrolled = false
    private var alreadyLoading = false
    /// New posts count added with last thread update
    private var previousPostsCount: NSNumber = 0
    
    init(boardCode: String, andThreadNumber threadNumber: String, andThreadSubject subject: String) {
        let tableNode = ASTableNode(style: UITableView.Style.plain)
        super.init(node: tableNode)
        self.tableNode = tableNode
        threadModel = DVBThreadModel(boardCode: boardCode, andThreadNum: threadNumber)
        self.title = DVBThreadUIGenerator.title(
            withSubject: subject,
            andThreadNum: threadNumber)
        createRightButton()
        setupTableNode()
        initialThreadLoad()
        fillToolbar()
    }

    init(postNum: String, answers: [DVBPostViewModel], allPosts: [DVBPostViewModel]?) {
        let tableNode = ASTableNode(style: UITableView.Style.plain)
        super.init(node: tableNode)
        self.tableNode = tableNode
        posts = answers
        self.allPosts = allPosts
        title = postNum
        setupTableNode()
        initialThreadLoad()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View stuff
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if UserDefaults.standard.bool(forKey: SETTING_ENABLE_DARK_THEME) {
            navigationController?.toolbar.barStyle = .blackTranslucent
        } else {
            navigationController?.toolbar.barStyle = .default
        }
        if (allPosts == nil) {
            navigationController?.setToolbarHidden(false, animated: true)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if autoScrolled {
            return
        }
        autoScrolled = true
        threadModel?.storedThreadPosition({ [self] indexPath in
            if let indexPath = indexPath {
                tableNode?.scrollToRow(at: indexPath, at: .bottom, animated: false)
            }
        })
    }

    func setupTableNode() {
        DVBThreadUIGenerator.styleTableNode(tableNode)
        tableNode?.delegate = self
        tableNode?.dataSource = self
        if (allPosts == nil) {
            addTopRefreshControl()
            tableNode?.view.tableFooterView = DVBThreadUIGenerator.footerView()
        }
    }

    func addTopRefreshControl() {
        refreshControl = DVBThreadUIGenerator.refreshControl(
            for: tableNode?.view,
            target: self,
            action: #selector(reloadThread))
    }
    
    func bottomRefreshStart(_ start: Bool) {
        if !(tableNode?.view.tableFooterView is UIActivityIndicatorView) {
            return
        }
        let activity = tableNode?.view.tableFooterView as? UIActivityIndicatorView
        if start {
            reloadThread()
            activity?.startAnimating()
        } else {
            if tableNode?.view.tableFooterView is UIActivityIndicatorView {
                let activity = tableNode?.view.tableFooterView as? UIActivityIndicatorView
                if posts.count > 8 {
                    activity?.startAnimating()
                } else {
                    activity?.stopAnimating()
                }
            }
        }
    }

    func createRightButton() {
        navigationItem.rightBarButtonItem = DVBThreadUIGenerator.composeItemTarget(self, action: #selector(composeAction))
    }

    func fillToolbar() {
        toolbarItems = DVBThreadUIGenerator.toolbarItemsTarget(
            self,
            scrollBottom: #selector(scrollToBottom),
            bookmark: #selector(bookmarkAction),
            share: #selector(shareAction),
            flag: #selector(flagAction),
            reload: #selector(reloadThread))
    }
    
    // MARK: - Data management and processing

    /// Get data for thread from Db if any
    func initialThreadLoad() {
        alreadyLoading = true
        threadModel?.checkPostsInDbForThisThread(withCompletion: { [self] posts in
            // array of DVBPost
            if posts == nil {
                alreadyLoading = false
                reloadThread()
                return
            }
            self.posts = convertPosts(toViewModel: posts!, forAnswer: false) ?? []
            DispatchQueue.main.async(execute: { [self] in
                tableNode!.reloadData()
                alreadyLoading = false
                reloadThread()
            })
        })
    }

    func convertPosts(toViewModel posts: [DVBPost], forAnswer: Bool) -> [DVBPostViewModel]? {
        var vmPosts: [DVBPostViewModel]? = []
        (posts as NSArray).enumerateObjects({ post, idx, stop in
            let post = post as! DVBPost
            let vm = DVBPostViewModel(post: post, andIndex: idx)
            if forAnswer {
                vm.convertToNested()
            }
            vmPosts?.append(vm)
        })
        return vmPosts
    }
    
    // MARK: - ASTableDataSource & ASTableDelegate
    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        let post = posts[indexPath.row]
        return { [self] in
            return DVBPostNode(post: post, andDelegate: self, width: view.bounds.size.width)
        }
    }

    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }

    func scrolledPastBottomThreshold(in tableView: UITableView?) -> Bool {
        let kChrisTableViewAnimationThreshold: CGFloat = 40.0
        let scrolledPast = tableView!.contentOffset.y - kChrisTableViewAnimationThreshold
        let bottomThreshold = tableView!.contentSize.height - tableView!.frame.size.height
        return scrolledPast >= bottomThreshold
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // Store current scrolling position
        let visibleIndexes = tableNode?.indexPathsForVisibleRows
        if visibleIndexes!().count == 0 {
            return
        }
        threadModel?.storeThreadPosition(visibleIndexes!().last)

        // Refresh posts
        if scrollView == tableNode?.view {
            if scrolledPastBottomThreshold(in: tableNode!.view) {
                // Start the animation and network
                bottomRefreshStart(true)
            }
        }
    }

    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        // Store current scrolling position on top
        let count = tableNode!.numberOfRows(inSection: 0)
        if count == 0 {
            return
        }
        let firstIndexPath = IndexPath(row: 0, section: 0)
        threadModel?.storeThreadPosition(firstIndexPath)
    }
    
    // MARK: - Network Loading
    @objc func reloadThread() {
        if alreadyLoading {
            return
        }
        getPostsWithBoard(
            threadModel?.boardCode,
            andThread: threadModel?.threadNum,
            andCompletion: { [self] posts in
                if posts == nil {
                    DispatchQueue.main.async(execute: { [self] in
                        alreadyLoading = false
                        refreshControl?.endRefreshing()
                        bottomRefreshStart(false)
                        tableNode?.view.backgroundView = DVBThreadUIGenerator.errorView()
                    })
                    return
                }
                var newRows: [IndexPath]? = []
                for i in self.posts.count..<posts!.count {
                    let path = IndexPath(row: i, section: 0)
                    newRows?.append(path)
                }
                self.posts = convertPosts(toViewModel: posts!, forAnswer: false) ?? []
                DispatchQueue.main.async(execute: { [self] in
                    addTableRows(newRows)
                    checkNewPostsCount()
                    tableNode?.view.backgroundView = nil
                })
            })
    }

    func addTableRows(_ paths: [IndexPath]?) {
        tableNode?.performBatch(
            animated: true,
            updates: {
                if let paths = paths {
                    tableNode?.insertRows(at: paths, with: .fade)
                }
            }) { [self] finished in
            alreadyLoading = false
            refreshControl?.endRefreshing()
            bottomRefreshStart(false)
        }
    }
    
    /// Get data from 2ch server
    func getPostsWithBoard(_ board: String?, andThread threadNum: String?, andCompletion completion: @escaping ([DVBPost]?) -> Void) {
        threadModel?.reloadThread(withCompletion: { completionsPosts in
            completion(completionsPosts)
        })
    }

    // MARK: - New posts count handling

    /// Check if server have new posts and scroll if user already scrolled to the end
    func checkNewPostsCount() {
        let additionalPostCount = posts.count - previousPostsCount.intValue

        if (previousPostsCount.intValue > 0) && (additionalPostCount > 0) {
            let newMessagesCount = NSNumber(value: additionalPostCount)

            perform(
                #selector(newMessagesPrompt(withNewMessagesCount:)),
                with: newMessagesCount,
                afterDelay: 0.5)
        }

        let postsCountNewValue = NSNumber(value: posts.count)

        previousPostsCount = postsCountNewValue

        if additionalPostCount == 0 {
            scrollToBottom()
        }
    }
    
    // MARK: - Prompt

    /// Show and hide message after delay
    func showPrompt(withMessage message: String?) {
        navigationItem.prompt = message
        perform(
            #selector(clearPrompt),
            with: nil,
            afterDelay: 1.5)
    }

    /// Clear prompt from any status / error messages.
    @objc func clearPrompt() {
        // Prevent crashes
        if navigationItem.prompt == nil {
            return
        }
        navigationItem.prompt = nil
    }

    /// Show prompt with cound of new messages
    @objc func newMessagesPrompt(withNewMessagesCount newMessagesCount: NSNumber?) {
        showPrompt(withMessage: "\(NSNumber(value: newMessagesCount?.intValue ?? 0)) \(NSLS("PROMPT_NEW_MESSAGES"))")

        // Check if difference is not too big (scroll isn't needed if user saw only half of the thread)
        let offsetDifference = tableNode!.view.contentSize.height - tableNode!.view.contentOffset.y - tableNode!.view.bounds.size.height

        if offsetDifference < MAX_OFFSET_DIFFERENCE_TO_SCROLL_AFTER_POSTING && posts.count > 10 {
            Timer.scheduledTimer(
                timeInterval: 2.0,
                target: self,
                selector: #selector(scrollToBottom),
                userInfo: nil,
                repeats: false)
        }
    }

    // MARK: - DVBThreadDelegate
    func openGalleryWIthUrl(_ url: String) {
        let thumbIndex = threadModel!.thumbImagesArray.firstIndex(of: url) ?? NSNotFound
        if thumbIndex == NSNotFound {
            return
        }
        let mediaOpener = DVBMediaOpener(viewController: self)

        mediaOpener.openMedia(
            withUrlString: threadModel!.fullImagesArray[thumbIndex],
            andThumbImagesArray: threadModel!.thumbImagesArray,
            andFullImagesArray: threadModel!.fullImagesArray)
    }
    
    func quotePostIndex(_ index: Int, andText text: String?) {
        attachAnswerToComment(withPost: index, andText: text)

        if shouldStopReplyAndRedirect() {
            return
        }

        composeAction()
    }

    func showAnswers(for index: Int) {
        let post = threadModel?.postsArray?[index]
        DVBRouter.pushAnswers(
            from: self,
            postNum: post!.num!,
            answers: convertPosts(toViewModel: post!.replies, forAnswer: true)!,
            allPosts: allPosts != nil ? allPosts! : posts)
    }

    func attachAnswerToComment(withPost index: Int, andText text: String?) {
        let post = posts[index]
        let postNum = post.num

        let sharedComment = DVBComment.sharedComment()

        if let text = text {
            let postComment = post.text
            sharedComment.topUpComment(withPostNum: postNum,
                andOriginalPostText: postComment,
                andQuoteString: text)
        } else {
            sharedComment.topUpComment(withPostNum: postNum)
        }
    }

    func share(withUrl url: String) {
        let shareItem = toolbarItems?[4]
        DVBThreadUIGenerator.shareUrl(
            url,
            fromVC: self,
            fromButton: shareItem)
    }

    func isLinkInternal(withLink url: UrlNinja) -> Bool {
        let urlNinjaHelper = UrlNinja()
        urlNinjaHelper.urlOpener = self
        let answer = urlNinjaHelper.isLinkInternal(withLink: url, andThreadNum: threadModel!.threadNum, andBoardCode: threadModel?.boardCode)

        return answer
    }
    
    func openPost(withUrlNinja urlNinja: UrlNinja) {
        let postNum = urlNinja.postId
        let postNumPredicate = NSPredicate(format: "num == %@", postNum ?? "")

        var arrayOfPosts = (threadModel!.postsArray! as NSArray).filtered(using: postNumPredicate)

        var post: DVBPost?

        if arrayOfPosts.count > 0 {
            // check our regular array first
            post = arrayOfPosts[0] as? DVBPost
            DVBRouter.pushAnswers(
                from: self,
                postNum: post!.num!,
                answers: convertPosts(toViewModel: [post!], forAnswer: true)!,
                allPosts: allPosts != nil ? allPosts! : posts)
            return
        } else if (allPosts != nil) {
            // if it didn't work - check our full array
            arrayOfPosts = (allPosts! as NSArray).filtered(using: postNumPredicate)

            if arrayOfPosts.count > 0 {
                post = arrayOfPosts[0] as? DVBPost
                let postVM = post as! DVBPostViewModel
                postVM.convertToNested()
                DVBRouter.pushAnswers(
                    from: self,
                    postNum: postVM.num!,
                    answers: [postVM],
                    allPosts: (allPosts != nil  ? allPosts : posts)!)
            } else {
                // end method if we can't find posts
                return
            }
        } else {
            // if we do not have allThreadsArray AND can't find post in regular array (impossible but just in case...)
            return
        }

    }

    func openThread(withUrlNinja urlNinja: UrlNinja) {
        DVBRouter.pushThread(
            from: self,
            board: urlNinja.boardId!,
            thread: urlNinja.threadId!,
            subject: nil,
            comment: nil)
    }
    
    // MARK: - DVBCreatePostViewControllerDelegate
    func updateThreadAfterPosting() {
        reloadThread()
    }

    // MARK: - Helpers for posting from another copy of the controller

    /// Plain post id reply
    func shouldStopReplyAndRedirect() -> Bool {
        if shouldPopToPreviousControllerBeforeAnswering() {
            let firstThreadVC = navigationController?.viewControllers[2] as? DVBAsyncThreadViewController
            if let firstThreadVC = firstThreadVC {
                navigationController?.popToViewController(
                    firstThreadVC,
                    animated: true)
            }
            DVBRouter.showCompose(from: firstThreadVC, boardCode: threadModel!.boardCode!, threadNum: threadModel!.threadNum!)
            return true
        }

        return false
    }

    /// Helper to determine if current controller is the original one or just 'Answers' controller
    func shouldPopToPreviousControllerBeforeAnswering() -> Bool {
        let arrayOfControllers = navigationController?.viewControllers

        var countOfThreadControllersInStack = 0
        for vc in arrayOfControllers ?? [] {
            if vc is DVBAsyncThreadViewController {
                countOfThreadControllersInStack += 1

                if (countOfThreadControllersInStack >= 2) && ((navigationController?.viewControllers.count ?? 0) >= 3) {
                    return true
                }
            }
        }
        return false
    }
    
    // MARK: - Actions
    @objc func composeAction() {
        DVBRouter.showCompose(from: self, boardCode: threadModel!.boardCode!, threadNum: threadModel!.threadNum!)
    }

    @objc func scrollToBottom() {
        var lastRowIndex = tableNode!.numberOfRows(inSection: 0) - 1
        if lastRowIndex < 0 {
            lastRowIndex = 0
        }
        let lastIndexPath = IndexPath(row: lastRowIndex, section: 0)
        tableNode?.scrollToRow(
            at: lastIndexPath,
            at: .bottom,
            animated: true)
        threadModel?.storeThreadPosition(lastIndexPath)
    }

    @objc func shareAction() {
        let url = "\(DVBUrls.base)/\(threadModel!.boardCode!)/res/\(threadModel!.threadNum!).html"
        share(withUrl: url)
    }

    @objc func flagAction() {
        DVBThreadUIGenerator.flag(fromVC: self, handler: { [self] action in
            threadModel?.reportThread()
            showPromptAboutReportedPost()
        })
    }

    @objc func bookmarkAction() {
        threadModel?.bookmarkThread(withTitle: title)
        showPrompt(withMessage: NSLS("PROMPT_THREAD_BOOKMARKED"))
    }

    func showPromptAboutReportedPost() {
        navigationItem.prompt = NSLS("PROMPT_REPORT_SENT")
        perform(
            #selector(clearPrompt),
            with: nil,
            afterDelay: 2.0)
    }
}

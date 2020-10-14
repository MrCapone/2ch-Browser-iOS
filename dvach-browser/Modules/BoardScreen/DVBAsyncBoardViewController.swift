//
//  DVBAsyncBoardViewController.swift
//  dvach-browser
//
//  Created by Dmitry on 14.10.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import AsyncDisplayKit

class DVBAsyncBoardViewController: ASDKViewController<ASDisplayNode>, ASTableDataSource, ASTableDelegate, DVBCreatePostViewControllerDelegate {
    private static var ageAlertHasShown = false
    
    private var tableNode: ASTableNode!
    private var refreshControl: UIRefreshControl!
    /// Board's shortcode.
    private var boardCode: String = ""
    /// MaxPage (i.e. page count) for specific board.
    private var pages = 0
    private var currentPage: Int?
    private var alreadyLoadingNextPage = false
    /// Array contains all threads' OP posts for one page.
    private var threadsArray: [DVBThread]?
    private var boardModel: DVBBoardModel!
    /// Need property for know if we gonna create new thread or not.
    private var createdThreadNum: String?
    
    init(_ boardCode: String, pages: Int) {
        let tableNode = ASTableNode(style: UITableView.Style.plain)
        super.init(node: tableNode)
        self.boardCode = boardCode
        self.pages = pages
        self.tableNode = tableNode

        let item = UIBarButtonItem(
            image: UIImage(named: "Compose"),
            style: .plain,
            target: self,
            action: #selector(DVBAsyncBoardViewController.openThred(withCreatedThread:)))
        navigationItem.rightBarButtonItem = item

        setupTableNode()
        currentPage = 0

        // set loading flag here because othervise
        // scrollViewDidScroll methods will start loading 'next' page (actually the same page) again
        alreadyLoadingNextPage = false

        // If no pages setted (or pages is 0 - then set 10 pages).
        if (self.pages == 0) {
            self.pages = 10
        }

        title = "/\(self.boardCode)/"
        boardModel = DVBBoardModel(
            boardCode: self.boardCode,
            andMaxPage: self.pages)
        initialBoardLoad()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        // Because we need to turn off toolbar every time view appears, not only when it loads first time
        navigationController?.setToolbarHidden(true, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Show this alert only once because of UX
        if !DVBAsyncBoardViewController.ageAlertHasShown {
            if DVBBoardStyler.ageCheckNotPassed() {
                let alert = DVBAlertGenerator.ageCheckAlert()
                if let alert = alert {
                    present(alert, animated: true)
                    DVBAsyncBoardViewController.ageAlertHasShown = true
                }
            }
        }
    }

    // MARK: - Setup
    func setupTableNode() {
        UIApplication.shared.keyWindow?.backgroundColor = DVBBoardStyler.threadCellBackgroundColor()

        tableNode.view.separatorStyle = .none
        tableNode.view.contentInset = UIEdgeInsets(top: DVBBoardStyler.elementInset() / 2, left: 0, bottom: DVBBoardStyler.elementInset() / 2, right: 0)
        tableNode.backgroundColor = DVBBoardStyler.threadCellBackgroundColor()
        tableNode.delegate = self
        tableNode.dataSource = self
        tableNode.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableNode.view.showsVerticalScrollIndicator = false
        tableNode.view.showsHorizontalScrollIndicator = false
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(
            self,
            action: #selector(reloadBoardPage),
            for: .valueChanged)
        tableNode.view.addSubview(refreshControl)
    }
    
    // MARK: - Network

    /// First time loading thread list
    func initialBoardLoad() {
        alreadyLoadingNextPage = true
        boardModel.reloadBoard(withCompletion: { [self] completionThreadsArray in
            threadsArray = completionThreadsArray
            DispatchQueue.main.async(execute: { [self] in
                tableNode.reloadData()
                alreadyLoadingNextPage = false
                if completionThreadsArray == nil || completionThreadsArray?.count == 0 {
                    tableNode.view.backgroundView = DVBThreadUIGenerator.errorView()
                } else {
                    tableNode.view.backgroundView = nil
                }
            })
        })
    }
    
    @objc func reloadBoardPage() {
        // Prevent reloading while already loading board items
        if alreadyLoadingNextPage {
            refreshControl.endRefreshing()
            return
        }
        alreadyLoadingNextPage = true
        let duration = 1.0
        UIView.animate(
            withDuration: TimeInterval(duration),
            animations: {
                self.tableNode.view.layer.opacity = 0
            }) { [self] finished in
                tableNode.reloadData()
                boardModel.reloadBoard(withCompletion: { [self] completionThreadsArray in
                    currentPage = nil
                    threadsArray = completionThreadsArray
                    DispatchQueue.main.async(execute: { [self] in
                        refreshControl?.endRefreshing()
                        tableNode.reloadData()
                        if threadsArray!.count > 0 {
                            tableNode.view.backgroundView = nil
                        }
                        UIView.animate(
                            withDuration: TimeInterval(duration),
                            animations: { [self] in
                                tableNode.view.layer.opacity = 1
                            }) { [self] finished in
                                alreadyLoadingNextPage = false
                            }
                    })
                })
            }
    }
    
    func loadNextBoardPage() {
        if alreadyLoadingNextPage {
            return
        }
        if pages > currentPage! {
            boardModel.loadNextPage(withCompletion: { [self] completionThreadsArray, error in
                let threadsCountWas = (threadsArray!.count != 0) ? threadsArray!.count : 0
                threadsArray = completionThreadsArray
                let threadsCountNow = (threadsArray!.count != 0) ? threadsArray!.count : 0

                var mutableIndexPathes: [IndexPath] = []

                for i in threadsCountWas..<threadsCountNow {
                    mutableIndexPathes.append(IndexPath(row: i, section: 0))
                }
                if threadsArray!.count == 0 {
                    navigationItem.rightBarButtonItem?.isEnabled = false
                } else {
                    currentPage = currentPage! + 1
                    // Update only if we have something to show
                    DispatchQueue.main.async(execute: { [self] in
                        tableNode.insertRows(at: mutableIndexPathes, with: .fade)
                        alreadyLoadingNextPage = false
                        navigationItem.rightBarButtonItem?.isEnabled = true
                    })
                }
            })
        } else {
            currentPage = 0
            loadNextBoardPage()
        }
    }
    
    // MARK: - Routing
    @objc func openNewThread() {
        DVBRouter.openCreateThread(from: self, boardCode: boardCode)
    }

    // MARK: - DVBCreatePostViewControllerDelegate
    @objc func openThred(withCreatedThread threadNum: String?) {
        let thread = DVBThread()
        thread?.num = threadNum!
        DVBRouter.pushThread(
            from: self,
            board: boardCode,
            thread: threadNum!,
            subject: nil,
            comment: nil)
    }

    // MARK: - ASTableDataSource & ASTableDelegate
    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        // Early return in case of error
        guard let threadsArray = boardModel.threadsArray else {
            return {
                return ASCellNode()
            }
        }
        guard indexPath.row < threadsArray.count else {
            return {
                return ASCellNode()
            }
        }

        let thread = threadsArray[indexPath.row]
        return { () in
            return DVBThreadNode(thread: thread)
        }
    }

    func tableNode(_ tableNode: ASTableNode, willDisplayRowWith node: ASCellNode) {
        if let indexPath = node.indexPath, let threadsArray = boardModel.threadsArray, indexPath.row == threadsArray.count {
            loadNextBoardPage()
        }
    }
    
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        if let threadsArray = boardModel.threadsArray {
            return threadsArray.count + 1
        }
        return 0
    }

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        guard let threadsArray = boardModel.threadsArray else {
            return
        }
        
        let thread = threadsArray[indexPath.row]
        DVBRouter.pushThread(
            from: self,
            board: boardCode,
            thread: thread.num,
            subject: thread.subject as String,
            comment: thread.comment as String)
        self.tableNode.deselectRow(at: indexPath, animated: true)
    }
}

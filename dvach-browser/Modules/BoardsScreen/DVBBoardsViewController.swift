//
//  DVBBoardsViewController.swift
//  dvach-browser
//
//  Created by Dmitry on 09.10.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import UIKit

private let MAXIMUM_SCROLL_UNTIL_SCROLL_TO_TOP_ON_APPEAR = CGFloat(190.0)

class DVBBoardsViewController: DVBCommonTableViewController, DVBAlertGeneratorDelegate, DVBBoardsModelDelegate {
    /// For storing fetched boards
    private var boardsDict: [AnyHashable : Any]?
    private var defaultsToCompare: [AnyHashable : Any] = [:]
    private var boardsModel: DVBBoardsModel?
    private var alertGenerator: DVBAlertGenerator?
    @IBOutlet private weak var searchBar: UISearchBar!
    @IBOutlet private weak var settingsButton: UIBarButtonItem!
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        defaultsToCompare = DVBDefaultsManager.initialDefaultsMattersForAppReset()
        title = NSLS("TITLE_BOARDS")

        darkThemeHandler()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(darkThemeHandler),
            name: UserDefaults.didChangeNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(goToFirstController),
            name: UIContentSizeCategory.didChangeNotification,
            object: nil)
        alertGenerator = DVBAlertGenerator()
        alertGenerator?.alertGeneratorDelegate = self
        loadBoardList()

        // check if EULA accepted or not
        if !userAgreementAccepted() {
            performSegue(withIdentifier: SEGUE_TO_EULA, sender: self)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setToolbarHidden(
            true,
            animated: false)

        // Check if table have section 0.
        // Table View always have this 0 section - but it's hidden if user not added favourites.
        if tableView.numberOfRows(inSection: 0) != 0 {
            // hide search bar - we can reach it by pull gesture
            let firstRow = IndexPath(row: 0, section: 0)

            // Check if first row is existing - or otherwise app will crash
            // and Check if user scrolled table already or not
            if firstRow != nil && (tableView.contentOffset.y < MAXIMUM_SCROLL_UNTIL_SCROLL_TO_TOP_ON_APPEAR) {
                tableView.scrollToRow(
                    at: firstRow,
                    at: .top,
                    animated: false)
            }
        }
    }
    
    @objc func goToFirstController() {
        navigationController?.popToRootViewController(animated: true)
    }

    @objc func darkThemeHandler() {
        if DVBDefaultsManager.needToReset(withStoredDefaults: defaultsToCompare) {
            goToFirstController()
        }

        if UserDefaults.standard.bool(forKey: SETTING_ENABLE_DARK_THEME) {
            navigationController?.navigationBar.barStyle = .blackTranslucent
            tableView.backgroundColor = UIColor.black
            tableView.separatorColor = CELL_SEPARATOR_COLOR_BLACK
            searchBar.barStyle = .blackTranslucent
        } else {
            navigationController?.navigationBar.barStyle = .default
            tableView.backgroundColor = UIColor.white
            tableView.separatorColor = CELL_SEPARATOR_COLOR
            searchBar.barStyle = .default
        }
        updateTable()
    }

    // MARK: - Board List
    func loadBoardList() {
        boardsModel = DVBBoardsModel.shared
        boardsModel?.boardsModelDelegate = self

        tableView.dataSource = boardsModel
        tableView.delegate = boardsModel
        searchBar.delegate = boardsModel

        updateTable()
    }
    
    func addBoard(withCode code: String?) {
        if let code = code {
            boardsModel?.addBoard(withBoardId: code)
            updateTable()
        }
    }

    // MARK: - DVBBoardsModelDelegate
    func updateTable() {
        DispatchQueue.main.async(execute: { [self] in
            tableView.reloadData()
        })
    }

    func `open`(withBoardId boardId: String?, pages: Int) {
        // Cancel opening if app isn't allowed to open the board
        if !(boardsModel?.canOpenBoard(withBoardId: boardId) ?? false) {
            let alert = DVBAlertGenerator.ageCheckAlert()
            if let alert = alert {
                present(alert, animated: true)
            }
            return
        }
        if let boardId = boardId {
            DVBRouter.pushBoard(from: self, boardCode: boardId, pages: pages)
        }
    }

    func openThread(with urlNinja: UrlNinja?) {
        if let urlNinja = urlNinja, let boardId = urlNinja.boardId, let threadId = urlNinja.threadId {
            DVBRouter.pushThread(
                from: self,
                board: boardId,
                thread: threadId,
                subject: nil,
                comment: nil)
        }
    }
    
    // MARK: - user Agreement

    ///  Check EULA ccepted or not
    ///
    ///  - Returns: YES if user accepted EULA
    func userAgreementAccepted() -> Bool {
        let userAgreementAccepted = UserDefaults.standard.bool(forKey: USER_AGREEMENT_ACCEPTED)
        return userAgreementAccepted
    }

    // MARK: - Navigation
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        searchBar.endEditing(true)
        if identifier == SEGUE_TO_EULA {
            return true
        }
        return false
    }

    // MARK: - Actions
    @IBAction func showAlert(withBoardCodePrompt sender: Any) {
        // Cancel focus on Search field - or app can crash
        view.endEditing(true)
        let boardCodeAlertController = alertGenerator?.boardCodeAlert()
        if let boardCodeAlertController = boardCodeAlertController {
            present(boardCodeAlertController, animated: true)
        }
    }

    @IBAction func openSettingsApp(_ sender: Any) {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.openURL(url)
        }
    }
}

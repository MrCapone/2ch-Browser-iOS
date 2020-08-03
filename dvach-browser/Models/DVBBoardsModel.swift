//
//  DVBBoardsModel.swift
//  dvach-browser
//
//  Created by Dmitry Lukianov on 26.07.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import Foundation
import UIKit
import CoreData

private let BOARD_STORAGE_FILE_PATH = "store.data"
private let DVBBOARD_ENTITY_NAME = "DVBBoard"
private let DEFAULT_BOARDS_PLIST_FILENAME = "DefaultBoards"
private let BOARD_CATEGORIES_PLIST_FILENAME = "BoardCategories"

@objc protocol DVBBoardsModelDelegate: NSObjectProtocol {
    func updateTable()
    func `open`(withBoardId boardId: String?, pages: Int)
    func openThread(with urlNinja: UrlNinja?)
}

@objc class DVBBoardsModel: NSObject, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    // MARK: - variables
    @objc weak var boardsModelDelegate: DVBBoardsModelDelegate?
    /// Array of board categroies
    private(set) var boardCategoriesArray: [String]?
    /// All in one - cats and their boards
    private(set) var boardsDictionaryByCategories: [String : DVBBoard]?
    
    private var boardsPrivate: [DVBBoard]?
    private var allBoardsPrivate: [DVBBoard]?
    
    // Core data properties.
    private var context: NSManagedObjectContext?
    private var model: NSManagedObjectModel?
    // Wee need different store (memory) to not store boards gotten from network in DB
    private var memoryStore: NSPersistentStore?
    private var persistentStoreCoordinator: NSPersistentStoreCoordinator?
    
    static var shared = DVBBoardsModel()
    
    @objc class func sharedBoardsModel() -> DVBBoardsModel {
        return shared
    }
    
    // MARK: - Init and Core Data
    
    private override init() {
        super.init()
        
        // Read from datamodel
        self.model = NSManagedObjectModel.mergedModel(from: nil)
        
        guard let model = self.model else {
            print("DVBBoardsModel NSManagedObjectModel failure")
            fatalError()
        }
        
        self.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        
        guard let persistentStoreCoordinator = self.persistentStoreCoordinator else {
            print("DVBBoardsModel NSPersistentStoreCoordinator failure")
            fatalError()
        }
        
        // Get path for SQL file.
        guard let boardsStorageFilePath = self.boardsArchivePath() else {
            print("DVBBoardsModel failed get boardsArchivePath")
            fatalError()
        }
        
        let boardsStorageURL = URL(fileURLWithPath: boardsStorageFilePath)
        do {
            try persistentStoreCoordinator.addPersistentStore(
                ofType: NSSQLiteStoreType,
                configurationName: nil,
                at: boardsStorageURL,
                options: nil)
        } catch {
            NSException(name: NSExceptionName("OpenFailure"), reason: error.localizedDescription, userInfo: nil).raise()
        }
        
        // Create the managed object context
        self.context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        self.context?.persistentStoreCoordinator = persistentStoreCoordinator
        self.boardCategoriesArray = self.loadBoardCategoriesFromPlist()
        self.loadAllboards()
        
        guard let boardsPrivate = self.boardsPrivate else {
            print("DVBBoardsModel loadAllboards() failed")
            fatalError()
        }
        
        self.allBoardsPrivate = boardsPrivate
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(processBookmarkThreadNotification(_:)),
            name: NSNotification.Name(rawValue: NOTIFICATION_NAME_BOOKMARK_THREAD),
            object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    ///  Determining path for loading/saving array of DVBBoards to disk
    ///
    ///  - Returns: path of file to save to
    private func boardsArchivePath() -> String? {
        let documentDirectories = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).map(\.path)
        if let documentDirectory = documentDirectories.first {
            return URL(fileURLWithPath: documentDirectory).appendingPathComponent(BOARD_STORAGE_FILE_PATH).path
        }
        
        return nil
    }
    
    @discardableResult func saveChanges() -> Bool {
        var saveError: Error? = nil
        do {
            try context?.save()
        } catch {
            saveError = error
            print("Error saving: \(error.localizedDescription)")
        }
        
        return saveError == nil
    }
    
    ///  Getter method for boardsArray.
    ///
    ///  - Returns: Array of all boards in model.
    var boardsArray: [DVBBoard]? {
        get {
            return boardsPrivate
        }
    }
    
    private func loadAllboards() {
        // To prevent from "rebuilding" it
        do {
            memoryStore = try persistentStoreCoordinator?.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
        } catch {
        }
        
        guard let context = self.context else {
            print("DVBBoardsModel loadAllboards NSManagedObjectContext error")
            fatalError()
        }
        
        let request = NSFetchRequest<NSFetchRequestResult>()
        let wordEntityDescription = NSEntityDescription.entity(forEntityName: DVBBOARD_ENTITY_NAME, in: context)
        request.entity = wordEntityDescription
        let sortDescriptorByOrderKey = NSSortDescriptor(key: "boardId", ascending: true)
        request.sortDescriptors = [sortDescriptorByOrderKey]
        var result: [DVBBoard]? = nil
        do {
            result = try context.fetch(request) as? [DVBBoard]
        } catch {
            NSException(name: NSExceptionName("Fetch failed"), reason: "Reason: \(error.localizedDescription)", userInfo: nil).raise()
        }
        
        let boardsCount = result?.count ?? 0
        
        if boardsCount != 0 {
            // load from file
            boardsPrivate = result
            checkBoardNames()
        } else {
            // create first time
            boardsPrivate = []
            loadBoardsFromPlist()
        }
    }
    
    /// Add new board to user list of boards, directly to the Favourite section
    @objc func addBoard(withBoardId boardId: String) {
        guard let context = self.context else {
            print("DVBBoardsModel addBoard withBoardId NSManagedObjectContext error")
            fatalError()
        }
        
        // Constructing DVBBoard with Core Data
        let board = NSEntityDescription.insertNewObject(forEntityName: DVBBOARD_ENTITY_NAME, into: context) as? DVBBoard
        board?.boardId = boardId
        board?.name = ""
        
        // 0 - categoryId for favourite category
        let favouriteCategoryId = NSNumber(value: 0)
        board?.categoryId = favouriteCategoryId
        if let board = board {
            boardsPrivate?.append(board)
        }
        
        saveChanges()
        loadAllboards()
    }
    
    private func addBoard(withBoardId boardId: String, andBoardName name: String, andCategoryId categoryId: NSNumber) {
        guard let context = self.context else {
            print("DVBBoardsModel addBoard withBoardId andBoardName andCategoryId NSManagedObjectContext error")
            fatalError()
        }
        
        // Constructing DVBBoard with Core Data
        let board = NSEntityDescription.insertNewObject(forEntityName: DVBBOARD_ENTITY_NAME, into: context) as? DVBBoard
        board?.boardId = boardId
        board?.name = name
        board?.categoryId = categoryId
        
        if let board = board {
            boardsPrivate?.append(board)
        }
    }
    
    /// Adding favourite THREADS
    func addThread(withUrl url: String, andThreadTitle title: String) {
        guard let context = self.context else {
            print("DVBBoardsModel addThread withUrl andThreadTitle NSManagedObjectContext error")
            fatalError()
        }
        
        // Constructing DVBBoard with Core Data
        let board = NSEntityDescription.insertNewObject(forEntityName: DVBBOARD_ENTITY_NAME, into: context) as? DVBBoard
        board?.boardId = url
        board?.name = title
        
        // 0 - categoryId for favourite category
        let favouriteCategoryId = NSNumber(value: 0)
        board?.categoryId = favouriteCategoryId
        if let board = board {
            boardsPrivate?.append(board)
        }
        
        // Sort new array
        let sortDescriptorByOrderKey = NSSortDescriptor(key: "boardId", ascending: true)
        boardsPrivate = (boardsPrivate! as NSArray).sortedArray(using: [sortDescriptorByOrderKey]) as? [DVBBoard]
        
        saveChanges()
        boardsModelDelegate?.updateTable()
    }
    
    private func loadBoardsFromPlist() {
        // Get default boards from plist
        let defaultBoardsArray = NSArray(contentsOfFile: Bundle.main.path(forResource: DEFAULT_BOARDS_PLIST_FILENAME, ofType: "plist") ?? "") as? [[String: Any]]
        
        for board in defaultBoardsArray ?? [] {
            if let boardId = board["boardId"] as? String, let boardName = board["name"] as? String, let categoryId = board["categoryId"] as? NSNumber {
                addBoard(
                withBoardId: boardId,
                andBoardName: boardName,
                andCategoryId: categoryId)
            }
        }
        
        saveChanges()
        loadAllboards()
    }
    
    private func loadBoardCategoriesFromPlist() -> [String]? {
        // get category names from plist
        return NSArray(contentsOfFile: Bundle.main.path(forResource: BOARD_CATEGORIES_PLIST_FILENAME, ofType: "plist") ?? "") as? [String]
    }
    
    private func getBoardsWithCompletion(_ completion: @escaping ([DVBBoard]?) -> Void) {
        guard let context = self.context else {
            print("DVBBoardsModel getBoardsWithCompletion NSManagedObjectContext error")
            fatalError()
        }
        
        guard let memoryStore = self.memoryStore else {
            print("DVBBoardsModel getBoardsWithCompletion NSPersistentStore error")
            fatalError()
        }
        
        let networkHandler = DVBNetworking()
        networkHandler.getBoardsFromNetwork(withCompletion: { boardsDict in
            var boardsFromNetworkMutableArray = [DVBBoard]()
            for key in boardsDict?.keys ?? [:].keys {
                let boardsInsideCategory = boardsDict?[key]
                for singleBoardDictionary in boardsInsideCategory ?? [] {
                    if let boardId = singleBoardDictionary["id"] as? String, let name = singleBoardDictionary["name"] as? String, let pages = singleBoardDictionary["pages"] as? NSNumber {
                        let board = NSEntityDescription.insertNewObject(forEntityName: DVBBOARD_ENTITY_NAME, into: context) as? DVBBoard
                        if let board = board {
                            context.assign(board, to: memoryStore)
                        }
                        board?.boardId = boardId
                        board?.name = name
                        board?.pages = pages
                        
                        if let board = board {
                            boardsFromNetworkMutableArray.append(board)
                        }
                        
                        // Need to delete this temp created object or it will appear in table after realoading
                        if let board = board {
                            context.delete(board)
                        }
                    }
                }
            }
            let boardsFromNetworkArray = boardsFromNetworkMutableArray
            completion(boardsFromNetworkArray)
        })
    }
    
    func checkBoardNames() {
        var isNeedToLoadBoardsFromNetwork = false
        
        for board in boardsArray ?? [] {
            let name = board.name
            let isNameEmpty = name == ""
            if isNameEmpty {
                isNeedToLoadBoardsFromNetwork = true
                break
            }
        }
        
        if isNeedToLoadBoardsFromNetwork {
            let arrayForInterating = boardsArray
            getBoardsWithCompletion({ completion in
                var indexOfCurrentBoard = 0
                for board in arrayForInterating ?? [] {
                    let name = board.name
                    let boardId = board.boardId
                    let isNameEmpty = name == ""
                    if isNameEmpty {
                        let matchedBoardsFromNetwork = completion?.filter( { $0.boardId == boardId } )
                        let matchedBoardsCount = matchedBoardsFromNetwork?.count ?? 0
                        if let boardFromNetwork = matchedBoardsFromNetwork?[0], matchedBoardsCount > 0 {
                            let nameOfTheMatchedBoard = boardFromNetwork.name
                            let pages = boardFromNetwork.pages
                            board.name = nameOfTheMatchedBoard
                            board.pages = pages
                            self.boardsPrivate?[indexOfCurrentBoard] = board
                        }
                    }
                    indexOfCurrentBoard += 1
                }
                self.saveChanges()
                self.boardsModelDelegate?.updateTable()
            })
        }
    }
    
    // MARK: - TableView delegate & DataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return boardCategoriesArray?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as? UITableViewHeaderFooterView
        if UserDefaults.standard.bool(forKey: SETTING_ENABLE_DARK_THEME) {
            header?.textLabel?.textColor = UIColor.white
            header?.contentView.backgroundColor = CELL_SEPARATOR_COLOR_BLACK
        } else {
            header?.textLabel?.textColor = UIColor.black
            header?.contentView.backgroundColor = UIColor(red: 247.0 / 255.0, green: 247.0 / 255.0, blue: 247.0 / 255.0, alpha: 1.0)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let categoryTitle = NSLS(boardCategoriesArray?[section] ?? "")
        
        // Do not show category at all if category does not contain boards
        let isCategoryEmpty = countOfBoardsInCategory(with: section) == 0
        
        if isCategoryEmpty {
            return nil
        }
        
        return categoryTitle
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return countOfBoardsInCategory(with: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let boardCell = tableView.dequeueReusableCell(withIdentifier: BOARD_CELL_IDENTIFIER) as? DVBBoardTableViewCell
        let categoryIndex = indexPath.section
        let boardsArrayInCategory = arrayForCategory(with: categoryIndex)
        let board = boardsArrayInCategory?[indexPath.row]
        
        var boardId = board?.boardId
        
        // Cunstruct different title for threads in list (if any)
        if indexPath.section == 0 {
            let urlNinja = UrlNinja(url: URL(string: boardId ?? ""))
            if urlNinja.type == .boardThreadLink {
                boardId = "/\(urlNinja.boardId!)/\(urlNinja.threadId!)"
            }
        }
        
        boardCell?.prepare(
            withId: boardId,
            andBoardName: board?.name)
        
        return boardCell!
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Permit editing only items of the Favourite section
        let section = indexPath.section
        if section == 0 {
            return true
        }
        return false
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let change = UITableViewRowAction(
            style: .default,
            title: NSLS("BUTTON_CHANGE"),
            handler: { action, indexPath in
                self.changeAction(for: tableView, indexPath: indexPath)
        })
        change.backgroundColor = UIColor.orange
        
        let delete = UITableViewRowAction(
            style: .destructive,
            title: NSLS("BUTTON_DELETE"),
            handler: { action, indexPath in
                self.deleteAction(for: tableView, indexPath: indexPath)
        })
        return [delete, change]
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        // Method should be here even if it's empty
    }
    
    func changeAction(for tableView: UITableView, indexPath: IndexPath) {
        tableView.endEditing(true)
        let arrayForInterating = boardsPrivate
        let boardIdToDeleteFromFavourites = self.boardId(by: indexPath)
        var indexOfCurrentBoard = 0
        
        for board in arrayForInterating ?? [] {
            let boardId = board.boardId
            let boardCategoryId = board.categoryId
            let favouritesCategoryid = NSNumber(value: 0)
            let isBoardIdEquals = boardId == boardIdToDeleteFromFavourites
            let isInFavourites = boardCategoryId.intValue == favouritesCategoryid.intValue
            if isBoardIdEquals && isInFavourites {
                let alertVC = UIAlertController(title: NSLS("ALERT_CHANGE_FAVOURITE_TITLE"), message: nil, preferredStyle: .alert)
                
                alertVC.addTextField(configurationHandler: { textField in
                    textField.text = board.name
                    textField.becomeFirstResponder()
                })
                let cancelAction = UIAlertAction(
                    title: NSLS("BUTTON_CANCEL"),
                    style: .cancel,
                    handler: { action in
                        
                })
                alertVC.addAction(cancelAction)
                
                let changeAction = UIAlertAction(
                    title: NSLS("BUTTON_SAVE"),
                    style: .default,
                    handler: { action in
                        let field = alertVC.textFields?.first
                        guard let text = field?.text, !text.isEmpty else {
                            return
                        }
                        let board = self.boardsPrivate?[indexOfCurrentBoard]
                        board?.name = text
                        self.saveChanges()
                        tableView.reloadRows(at: [indexPath], with: .fade)
                })
                alertVC.addAction(changeAction)
                
                if let boardsModelDelegate = boardsModelDelegate {
                    let vc = boardsModelDelegate as? UIViewController
                    vc?.present(alertVC, animated: true)
                }
                
                break
            }
            indexOfCurrentBoard += 1
        }
    }
    
    func deleteAction(for tableView: UITableView, indexPath: IndexPath) {
        guard let context = self.context else {
            print("DVBBoardsModel deleteAction for tableView NSManagedObjectContext error")
            fatalError()
        }
        
        let arrayForInterating = boardsPrivate
        let boardIdToDeleteFromFavourites = self.boardId(by: indexPath)
        var indexOfCurrentBoard = 0
        
        for board in arrayForInterating ?? [] {
            let boardId = board.boardId
            let boardCategoryId = board.categoryId
            let favouritesCategoryid = NSNumber(value: 0)
            let isBoardIdEquals = boardId == boardIdToDeleteFromFavourites
            let isInFavourites = boardCategoryId.intValue == favouritesCategoryid.intValue
            if isBoardIdEquals && isInFavourites {
                boardsPrivate?.remove(at: indexOfCurrentBoard)
                context.delete(board)
                break
            }
            indexOfCurrentBoard += 1
        }
        saveChanges()
        
        tableView.deleteRows(at: [indexPath].compactMap { $0 }, with: .top)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let boardId = self.boardId(by: indexPath)
        let pages = boardMaxPage(by: indexPath)
        
        // Check if deal with thread bookmark and not board
        let urlNinja = UrlNinja(url: URL(string: boardId ?? ""))
        if urlNinja.type == .boardThreadLink {
            urlNinja.threadTitle = threadTitle(by: indexPath)
            boardsModelDelegate?.openThread(with: urlNinja)
        } else {
            // board
            boardsModelDelegate?.open(
                withBoardId: boardId,
                pages: pages?.intValue ?? 0)
        }
    }
    
    func boardId(by indexPath: IndexPath) -> String? {
        
        let boardsInThecategoryArray = arrayForCategory(with: indexPath.section)
        let board = boardsInThecategoryArray?[indexPath.row]
        let boardId = board?.boardId
        
        return boardId
    }
    
    func threadTitle(by indexPath: IndexPath) -> String? {
        let boardsInThecategoryArray = arrayForCategory(with: indexPath.section)
        let board = boardsInThecategoryArray?[indexPath.row]
        let threadTitle = board?.name
        
        return threadTitle
    }
    
    func boardMaxPage(by indexPath: IndexPath) -> NSNumber? {
        let boardsInThecategoryArray = arrayForCategory(with: indexPath.section)
        let board = boardsInThecategoryArray?[indexPath.row]
        return board?.pages
    }
    
    @objc func canOpenBoard(withBoardId boardId: String?) -> Bool {
        let ageCheckStatusOk = UserDefaults.standard.bool(forKey: DEFAULTS_AGE_CHECK_STATUS)
        if ageCheckStatusOk {
            return true
        }
        
        let plistPath = Bundle.main.path(
            forResource: "BadBoards",
            ofType: "plist")
        
        let badBoards = NSArray(contentsOfFile: plistPath ?? "") as? [AnyHashable]
        
        if !(badBoards?.contains(boardId ?? "") ?? false) {
            return true
        }
        
        return false
    }
    
    // MARK: - Table helpers
    func arrayForCategory(with index: Int) -> [DVBBoard]? {
        let matchedBoardsResult = boardsArray?.filter({ $0.categoryId.intValue == index })
        
        return matchedBoardsResult
    }
    
    func countOfBoardsInCategory(with index: Int) -> Int {
        let matchedBoardsResult = arrayForCategory(with: index)
        return matchedBoardsResult?.count ?? 0
    }
    
    func updateTable(withSearchText searchText: String?) {
        if let searchText = searchText {
            boardsPrivate = getArrayOfBoards(withSearchText: searchText)
        } else {
            boardsPrivate = allBoardsPrivate
        }
        boardsModelDelegate?.updateTable()
    }
    
    func getArrayOfBoards(withSearchText searchText: String) -> [DVBBoard]? {
        let fullBoarsArray = allBoardsPrivate
        let filteredArray = fullBoarsArray?.filter({
            $0.name.range(of: searchText, options: [.diacriticInsensitive, .caseInsensitive]) != nil ||
                $0.boardId.range(of: searchText, options: [.diacriticInsensitive, .caseInsensitive]) != nil })
        return filteredArray
    }
    
    // MARK: - UISearchBarDelegate
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(
            true,
            animated: true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.setShowsCancelButton(
            false,
            animated: true)
        updateTable(withSearchText: nil)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let countOfLetters = searchText.count
        let minimalCountOfCharactersToStartSearch = 1
        
        if countOfLetters >= minimalCountOfCharactersToStartSearch {
            updateTable(withSearchText: searchText)
        } else {
            updateTable(withSearchText: nil)
        }
    }
    
    // MARK: - Notifications
    @objc func processBookmarkThreadNotification(_ notification: NSNotification) {
        addThread(
            withUrl: notification.url,
            andThreadTitle: notification.title)
    }
}

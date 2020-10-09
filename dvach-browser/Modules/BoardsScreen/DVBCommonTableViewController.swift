//
//  DVBCommonTableViewController.swift
//  dvach-browser
//
//  Created by Dmitry on 09.10.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import UIKit

class DVBCommonTableViewController: UITableViewController {
    private var savedSelectedIndexPath: IndexPath?

// MARK: - Fixes for right cells deselect behaviour
    override func viewDidLoad() {
        super.viewDidLoad()
        clearsSelectionOnViewWillAppear = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        savedSelectedIndexPath = tableView.indexPathForSelectedRow
        if let savedSelectedIndexPath = savedSelectedIndexPath {
            tableView.deselectRow(at: savedSelectedIndexPath, animated: true)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        savedSelectedIndexPath = nil
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let savedSelectedIndexPath = savedSelectedIndexPath {
            tableView.selectRow(at: savedSelectedIndexPath, animated: false, scrollPosition: .none)
        }
    }
}

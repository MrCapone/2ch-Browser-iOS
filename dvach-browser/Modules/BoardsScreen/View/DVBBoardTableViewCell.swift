//
//  DVBBoardTableViewCell.swift
//  dvach-browser
//
//  Created by Dmitry on 09.10.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import UIKit

@objc class DVBBoardTableViewCell: UITableViewCell {
    @IBOutlet private weak var titleContainerView: UIView!
    @IBOutlet private weak var subtitleContainerView: UIView!
    @IBOutlet private weak var title: UILabel!
    @IBOutlet private weak var subtitle: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        resetUI()
    }
    
    @objc func prepare(withId boardId: String?, andBoardName boardName: String?) {
        let isBoardIdNotEmpty = !(boardId == "")
        if boardId != nil && isBoardIdNotEmpty {
            title.text = boardId
        }
        
        let isNameNotEmpty = !(boardName == "")
        if boardName != nil && isNameNotEmpty {
            subtitle.text = boardName
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        resetUI()
    }
    
    private func resetUI() {
        setEditing(false, animated: false)
        title.font = UIFont.preferredFont(forTextStyle: .headline)
        subtitle.font = UIFont.preferredFont(forTextStyle: .footnote)
        if UserDefaults.standard.bool(forKey: SETTING_ENABLE_DARK_THEME) {
            titleContainerView.backgroundColor = CELL_BACKGROUND_COLOR
            subtitleContainerView.backgroundColor = CELL_BACKGROUND_COLOR
            backgroundColor = CELL_BACKGROUND_COLOR
            title.textColor = CELL_TEXT_COLOR
            subtitle.textColor = CELL_TEXT_COLOR
        } else {
            titleContainerView.backgroundColor = UIColor.white
            subtitleContainerView.backgroundColor = UIColor.white
            backgroundColor = UIColor.clear
            title.textColor = UIColor.black
            subtitle.textColor = UIColor.black
        }
        
        // Need additional checkup - or labels won't update itself on change
        title.text = " "
        subtitle.text = " "
    }
}

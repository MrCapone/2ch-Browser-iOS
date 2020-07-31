//
//  DVBBoard.swift
//  dvach-browser
//
//  Created by Dmitry on 29.07.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import CoreData
import Foundation

///  Object for storing information about specific board.

public class DVBBoard: NSManagedObject {
    ///  Id of the board is simple chort code for fast forwarding to board content without scrolling board list.
    @NSManaged public var boardId: String
    ///  Name of the board, for board listing and (probably) for boardViewController's title.
    @NSManaged public var name: String
    ///  Category id of the board (boards grouped by this param in board list);
    ///  0 - favourite category
    @NSManaged public var categoryId: NSNumber
    ///  Count of total pages in the board.
    @NSManaged public var pages: NSNumber
}

//
//  DVBMediaButtonNode.swift
//  dvach-browser
//
//  Created by Dmitry on 15.10.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import AsyncDisplayKit

class DVBMediaButtonNode: ASButtonNode {
    private(set) var url: String?

    init(url: String) {
        super.init()
        self.url = url
    }
}

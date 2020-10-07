//
//  DVBAgreementViewController.swift
//  dvach-browser
//
//  Created by Dmitry on 07.10.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import UIKit

private let AGREEMENT_TEXTVIEW_VERTICAL_INSET: CGFloat = 16.0
private let AGREEMENT_TEXTVIEW_HORISONTAL_INSET: CGFloat = 12.0

class DVBAgreementViewController: UIViewController {
    @IBOutlet private weak var agreementTextView: UITextView!
    @IBOutlet private weak var acceptButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLS("TITLE_AGREEMENT")
        agreementTextView.font = UIFont.preferredFont(forTextStyle: .subheadline)
        agreementTextView.textContainerInset = UIEdgeInsets(top: AGREEMENT_TEXTVIEW_VERTICAL_INSET, left: AGREEMENT_TEXTVIEW_HORISONTAL_INSET, bottom: AGREEMENT_TEXTVIEW_VERTICAL_INSET, right: AGREEMENT_TEXTVIEW_HORISONTAL_INSET)
        acceptButton.title = NSLS("BUTTON_ACCEPT")
    }

    /// Set user Defaults - user accepted EULA.
    @IBAction func agreeAction(_ sender: Any) {
        UserDefaults.standard.set(true, forKey: USER_AGREEMENT_ACCEPTED)
        dismiss(animated: true)
    }
}

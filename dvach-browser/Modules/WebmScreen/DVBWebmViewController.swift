//
//  DVBWebmViewController.swift
//  dvach-browser
//
//  Created by Dmitry on 09.10.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import UIKit
import OGVKit
import PureLayout

class DVBWebmViewController: UIViewController, OGVPlayerDelegate {
    private var url: URL!
    private var playerView: OGVPlayerView!
    
    init(url: URL?) {
        super.init(nibName: nil, bundle: nil)
        self.url = url
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Life circle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.barStyle = .blackTranslucent
        setupCloseButton()
        playerView = OGVPlayerView(frame: view.bounds)
        playerView.translatesAutoresizingMaskIntoConstraints = false
        playerView.delegate = self
        view.addSubview(playerView)
        playerView.autoPinEdgesToSuperviewEdges()
        playerView.sourceURL = url
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playerView.play()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        playerView.pause()
    }
    
    // MARK: - Actions
    func setupCloseButton() {
        let closeItem = UIBarButtonItem(title: NSLS("BUTTON_CLOSE"), style: .plain, target: self, action: #selector(closeVC))
        navigationItem.leftBarButtonItem = closeItem
    }
    
    @objc func closeVC() {
        playerView.pause()
        dismiss(
            animated: true)
    }
    
    // MARK: - OGVPlayerDelegate
    func ogvPlayerDidEnd(_ sender: OGVPlayerView?) {
        closeVC()
    }
    
    func ogvPlayerControlsWillHide(_ sender: OGVPlayerView?) {
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    func ogvPlayerControlsWillShow(_ sender: OGVPlayerView?) {
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
}

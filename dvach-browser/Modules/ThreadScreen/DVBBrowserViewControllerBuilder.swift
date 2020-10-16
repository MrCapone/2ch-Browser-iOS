//
//  DVBBrowserViewControllerBuilder.swift
//  dvach-browser
//
//  Created by Dmitry on 16.10.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import MWPhotoBrowser

private let MIN_DURATION: Double = 0.2
private let MAX_DURATION: Double = 0.6
private let PROPORTION_TO_OVERPASS_TO_FINISH_TRANSITION: CGFloat = 5.0

class DVBBrowserViewControllerBuilder: MWPhotoBrowser, MWPhotoBrowserDelegate, UIViewControllerTransitioningDelegate {
    var pan: UIPanGestureRecognizer?

    private var index: UInt = 0
    // array of all post thumb images in thread
    private var thumbImagesArray: [String]!
    // array of all post full images in thread
    private var fullImagesArray: [String]!
    private var transitionManager: DVBGalleryTransition?
    
    func prepare(with index: UInt, andThumbImagesArray thumbImagesArray: [String], andFullImagesArray fullImagesArray: [String]) {
        self.index = index

        self.thumbImagesArray = thumbImagesArray
        self.fullImagesArray = fullImagesArray

        removeAllWebmLinks(
            fromThumbImagesArray: self.thumbImagesArray,
            andFullImagesArray: self.fullImagesArray)

        delegate = self

        displayActionButton = true
        displayNavArrows = true
        displaySelectionButtons = false
        zoomPhotosToFill = false
        alwaysShowControls = false
        enableGrid = true
        startOnGrid = false

        // Set the current visible photo before displaying
        self.setCurrentPhotoIndex(self.index)

        transitionManager = DVBGalleryTransition()
        transitioningDelegate = transitionManager

        pan = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
        view.addGestureRecognizer(pan!)
    }

    internal func numberOfPhotos(in photoBrowser: MWPhotoBrowser!) -> UInt {
        return UInt(fullImagesArray.count)
    }

    internal func photoBrowser(_ photoBrowser: MWPhotoBrowser!, photoAt index: UInt) -> MWPhotoProtocol! {
        if index < fullImagesArray.count {
            let fullImageUrl = URL(string: fullImagesArray[Int(index)])
            let mwpPhoto = MWPhoto(url: fullImageUrl)
            return mwpPhoto
        }

        return nil
    }

    internal func photoBrowser(_ photoBrowser: MWPhotoBrowser!, thumbPhotoAt index: UInt) -> MWPhotoProtocol! {
        if index < thumbImagesArray.count {
            let thumbImageUrl = URL(string: thumbImagesArray[Int(index)])
            let mwpPhoto = MWPhoto(url: thumbImageUrl)
            return mwpPhoto
        }

        return nil
    }
    
    private func removeAllWebmLinks(fromThumbImagesArray thumbImagesArray: [String]?, andFullImagesArray fullImagesArray: [String]?) {
        var thumbImagesMutableArray = thumbImagesArray
        var fullImagesMutableArray = fullImagesArray

        // start reverse loop because we need to delete objects more simplessly withour 'wrong indexes' erros
        var currentItemWhenCheckForWebm = (fullImagesArray?.count ?? 0) - 1

        if let reverse = (fullImagesArray as NSArray?)?.reverseObjectEnumerator() {
            for photoPath in reverse {
                guard let photoPath = photoPath as? String else {
                    continue
                }
                let isWebmLink = (photoPath as NSString).range(of: "webm").location != NSNotFound

                if isWebmLink {
                    thumbImagesMutableArray?.remove(at: currentItemWhenCheckForWebm)
                    fullImagesMutableArray?.remove(at: currentItemWhenCheckForWebm)

                    // decrease index of current photo to show first - because othervise we can show user the wrong one (if we delete photos with index between 0 and current index
                    if currentItemWhenCheckForWebm < index {
                        index -= 1
                    }
                }
                currentItemWhenCheckForWebm -= 1
            }
        }

        self.thumbImagesArray = thumbImagesMutableArray
        self.fullImagesArray = fullImagesMutableArray
    }

    internal override var preferredStatusBarStyle: UIStatusBarStyle {
        if UserDefaults.standard.bool(forKey: SETTING_ENABLE_DARK_THEME) {
            return .lightContent
        }

        return .default
    }
    
    // MARK: - Dismiss Transition
    @objc private func pan(_ recognizer: UIPanGestureRecognizer?) {
        if recognizer?.state == .began {
            dismiss(animated: true)
            recognizer?.setTranslation(CGPoint.zero, in: view.superview)
            transitionManager?.update(0)
            return
        }

        let percentage = (recognizer?.translation(in: view.superview).y ?? 0.0) / view.superview!.bounds.size.height

        transitionManager?.update(percentage)

        if recognizer?.state == .ended {

            let velocityY = recognizer?.velocity(in: recognizer?.view?.superview).y ?? 0.0

            // If moved up but not so far
            let isBadDistanceUp = (velocityY < 0) && (-(recognizer?.view?.frame.origin.y ?? 0.0) < view.bounds.size.height / PROPORTION_TO_OVERPASS_TO_FINISH_TRANSITION)

            // If moved down but not so far
            let isBadDistanceDown = (velocityY > 0) && ((recognizer?.view?.frame.origin.y ?? 0.0) < view.bounds.size.height / PROPORTION_TO_OVERPASS_TO_FINISH_TRANSITION)

            let cancel = isBadDistanceUp || isBadDistanceDown

            let points = (cancel ? recognizer?.view?.frame.origin.y : view.superview!.bounds.size.height - (recognizer?.view?.frame.origin.y ?? 0.0)) ?? 0.0
            var duration = TimeInterval(points / velocityY)

            if duration < MIN_DURATION {
                duration = MIN_DURATION
            } else if duration > MAX_DURATION {
                duration = MAX_DURATION
            }

            if cancel {
                transitionManager?.cancelInteractiveTransition(withDuration: CGFloat(duration))
            } else {
                var toTop = false
                if velocityY < 0 {
                    toTop = true
                }

                transitionManager?.finishInteractiveTransition(withDuration: CGFloat(duration), andToTop: toTop)
            }
        } else if recognizer?.state == .failed {
            transitionManager?.cancelInteractiveTransition(withDuration: 0.35)
        }
    }
}

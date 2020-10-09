//
//  DVBGalleryTransition.swift
//  dvach-browser
//
//  Created by Dmitry on 09.10.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import UIKit

@objc class DVBGalleryTransition: UIPercentDrivenInteractiveTransition, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate {
    @objc weak var transitionContext: UIViewControllerContextTransitioning?
    
    // MARK: - UIViewControllerTransitioningDelegate
    internal func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
    
    internal func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return self
    }
    
    // MARK: - UIViewControllerAnimatedTransitioning
    internal func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    internal func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            
        }) { finished in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
    
    internal func animationEnded(_ transitionCompleted: Bool) {
        // This here is on purpose
    }
    
    // MARK: - UIViewControllerInteractiveTransitioning
    internal override func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
    }
    
    // MARK: - UIPercentDrivenInteractiveTransition
    internal override func update(_ percentComplete: CGFloat) {
        var percentComplete = percentComplete
        if percentComplete < -1 {
            percentComplete = -1
        } else if percentComplete > 1 {
            percentComplete = 1
        }

        let toViewController = transitionContext?.viewController(forKey: .to)
        let fromViewController = transitionContext?.viewController(forKey: .from)
        var frame = toViewController?.view.frame
        frame?.origin.y = (toViewController?.view.bounds.size.height ?? 0.0) * percentComplete
        fromViewController?.view.frame = frame ?? CGRect.zero
    }
    
    @objc func cancelInteractiveTransition(withDuration duration: CGFloat) {
        let toViewController = transitionContext?.viewController(forKey: .to)
        let fromViewController = transitionContext?.viewController(forKey: .from)

        UIView.animate(
            withDuration: TimeInterval(duration),
            delay: 0,
            options: .curveEaseOut,
            animations: {
                let frame = toViewController?.view.frame
                fromViewController?.view.frame = frame ?? CGRect.zero
            }) { [self] finished in
            transitionContext?.cancelInteractiveTransition()
            transitionContext?.completeTransition(false)
                transitionContext = nil
            }

        cancel()
    }
    
    @objc func finishInteractiveTransition(withDuration duration: CGFloat, andToTop toTop: Bool) {
        let toViewController = transitionContext?.viewController(forKey: .to)
        let fromViewController = transitionContext?.viewController(forKey: .from)

        UIView.animate(
            withDuration: TimeInterval(duration),
            delay: 0,
            options: .curveEaseOut,
            animations: {
                var frame = toViewController?.view.frame
                if toTop {
                    frame?.origin.y = -(toViewController?.view.bounds.size.height ?? 0.0)
                } else {
                    frame?.origin.y = toViewController?.view.bounds.size.height ?? 0.0
                }

                fromViewController?.view.frame = frame ?? CGRect.zero
            }) { [self] finished in
                fromViewController?.view.removeFromSuperview()
            transitionContext?.completeTransition(true)
                transitionContext = nil
            }

        finish()
    }
}

//
//  VGRefreshHeaderView.swift
//  PullToRefresh
//
//  Created by Vein on 2017/9/21.
//  Copyright © 2017年 Vein. All rights reserved.
//

import UIKit

open class VGRefreshHeaderView: UIView {

    fileprivate var _state: VGRefreshViewState = .stopped
    fileprivate(set) var state: VGRefreshViewState {
        get { return _state }
        set {
            let previousValue = state
            _state = newValue
            
            if previousValue == .dragging && newValue == .animatingBounce {
                loadingIndicator?.startAnimating()
                animateBounce()
            } else if newValue == .loading && actionHandler != nil {
                actionHandler()
            } else if newValue == .animatingToStopped {
                resetScrollViewContentInset(shouldAddObserverWhenFinished: true, animated: true, completion: { [weak self] () -> () in self?.state = .stopped })
            } else if newValue == .stopped {
                loadingIndicator?.stopAnimating()
            }
        }
    }
    
    fileprivate var loadingIndicator: VGPullToRefreshLoadingIndicator?
    
    open var observing: Bool = false {
        didSet {
            if observing {
                addRefreshObserver()
            } else {
                removeRefreshObserver()
            }
        }
    }
    
    fileprivate let bounceAnimationHelperView = UIView()
    fileprivate var originalContentInsetTop: CGFloat = 0.0 { didSet { layoutSubviews() } }
    var actionHandler: (() -> Void)!
    
    init() {
        super.init(frame: .zero)
        loadingIndicator = VGPullToRefreshLoadingIndicator()
        addSubview(loadingIndicator!)
        addSubview(bounceAnimationHelperView)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        observing = false
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Layout
    fileprivate func layoutLoadingView() {
        let width = bounds.width
        let height: CGFloat = bounds.height
        
        let loadingViewSize: CGFloat = VGPullToRefreshCommon.LoadingViewSize
        let minOriginY = (VGPullToRefreshCommon.LoadingContentInset - loadingViewSize) / 2.0
        var originY: CGFloat = max(min((height - loadingViewSize) / 2.0, minOriginY), 0)
        if frame.origin.y >= 0 { originY = -loadingViewSize }
        loadingIndicator?.frame = CGRect(x: (width - loadingViewSize) / 2.0, y: originY, width: loadingViewSize, height: loadingViewSize)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        if let scrollView = scrollView(), state != .animatingBounce {
            let width = scrollView.bounds.width
            let height = currentHeight()
            frame = CGRect(x: 0.0, y: -height, width: width, height: height)
            layoutLoadingView()
        }
    }
    
    // MARK: Public Methods
    func stopLoading() {
        // Prevent stop close animation
        if state == .animatingToStopped {
            return
        }
        state = .animatingToStopped
    }
    
    // MARK: Private Methods
    fileprivate func isAnimating() -> Bool {
        return state.isAnyOf([.animatingBounce, .animatingToStopped])
    }
    
    fileprivate func actualContentOffsetY() -> CGFloat {
        guard let scrollView = scrollView() else { return 0.0 }
        return max(-scrollView.contentInset.top - scrollView.contentOffset.y, 0)
    }
    
    fileprivate func currentHeight() -> CGFloat {
        guard let scrollView = scrollView() else { return 0.0 }
        return max(-originalContentInsetTop - scrollView.contentOffset.y, 0)
    }
    
    fileprivate func scrollViewDidChangeContentOffset(dragging: Bool) {
        let offsetY = actualContentOffsetY()
        
        if state == .stopped && dragging {
            state = .dragging
        } else if state == .dragging && dragging == false {
            if offsetY >= VGPullToRefreshCommon.MinOffsetToPull {
                state = .animatingBounce
            } else {
                state = .stopped
            }
        } else if state.isAnyOf([.dragging, .stopped]) {
            let pullProgess: CGFloat = offsetY / VGPullToRefreshCommon.MinOffsetToPull
            loadingIndicator?.setPullProgress(pullProgess)
        }
    }
    
    fileprivate func resetScrollViewContentInset(shouldAddObserverWhenFinished: Bool, animated: Bool, completion: (() -> ())?) {
        guard let scrollView = scrollView() else { return }
        
        var contentInset = scrollView.contentInset
        contentInset.top = originalContentInsetTop
        
        if state == .animatingBounce {
            contentInset.top += currentHeight()
        } else if state == .loading {
            contentInset.top += VGPullToRefreshCommon.LoadingContentInset
        }
        
        scrollView.vg_removeObserver(self, forKeyPath: VGPullToRefreshCommon.KeyPaths.ContentInset)

        let animationBlock = { scrollView.contentInset = contentInset }
        let completionBlock = { () -> Void in
            if shouldAddObserverWhenFinished && self.observing {
                scrollView.vg_addObserver(self, forKeyPath: VGPullToRefreshCommon.KeyPaths.ContentInset)
            }
            completion?()
        }

        if animated {
            UIView.animate(withDuration: 0.4, animations: animationBlock, completion: { _ in
                completionBlock()
            })
        } else {
            animationBlock()
            completionBlock()
        }
    }
    
    fileprivate func animateBounce() {
        guard let scrollView = scrollView() else { return }
        if !observing { return }
        
        resetScrollViewContentInset(shouldAddObserverWhenFinished: false, animated: false, completion: nil)
        let duration = 0.5
        
        scrollView.isScrollEnabled = false
        scrollView.vg_removeObserver(self, forKeyPath: VGPullToRefreshCommon.KeyPaths.ContentOffset)
        scrollView.vg_removeObserver(self, forKeyPath: VGPullToRefreshCommon.KeyPaths.ContentInset)
        
        bounceAnimationHelperView.center = CGPoint(x: 0.0, y: originalContentInsetTop + currentHeight())
        let width = bounds.width
        UIView.animate(withDuration: duration, delay: 0.0, options: [], animations: { [weak self] in
            if let contentInsetTop = self?.originalContentInsetTop {
                self?.bounceAnimationHelperView.center = CGPoint(x: 0.0, y: contentInsetTop + VGPullToRefreshCommon.LoadingContentInset)
                if let contentInsetTop = self?.bounceAnimationHelperView.center.y {
                    scrollView.contentInset.top = contentInsetTop
                    scrollView.contentOffset.y = -scrollView.contentInset.top
                    self?.frame = CGRect(x: 0.0, y: -contentInsetTop - 1.0, width: width, height: contentInsetTop)
                }
            }
        }) { [weak self] _ in
            
            self?.resetScrollViewContentInset(shouldAddObserverWhenFinished: true, animated: false, completion: nil)
            if let strongSelf = self, let scrollView = strongSelf.scrollView() {
                scrollView.vg_addObserver(strongSelf, forKeyPath: VGPullToRefreshCommon.KeyPaths.ContentOffset)
                scrollView.isScrollEnabled = true
            }
            self?.state = .loading
        }
    }
    
    // MARK: Observer
    fileprivate func scrollView() -> UIScrollView? {
        return superview as? UIScrollView
    }
    
    fileprivate func addRefreshObserver() {
        guard let scrollView = scrollView() else { return }
        scrollView.vg_addObserver(self, forKeyPath: VGPullToRefreshCommon.KeyPaths.ContentOffset)
        scrollView.vg_addObserver(self, forKeyPath: VGPullToRefreshCommon.KeyPaths.ContentInset)
        scrollView.vg_addObserver(self, forKeyPath: VGPullToRefreshCommon.KeyPaths.Frame)
        scrollView.vg_addObserver(self, forKeyPath: VGPullToRefreshCommon.KeyPaths.PanGestureRecognizerState)
    }
    
    fileprivate func removeRefreshObserver() {
        guard let scrollView = scrollView() else { return }
        scrollView.vg_removeObserver(self, forKeyPath: VGPullToRefreshCommon.KeyPaths.ContentOffset)
        scrollView.vg_removeObserver(self, forKeyPath: VGPullToRefreshCommon.KeyPaths.ContentInset)
        scrollView.vg_removeObserver(self, forKeyPath: VGPullToRefreshCommon.KeyPaths.Frame)
        scrollView.vg_removeObserver(self, forKeyPath: VGPullToRefreshCommon.KeyPaths.PanGestureRecognizerState)
    }
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == VGPullToRefreshCommon.KeyPaths.ContentOffset {
            if let newContentOffset = change?[NSKeyValueChangeKey.newKey], let scrollView = scrollView() {
                let newContentOffsetY = (newContentOffset as AnyObject).cgPointValue.y
                if state.isAnyOf([.loading, .animatingToStopped]) && newContentOffsetY < -scrollView.contentInset.top {
                    scrollView.contentOffset.y = -scrollView.contentInset.top
                } else {
                    scrollViewDidChangeContentOffset(dragging: scrollView.isDragging)
                }
                layoutSubviews()
            }
        } else if keyPath == VGPullToRefreshCommon.KeyPaths.ContentInset {
            if let newContentInset = change?[NSKeyValueChangeKey.newKey] {
                let newContentInsetTop = (newContentInset as AnyObject).uiEdgeInsetsValue.top
                originalContentInsetTop = newContentInsetTop
            }
        } else if keyPath == VGPullToRefreshCommon.KeyPaths.Frame {
            layoutSubviews()
        } else if keyPath == VGPullToRefreshCommon.KeyPaths.PanGestureRecognizerState {
            if let gestureState = scrollView()?.panGestureRecognizer.state, gestureState.vg_isAnyOf([.ended, .cancelled, .failed]) {
                scrollViewDidChangeContentOffset(dragging: false)
            }
        }
    }
}




















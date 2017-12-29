//
//  VGRefreshFooterView.swift
//  PullToRefresh
//
//  Created by Vein on 2017/9/22.
//  Copyright © 2017年 Vein. All rights reserved.
//

import UIKit

open class VGRefreshFooterView: UIView {
    
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
                resetScrollViewContentInset(shouldAddObserverWhenFinished: true, animated: true, completion: { [weak self] () -> Void in
                    self?.state = .stopped
                    self?.scrollView()?.contentInset.bottom = 0
                })
            } else if newValue == .stopped {
                loadingIndicator?.stopAnimating()
            }
        }
    }
    
    open var loadingIndicator: UIActivityIndicatorView?
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
    fileprivate var originalContentInsetBottom: CGFloat = 0.0 { didSet { layoutSubviews() } }
    var actionHandler: (() -> Void)!
    
    init() {
        super.init(frame: .zero)
        loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        addSubview(loadingIndicator!)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Layout
    fileprivate func layoutLoadingView() {
        let width = bounds.width
        
        if scrollView() != nil {
            let loadingViewSize: CGFloat = VGPullToRefreshCommon.LoadingViewSize
            loadingIndicator?.frame = CGRect(x: (width - loadingViewSize) / 2.0, y: 0, width: loadingViewSize, height: loadingViewSize)
            loadingIndicator?.center.y = VGPullToRefreshCommon.LoadingContentInset / 2
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        if let scrollView = scrollView(), state != .animatingBounce {
            let width = scrollView.bounds.width
            let height = scrollView.contentSize.height > 0 ? currentHeight() : 0
            frame = CGRect(x: 0.0, y: scrollView.contentSize.height, width: width, height: height)
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
        //        return max((scrollView.contentInset.bottom + scrollView.contentOffset.y) - (scrollView.contentSize.height - scrollView.bounds.height), 0)
        return max(scrollView.contentSize.height - scrollView.contentOffset.y + scrollView.contentInset.bottom, 0)
    }
    
    fileprivate func currentHeight() -> CGFloat {
        guard let scrollView = scrollView() else { return 0.0 }
        return max((originalContentInsetBottom + scrollView.contentOffset.y) - (scrollView.contentSize.height - scrollView.bounds.height), 0)
    }
    
    fileprivate func scrollViewDidChangeContentOffset(dragging: Bool) {
        guard let scrollView = scrollView() else { return }
        let offsetY = actualContentOffsetY()
        
        if state == .stopped && dragging {
            state = .dragging
        } else if state == .dragging {
            if offsetY <= scrollView.bounds.size.height {
                state = .animatingBounce
            } else {
                state = .stopped
            }
        } else if state.isAnyOf([.dragging, .stopped]) {
            
        }
    }
    
    fileprivate func resetScrollViewContentInset(shouldAddObserverWhenFinished: Bool, animated: Bool, completion: (() -> Void)?) {
        guard let scrollView = scrollView() else { return }
        
        var contentInset = scrollView.contentInset
        contentInset.bottom = originalContentInsetBottom
        if state == .animatingBounce {
            contentInset.bottom += currentHeight()
        } else if state == .loading || state == .animatingToStopped {
            contentInset.bottom += VGPullToRefreshCommon.LoadingContentInset
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
        
        bounceAnimationHelperView.center = CGPoint(x: 0.0, y: scrollView.contentSize.height + currentHeight())
        let width = bounds.width
        UIView.animate(withDuration: duration, delay: 0.0, options: [], animations: { [weak self] in
            if let contentInsetBottom = self?.originalContentInsetBottom {
                self?.bounceAnimationHelperView.center = CGPoint(x: 0.0, y: scrollView.contentSize.height + contentInsetBottom + VGPullToRefreshCommon.LoadingContentInset)
                if let contentInsetBottom = self?.bounceAnimationHelperView.center.y {
                    scrollView.contentInset.bottom = contentInsetBottom - scrollView.contentSize.height
                    scrollView.contentOffset.y += scrollView.contentInset.bottom
                    self?.frame = CGRect(x: 0.0, y: scrollView.contentSize.height, width: width, height: contentInsetBottom - scrollView.contentSize.height)
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
                if newContentOffsetY <= 0 { return }
                if state.isAnyOf([.loading, .animatingToStopped]) && newContentOffsetY < (scrollView.contentInset.bottom + (scrollView.contentSize.height - scrollView.bounds.height)) {
                    
                } else {
                    scrollViewDidChangeContentOffset(dragging: scrollView.isDragging)
                }
                layoutSubviews()
            }
        } else if keyPath == VGPullToRefreshCommon.KeyPaths.ContentInset {
            if let newContentInset = change?[NSKeyValueChangeKey.newKey] {
                let newContentInsetTop = (newContentInset as AnyObject).uiEdgeInsetsValue.bottom
                originalContentInsetBottom = newContentInsetTop
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


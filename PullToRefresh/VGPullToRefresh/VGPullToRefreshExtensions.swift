//
//  VGPullToRefreshExtensions.swift
//  PullToRefresh
//
//  Created by Vein on 2017/9/21.
//  Copyright © 2017年 Vein. All rights reserved.
//

import UIKit
import ObjectiveC

// MARK: NSObject Extension
public extension NSObject {
    fileprivate struct vg_associatedKeys {
        static var observersArray = "observers"
    }
    
    // runtime  NSObject添加 Refresh所需要监听的字典
    fileprivate var vg_observers: [[String : NSObject]] {
        get {
            if let observers = objc_getAssociatedObject(self, &vg_associatedKeys.observersArray) as? [[String : NSObject]] {
                return observers
            } else {
                let observers = [[String : NSObject]]()
                self.vg_observers = observers
                return observers
            }
        }
        set {
            objc_setAssociatedObject(self, &vg_associatedKeys.observersArray, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public func vg_addObserver(_ observer: NSObject, forKeyPath keyPath: String) {
        let observerInfo = [keyPath : observer]
        
        if vg_observers.index(where: { $0 == observerInfo }) == nil {
            vg_observers.append(observerInfo)
            addObserver(observer, forKeyPath: keyPath, options: .new, context: nil)
        }
    }
    
    public func vg_removeObserver(_ observer: NSObject, forKeyPath keyPath: String) {
        let observerInfo = [keyPath : observer]
        
        if let index = vg_observers.index(where: { $0 == observerInfo }) {
            vg_observers.remove(at: index)
            removeObserver(observer, forKeyPath: keyPath)
        }
    }
}

// MARK: UIScrollView Extension
public extension UIScrollView {
    // 刷新头视图 & 下拉更多尾视图
    fileprivate struct vg_associatedKeys {
        static var refreshHeaderView = "VGRefreshHeaderView"
        static var refreshFooterView = "VGRefreshFooterView"
    }
    
    fileprivate var refreshHeaderView: VGRefreshHeaderView? {
        get {
            return objc_getAssociatedObject(self, &vg_associatedKeys.refreshHeaderView) as? VGRefreshHeaderView
        }
        
        set {
            objc_setAssociatedObject(self, &vg_associatedKeys.refreshHeaderView, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    fileprivate var refreshFooterView: VGRefreshFooterView? {
        get {
            return objc_getAssociatedObject(self, &vg_associatedKeys.refreshFooterView) as? VGRefreshFooterView
        }
        
        set {
            objc_setAssociatedObject(self, &vg_associatedKeys.refreshFooterView, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /* 添加下拉刷新 */
    public func vg_addPullToRefresh(actionHandler: @escaping () -> Void) {
        isMultipleTouchEnabled = false
        panGestureRecognizer.maximumNumberOfTouches = 1
        
        let refreshHeaderView = VGRefreshHeaderView()
        self.refreshHeaderView = refreshHeaderView
        refreshHeaderView.actionHandler = actionHandler
        addSubview(refreshHeaderView)

        refreshHeaderView.observing = true
    }
    
    /* 添加尾部加载更多 */
    public func vg_addInfiniteScrolling(actionHandler: @escaping () -> Void) {
        isMultipleTouchEnabled = false
        panGestureRecognizer.maximumNumberOfTouches = 1
        
        let refreshFooterView = VGRefreshFooterView()
        self.refreshFooterView = refreshFooterView
        refreshFooterView.actionHandler = actionHandler
        addSubview(refreshFooterView)
        
        refreshFooterView.observing = true
    }
    
    public func vg_headerIndicatorTintColor(tintColor: UIColor) {
        refreshHeaderView?.loadingIndicator?.tintColor = tintColor
    }
    
    public func vg_stopLoading() {
        refreshHeaderView?.stopLoading()
    }
    
    public func vg_stopMore() {
        refreshFooterView?.stopLoading()
    }
    
    public func vg_removePullToRefresh() {
        refreshHeaderView?.observing = false
        refreshHeaderView?.removeFromSuperview()
        refreshHeaderView = nil
    }
    
    public func vg_removeInfiniteScrolling() {
        refreshFooterView?.observing = false
        refreshFooterView?.removeFromSuperview()
        refreshFooterView = nil
    }
    
    public func vg_setPullToRefreshBackgroundColor(_ color: UIColor) {
        refreshHeaderView?.backgroundColor = color
    }
    
    public func vg_setInfiniteScrollingBackgroundColor(_ color: UIColor) {
        refreshFooterView?.backgroundColor = color
    }
    
    public func vg_pullToRefreshStopLoading() {
        refreshHeaderView?.stopLoading()
    }
    
    public func vg_infiniteScrollingStopLoading() {
        refreshFooterView?.stopLoading()
    }
    
}

// MARK: UIView Extension

public extension UIView {
    func vg_center(_ usePresentationLayerIfPossible: Bool) -> CGPoint {
        if usePresentationLayerIfPossible, let presentationLayer = layer.presentation() {
            // Position can be used as a center, because anchorPoint is (0.5, 0.5)
            return presentationLayer.position
        }
        return center
    }
}

// MARK: UIGestureRecognizerState Extension

public extension UIGestureRecognizerState {
    func vg_isAnyOf(_ values: [UIGestureRecognizerState]) -> Bool {
        return values.contains(where: { $0 == self })
    }
}

//
//  VGPullToRefreshExtensions.swift
//  PullToRefresh
//
//  Created by Vein on 2017/9/21.
//  Copyright © 2017年 Vein. All rights reserved.
//

import UIKit
import ObjectiveC

public protocol VGExtensionsProvider {
    associatedtype CompatibleType
    var vg: CompatibleType { get }
}

extension UIScrollView: VGExtensionsProvider {}

extension VGExtensionsProvider {
    public var vg: VG<Self> {
        return VG(self)
    }
    
}

public struct VG<Base> {
    public let base: Base
    
    fileprivate init(_ base: Base) {
        self.base = base
    }
}

// MARK: NSObject Extension
public extension NSObject {
    fileprivate struct VGAssociatedKeys {
        static var observersArray = "observers"
    }
    
    // runtime  NSObject添加 Refresh所需要监听的字典
    fileprivate var vg_observers: [[String : NSObject]] {
        get {
            if let observers = objc_getAssociatedObject(self, &VGAssociatedKeys.observersArray) as? [[String : NSObject]] {
                return observers
            } else {
                let observers = [[String : NSObject]]()
                self.vg_observers = observers
                return observers
            }
        }
        set {
            objc_setAssociatedObject(self, &VGAssociatedKeys.observersArray, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
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

public extension VG where Base: UIScrollView {
    /* 添加下拉刷新 */
    public func addPullToRefresh(actionHandler: @escaping () -> Void) {
        base.isMultipleTouchEnabled = false
        base.panGestureRecognizer.maximumNumberOfTouches = 1
        
        let refreshHeaderView = VGRefreshHeaderView()
        base.refreshHeaderView = refreshHeaderView
        refreshHeaderView.actionHandler = actionHandler
        base.addSubview(refreshHeaderView)
        
        refreshHeaderView.observing = true
    }
    
    /* 添加尾部加载更多 */
    public func addInfiniteScrolling(actionHandler: @escaping () -> Void) {
        base.isMultipleTouchEnabled = false
        base.panGestureRecognizer.maximumNumberOfTouches = 1
        
        let refreshFooterView = VGRefreshFooterView()
        base.refreshFooterView = refreshFooterView
        refreshFooterView.actionHandler = actionHandler
        base.addSubview(refreshFooterView)
        
        refreshFooterView.observing = true
    }
    
    public func headerIndicatorTintColor(tintColor: UIColor) {
        base.refreshHeaderView?.loadingIndicator?.tintColor = tintColor
    }
    
    public func stopLoading() {
        base.refreshHeaderView?.stopLoading()
    }
    
    public func stopMoreLoding() {
        base.refreshFooterView?.stopLoading()
    }
    
    public func removePullToRefresh() {
        base.refreshHeaderView?.observing = false
        base.refreshHeaderView?.removeFromSuperview()
        base.refreshHeaderView = nil
    }
    
    public func removeInfiniteScrolling() {
        base.refreshFooterView?.observing = false
        base.refreshFooterView?.removeFromSuperview()
        base.refreshFooterView = nil
    }
    
    public func setPullToRefreshBackgroundColor(_ color: UIColor) {
        base.refreshHeaderView?.backgroundColor = color
    }
    
    public func setInfiniteScrollingBackgroundColor(_ color: UIColor) {
        base.refreshFooterView?.backgroundColor = color
    }
    
    public func pullToRefreshStopLoading() {
        base.refreshHeaderView?.stopLoading()
    }
    
    public func infiniteScrollingStopLoading() {
        base.refreshFooterView?.stopLoading()
    }
}

// MARK: UIScrollView Extension
public extension UIScrollView {
    // 刷新头视图 & 下拉更多尾视图
    fileprivate struct VGAssociatedKeys {
        static var refreshHeaderView = "VGRefreshHeaderView"
        static var refreshFooterView = "VGRefreshFooterView"
    }
    
    fileprivate var refreshHeaderView: VGRefreshHeaderView? {
        get {
            return objc_getAssociatedObject(self, &VGAssociatedKeys.refreshHeaderView) as? VGRefreshHeaderView
        }
        
        set {
            objc_setAssociatedObject(self, &VGAssociatedKeys.refreshHeaderView, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    fileprivate var refreshFooterView: VGRefreshFooterView? {
        get {
            return objc_getAssociatedObject(self, &VGAssociatedKeys.refreshFooterView) as? VGRefreshFooterView
        }
        
        set {
            objc_setAssociatedObject(self, &VGAssociatedKeys.refreshFooterView, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
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


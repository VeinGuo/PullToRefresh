//
//  VGRefreshHeaderView.swift
//  PullToRefresh
//
//  Created by Vein on 2017/9/21.
//  Copyright © 2017年 Vein. All rights reserved.
//

import UIKit

open class VGRefreshHeaderView: UIView {

    fileprivate(set) var state: VGRefreshViewState = .stopped
    
    fileprivate var loadingIndicator: VGPullToRefreshLoadingIndicator? {
        willSet {
            loadingIndicator?.removeFromSuperview()
            if let newValue = newValue {
                addSubview(newValue)
            }
        }
    }
    
    open var observing: Bool = false {
        didSet {
            
        }
    }
    var actionHandler: (() -> Void)!
    
    init() {
        state = .stopped
        super.init(frame: .zero)
        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Public Methods
    func stopLoading() {
        // Prevent stop close animation
        if state == .animatingToStopped {
            return
        }
        state = .animatingToStopped
    }
}

//
//  VGPullToRefreshCommon.swift
//  PullToRefresh
//
//  Created by Vein on 2017/9/21.
//  Copyright © 2017年 Vein. All rights reserved.
//

import UIKit
import Foundation

public enum VGRefreshViewState {
    case stopped
    case dragging
    case animatingBounce
    case loading
    case animatingToStopped
    
    func isAnyOf(_ values: [VGRefreshViewState]) -> Bool {
        return values.contains(where: { $0 == self })
    }
}

public struct VGPullToRefreshCommon {
    struct KeyPaths {
        static let ContentOffset = "contentOffset"
        static let ContentInset = "contentInset"
        static let Frame = "frame"
        static let PanGestureRecognizerState = "panGestureRecognizer.state"
    }
    
    public static var MinOffsetToPull: CGFloat = 95.0
    public static var LoadingContentInset: CGFloat = 50.0
    public static var LoadingViewSize: CGFloat = 30.0
}


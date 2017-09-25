//
//  VGPullToRefreshLoadingIndicator.swift
//  PullToRefresh
//
//  Created by Vein on 2017/9/21.
//  Copyright © 2017年 Vein. All rights reserved.
//

import UIKit

open class VGPullToRefreshLoadingIndicator: UIView {
    
    fileprivate let kRotationAnimationKey = "kRotationAnimationKey.rotation"
    
    fileprivate let indicatorLayer = CAShapeLayer()
    fileprivate var timingFunction = CAMediaTimingFunction()
    fileprivate lazy var identityTransform: CATransform3D = {
        var transform = CATransform3DIdentity
        transform.m34 = CGFloat(1.0 / -500.0)
        transform = CATransform3DRotate(transform, CGFloat(-90.0).toRadians(), 0.0, 0.0, 1.0)
        return transform
    }()
    
    init() {
        super.init(frame: .zero)
        commonInit()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    override open func layoutSubviews() {
        super.layoutSubviews()
        indicatorLayer.frame = bounds
        updateIndicatorLayerPath()
    }
    
    internal func commonInit(){
        timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        setupIndicatorLayer()
        
    }
    
    internal func setupIndicatorLayer() {
        indicatorLayer.strokeColor = UIColor.black.cgColor
        indicatorLayer.fillColor = UIColor.clear.cgColor
        indicatorLayer.lineWidth = 1.0
        indicatorLayer.lineJoin = kCALineJoinRound;
        indicatorLayer.lineCap = kCALineCapRound;
        indicatorLayer.actions = ["strokeEnd" : NSNull(), "transform" : NSNull()]
        layer.addSublayer(indicatorLayer)
        updateIndicatorLayerPath()
    }
    
    internal func updateIndicatorLayerPath() {
        let center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        let radius = min(self.bounds.width / 2, self.bounds.height / 2) - indicatorLayer.lineWidth / 2
        let startAngle: CGFloat = 0
        let endAngle: CGFloat = 2 * CGFloat(Double.pi)
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        indicatorLayer.path = path.cgPath
    }
    
    open func setPullProgress(_ progress: CGFloat) {
        indicatorLayer.strokeEnd = min(0.9 * progress, 0.9)
        
        // 超过1.0进度 让indicator 旋转
        if progress > 1.0 {
            let degrees = ((progress - 1.0) * 200.0)
            indicatorLayer.transform = CATransform3DRotate(identityTransform, degrees.toRadians(), 0.0, 0.0, 1.0)
        } else {
            indicatorLayer.transform = identityTransform
        }
    }
    
    open func startAnimating() {
        if indicatorLayer.animation(forKey: kRotationAnimationKey) != nil { return }
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.duration = 1.0
        animation.fromValue = 0
        animation.toValue = (2 * Double.pi)
        animation.repeatCount = Float.infinity
        animation.isRemovedOnCompletion = false
        indicatorLayer.add(animation, forKey: kRotationAnimationKey)
    }
    
    open func stopAnimating() {
        indicatorLayer.strokeEnd = 0.0
        indicatorLayer.removeAnimation(forKey: kRotationAnimationKey)
    }
}

public extension CGFloat {
    
    public func toRadians() -> CGFloat {
        return (self * CGFloat(Double.pi)) / 180.0
    }
    
    public func toDegrees() -> CGFloat {
        return self * 180.0 / CGFloat(Double.pi)
    }
    
}


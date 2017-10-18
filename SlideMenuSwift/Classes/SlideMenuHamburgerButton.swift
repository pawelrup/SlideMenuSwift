//
//  SlideMenuHamburgerButton.swift
//
//  Created by Paweł Rup on 26.07.2017.
//  Copyright © 2017 lobocode. All rights reserved.
//

import UIKit
import CoreGraphics

public enum SlideMenuHamburgerButtonMode {
    case hambuger
    case arrow
    case cross
}

private let middleLayerScaleFactor: CGFloat = 0.8

public class SlideMenuHamburgerButton: UIButton {
    
    private var topLayer: CAShapeLayer!
    private var middleLayer: CAShapeLayer!
    private var bottomLayer: CAShapeLayer!
    private var lastBounds: CGRect!

    public var lineHeight: CGFloat = 1.5
    public var lineWidth: CGFloat = 24
    public var lineSpacing: CGFloat = 3.5
    public var lineColor: UIColor = .white
    public var animationDuration: CFTimeInterval = 0.3
    public private (set) var currentMode: SlideMenuHamburgerButtonMode = .hambuger
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.updateAppearance()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.updateAppearance()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if !self.lastBounds.equalTo(self.bounds) {
            self.updateAppearance()
        }
    }
    
    public func set(currentMode newMode: SlideMenuHamburgerButtonMode) {
        guard newMode != self.currentMode else { return }
        self.currentMode = newMode
        self.updateAppearance()
    }
    
    public func set(currentMode newMode: SlideMenuHamburgerButtonMode, animationDuration duration: CFTimeInterval? = nil) {
        guard newMode != self.currentMode else { return }
        
        switch self.currentMode {
        case .hambuger:
            switch newMode {
            case .hambuger:
                break
            case .arrow:
                self.transformFromHamburgerToArrow(duration: duration ?? self.animationDuration)
            case .cross:
                self.transformFromHamburgerToCross(duration: duration ?? self.animationDuration)
            }
        case .arrow:
            switch newMode {
            case .hambuger:
                self.transformFromArrowToHamburger(duration: duration ?? self.animationDuration)
            case .arrow:
                break
            case .cross:
                self.transformFromArrowToCross(duration: duration ?? self.animationDuration)
            }
        case .cross:
            switch newMode {
            case .hambuger:
                self.transformFromCrossToHamburger(duration: duration ?? self.animationDuration)
            case .arrow:
                self.transformFromCrossToArrow(duration: duration ?? self.animationDuration)
            case .cross:
                break
            }
        }
    }
    
    public func updateAppearance() {
        self.lastBounds = self.bounds
        self.topLayer?.removeFromSuperlayer()
        self.middleLayer?.removeFromSuperlayer()
        self.bottomLayer?.removeFromSuperlayer()
        
        let x = self.frame.width / 2
        
        let topY = (self.frame.height / 2) - self.lineHeight - self.lineSpacing
        self.topLayer = self.createLayer()
        self.topLayer.position = CGPoint(x: x , y: topY)
        
        let middleY = self.frame.height / 2
        self.middleLayer = self.createLayer()
        self.middleLayer.position = CGPoint(x: x , y: middleY)
        
        let bottomY = (self.frame.height / 2) + self.lineHeight + self.lineSpacing
        self.bottomLayer = self.createLayer()
        self.bottomLayer.position = CGPoint(x: x , y: bottomY)
        
        switch self.currentMode {
        case .hambuger:
            self.transformModeHamburger()
        case .arrow:
            self.transformModeArrow()
        case .cross:
            self.transformModeCross()
        }
    }
    
    private func createLayer() -> CAShapeLayer {
        let layer = CAShapeLayer()
        
        let path = UIBezierPath()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: self.lineWidth, y: 0))
        
        layer.path = path.cgPath
        layer.lineWidth = self.lineWidth
        layer.strokeColor = self.lineColor.cgColor
        
        let bound = CGPath(__byStroking: layer.path!, transform: nil, lineWidth: layer.lineWidth, lineCap: .butt, lineJoin: .miter, miterLimit: layer.miterLimit)!
        layer.bounds = bound.boundingBox
        
        self.layer.addSublayer(layer)
        
        return layer
    }
    
    private func transformModeHamburger() {
        self.topLayer.transform = CATransform3DIdentity
        self.middleLayer.transform = CATransform3DIdentity
        self.bottomLayer.transform = CATransform3DIdentity
    }
    
    private func transformModeArrow() {
        
        // MARK: Top layer transform
        
        let topAngle: CGFloat = .pi + (.pi/4)
        let topScaleFactor: CGFloat = 0.5
        var topTransform = CATransform3DIdentity
        
        // Translate to bottom position
        var translateTopX: CGFloat = 0
        var translateTopY: CGFloat = (self.middleLayer.position.y + (self.lineWidth / 2)) - self.topLayer.position.y
        
        // Translate for 45 degres rotation
        translateTopX += (1 - CGFloat(fabs(Double(cosf(Float(topAngle)))))) * self.lineWidth / 2 * -1 * (1 / topScaleFactor)
        translateTopY += (1 - CGFloat(fabs(Double(sinf(Float(topAngle)))))) * self.lineWidth / 2 * -1 * (1 / topScaleFactor)
        
        // Hack
        translateTopX -= 1
        translateTopY -= 1
        
        topTransform = CATransform3DTranslate(topTransform, translateTopX, translateTopY, 0)
        topTransform = CATransform3DRotate(topTransform, topAngle, 0, 0, 1)
        topTransform = CATransform3DScale(topTransform, topScaleFactor, 1, 1)
        
        self.topLayer.transform = topTransform
        
        // MARK: Middle layer transform
        
        let middleScaleFactor = middleLayerScaleFactor
        var middleTransform = CATransform3DIdentity
        
        middleTransform = CATransform3DRotate(middleTransform, .pi, 0, 0, 1)
        middleTransform = CATransform3DScale(middleTransform, middleScaleFactor, 1, 1)
        middleTransform = CATransform3DTranslate(middleTransform, (1 - middleScaleFactor) * self.lineWidth / 2, 0, 0)
        
        self.middleLayer.transform = middleTransform
        
        // MARK: Bottom layer transform
        
        let bottomAngle: CGFloat = .pi - (.pi/4)
        let bottomScaleFactor: CGFloat = 0.5
        var bottomTransform = CATransform3DIdentity
        
        // Translate to bottom position
        var translateBottomX: CGFloat = 0
        var translateBottomY: CGFloat = (self.middleLayer.position.y - (self.lineWidth / 2)) - self.topLayer.position.y
        
        // Translate for 45 degres rotation
        translateBottomX += (1 - CGFloat(fabs(Double(cosf(Float(bottomAngle)))))) * self.lineWidth / 2 * -1 * (1 / bottomScaleFactor)
        translateBottomY += (1 - CGFloat(fabs(Double(sinf(Float(bottomAngle)))))) * self.lineWidth / 2 * (1 / bottomScaleFactor)
        
        // Hack
        translateBottomX -= 1
        translateBottomY += 1
        
        bottomTransform = CATransform3DTranslate(bottomTransform, translateBottomX, translateBottomY, 0)
        bottomTransform = CATransform3DRotate(bottomTransform, bottomAngle, 0, 0, 1)
        bottomTransform = CATransform3DScale(bottomTransform, bottomScaleFactor, 1, 1)
        
        self.bottomLayer.transform = bottomTransform
    }
    
    private func transformModeCross() {
        
        // MARK: Top layer transform
        let topAngle: CGFloat = .pi/4
        let translateTopY: CGFloat = self.middleLayer.position.y + self.topLayer.position.y
        
        var topTransform = CATransform3DIdentity
        topTransform = CATransform3DTranslate(topTransform, 0, translateTopY, 0)
        topTransform = CATransform3DRotate(topTransform, topAngle, 0, 0, 1)
        
        self.topLayer.transform = topTransform
        
        // MARK: Middle layer transform
        
        var middleTransform = CATransform3DIdentity
        middleTransform = CATransform3DScale(middleTransform, 0, 1, 1)
        self.middleLayer.transform = middleTransform
        
        // MARK: Bottom layer transform
        
        let bottomAngle: CGFloat = -(.pi/4)
        let translateBottomY: CGFloat = self.middleLayer.position.y - self.bottomLayer.position.y
        
        var bottomTransform = CATransform3DIdentity
        bottomTransform = CATransform3DTranslate(bottomTransform, 0, translateBottomY, 0)
        bottomTransform = CATransform3DRotate(bottomTransform, bottomAngle, 0, 0, 1)
        
        self.bottomLayer.transform = bottomTransform
    }
    
    // MARK: - Transform with animation
    
    private func transformFromHamburgerToArrow(duration: CFTimeInterval) {
        let animationTop = self.createKeyFrameAnimation(withDuration: duration)
        animationTop.values = self.hamburgerToArrowValuesTopLayer()
        self.topLayer.add(animationTop, forKey: "transform")
            
        let animationMiddle = self.createKeyFrameAnimation(withDuration: duration)
        animationMiddle.values = self.hamburgerToArrowValuesMiddleLayer()
        self.middleLayer.add(animationMiddle, forKey: "transform")
        
        let animationBottom = self.createKeyFrameAnimation(withDuration: duration)
        animationBottom.values = self.hamburgerToArrowValuesBottomLayer()
        self.bottomLayer.add(animationBottom, forKey: "transform")
    }
    
    private func transformFromHamburgerToCross(duration: CFTimeInterval) {
        let animationTop = self.createKeyFrameAnimation(withDuration: duration)
        animationTop.values = self.hamburgerToCrossValuesTopLayer()
        self.topLayer.add(animationTop, forKey: "transform")
        
        let animationMiddle = self.createKeyFrameAnimation(withDuration: duration)
        animationMiddle.values = self.hamburgerToCrossValuesMiddleLayer()
        self.middleLayer.add(animationMiddle, forKey: "transform")
        
        let animationBottom = self.createKeyFrameAnimation(withDuration: duration)
        animationBottom.values = self.hamburgerToCrossValuesBottomLayer()
        self.bottomLayer.add(animationBottom, forKey: "transform")
    }
    
    private func transformFromArrowToHamburger(duration: CFTimeInterval) {
        let animationTop = self.createKeyFrameAnimation(withDuration: duration)
        animationTop.values = self.hamburgerToArrowValuesTopLayer()
        self.topLayer.add(animationTop, forKey: "transform")
        
        let animationMiddle = self.createKeyFrameAnimation(withDuration: duration)
        animationMiddle.values = self.hamburgerToArrowValuesMiddleLayer()
        self.middleLayer.add(animationMiddle, forKey: "transform")
        
        let animationBottom = self.createKeyFrameAnimation(withDuration: duration)
        animationBottom.values = self.hamburgerToArrowValuesBottomLayer()
        self.bottomLayer.add(animationBottom, forKey: "transform")
    }
    
    private func transformFromArrowToCross(duration: CFTimeInterval) {
        let animationTop = self.createKeyFrameAnimation(withDuration: duration)
        animationTop.values = self.arrowToCrossValuesTopLayer()
        self.topLayer.add(animationTop, forKey: "transform")
        
        let animationMiddle = self.createKeyFrameAnimation(withDuration: duration)
        animationMiddle.values = self.arrowToCrossValuesMiddleLayer()
        self.middleLayer.add(animationMiddle, forKey: "transform")
        
        let animationBottom = self.createKeyFrameAnimation(withDuration: duration)
        animationBottom.values = self.arrowToCrossValuesBottomLayer()
        self.bottomLayer.add(animationBottom, forKey: "transform")
    }
    
    private func transformFromCrossToHamburger(duration: CFTimeInterval) {
        let animationTop = self.createKeyFrameAnimation(withDuration: duration)
        animationTop.values = self.hamburgerToCrossValuesTopLayer().reversed()
        self.topLayer.add(animationTop, forKey: "transform")
        
        let animationMiddle = self.createKeyFrameAnimation(withDuration: duration)
        animationMiddle.values = self.hamburgerToCrossValuesMiddleLayer().reversed()
        self.middleLayer.add(animationMiddle, forKey: "transform")
        
        let animationBottom = self.createKeyFrameAnimation(withDuration: duration)
        animationBottom.values = self.hamburgerToCrossValuesBottomLayer().reversed()
        self.bottomLayer.add(animationBottom, forKey: "transform")
    }
    
    private func transformFromCrossToArrow(duration: CFTimeInterval) {
        let animationTop = self.createKeyFrameAnimation(withDuration: duration)
        animationTop.values = self.arrowToCrossValuesTopLayer().reversed()
        self.topLayer.add(animationTop, forKey: "transform")
        
        let animationMiddle = self.createKeyFrameAnimation(withDuration: duration)
        animationMiddle.values = self.arrowToCrossValuesTopLayer().reversed()
        self.middleLayer.add(animationMiddle, forKey: "transform")
        
        let animationBottom = self.createKeyFrameAnimation(withDuration: duration)
        animationBottom.values = self.arrowToCrossValuesTopLayer().reversed()
        self.bottomLayer.add(animationBottom, forKey: "transform")
    }
    
    // MARK: -
    
    private func createKeyFrameAnimation(withDuration duration: CFTimeInterval) -> CAKeyframeAnimation {
        let animation = CAKeyframeAnimation(keyPath: "transform")
        animation.duration = duration
        animation.isRemovedOnCompletion = true
        animation.fillMode = kCAFillModeForwards
        return animation
    }
    
    // MARK: - Hamburger / Arrow
    
    private func hamburgerToArrowValuesTopLayer() -> [NSValue] {
        
        let numberOfValues = 4
        
        let startScaleFactor: CGFloat = 1
        let endScaleFactor: CGFloat = 0.5
        
        let endAngle: CGFloat = .pi + (.pi/4)
        
        var values: [NSValue] = []
        
        for i in 0 ..< numberOfValues {
            let angle = endAngle / CGFloat((numberOfValues - 1) * i)
            let scaleFactor = startScaleFactor + (endScaleFactor - startScaleFactor) * CGFloat(i) / (CGFloat(numberOfValues) - 1)
            
            var transform = CATransform3DIdentity
            
            // Translate to bottom position
            var translateX: CGFloat = 0
            var translateY = (self.middleLayer.position.y + (self.lineWidth / 2)) - self.topLayer.position.y
            // Translate for 45 degres rotation
            translateX += (1 - CGFloat(fabs(Double(cosf(Float(endAngle)))))) * self.lineWidth / 2 * -1 * (1 / endScaleFactor)
            translateY += (1 - CGFloat(fabs(Double(sinf(Float(endAngle)))))) * self.lineWidth / 2 * -1 * (1 / endScaleFactor)
            // Hack
            translateX -= 1
            translateY -= 1
            
            translateX *= CGFloat(i) / CGFloat(numberOfValues - 1)
            translateY *= CGFloat(i) / CGFloat(numberOfValues - 1)
            // Hack avoiding topLayer cross middleLayer
            if i == 1 {
                translateX += self.lineWidth * 1 / 4
                translateY += self.lineWidth * 1 / 8
            } else if i == 2 {
                translateX += self.lineWidth * 1 / 4
                translateY += self.lineWidth * 1 / 8
            }
            
            transform = CATransform3DTranslate(transform, translateX, translateY, 0)
            transform = CATransform3DRotate(transform, angle, 0, 0, 1)
            transform = CATransform3DScale(transform, scaleFactor, 1, 1)
            
            values.append(NSValue(caTransform3D: transform))
        }
        return values
    }
    
    private func hamburgerToArrowValuesMiddleLayer() -> [NSValue] {
        
        let numberOfValues = 4
        
        let startScaleFactor: CGFloat = 1
        let endScaleFactor: CGFloat = middleLayerScaleFactor
        
        let endAngle: CGFloat = .pi
        
        var values: [NSValue] = []
        
        for i in 0 ..< numberOfValues {
            let angle = endAngle / CGFloat((numberOfValues - 1) * i)
            let scaleFactor = startScaleFactor + (endScaleFactor - startScaleFactor) * CGFloat(i) / (CGFloat(numberOfValues) - 1)
            
            var transform = CATransform3DIdentity
            transform = CATransform3DRotate(transform, angle, 0, 0, 1)
            transform = CATransform3DScale(transform, scaleFactor, 1, 1)
            transform = CATransform3DTranslate(transform, (CGFloat(1) - scaleFactor) * self.lineWidth / 2, 0, 0)
            
            values.append(NSValue(caTransform3D: transform))
        }
        return values
    }
    
    private func hamburgerToArrowValuesBottomLayer() -> [NSValue] {
        
        let numberOfValues = 4
        
        let startScaleFactor: CGFloat = 1
        let endScaleFactor: CGFloat = 0.5
        
        let endAngle: CGFloat = .pi + (.pi/4)
        
        var values: [NSValue] = []
        
        for i in 0 ..< numberOfValues {
            let angle = endAngle / CGFloat((numberOfValues - 1) * i)
            let scaleFactor = startScaleFactor + (endScaleFactor - startScaleFactor) * CGFloat(i) / (CGFloat(numberOfValues) - 1)
            
            var transform = CATransform3DIdentity
            
            // Translate to bottom position
            var translateX: CGFloat = 0
            var translateY = (self.middleLayer.position.y - (self.lineWidth / 2)) - self.topLayer.position.y
            // Translate for 45 degres rotation
            translateX += (1 - CGFloat(fabs(Double(cosf(Float(endAngle)))))) * self.lineWidth / 2 * -1 * (1 / endScaleFactor)
            translateY += (1 - CGFloat(fabs(Double(sinf(Float(endAngle)))))) * self.lineWidth / 2 * (1 / endScaleFactor)
            // Hack
            translateX -= 1
            translateY += 1
            
            translateX *= CGFloat(i) / CGFloat(numberOfValues - 1)
            translateY *= CGFloat(i) / CGFloat(numberOfValues - 1)
            
            transform = CATransform3DTranslate(transform, translateX, translateY, 0)
            transform = CATransform3DRotate(transform, angle, 0, 0, 1)
            transform = CATransform3DScale(transform, scaleFactor, 1, 1)
            
            values.append(NSValue(caTransform3D: transform))
        }
        return values
    }
    
    // MARK: - Hamburger / Cross
    
    private func hamburgerToCrossValuesTopLayer() -> [NSValue] {
        
        let numberOfValues = 4
        let endAngle: CGFloat = .pi/4
        
        var values: [NSValue] = []
        
        for i in 0 ..< numberOfValues {
            let angle = endAngle / CGFloat((numberOfValues - 1) * i)
            
            var transform = CATransform3DIdentity
            
            var translateY = self.middleLayer.position.y - self.topLayer.position.y
            translateY *= CGFloat(i) / CGFloat(numberOfValues - 1)
            
            transform = CATransform3DTranslate(transform, 0, translateY, 0)
            transform = CATransform3DRotate(transform, angle, 0, 0, 1)
            
            values.append(NSValue(caTransform3D: transform))
            
        }
        return values
    }
    
    private func hamburgerToCrossValuesMiddleLayer() -> [NSValue] {
        
        let numberOfValues = 4
        
        let startScaleFactor: CGFloat = 1
        let endScaleFactor: CGFloat = 0.5
        
        var values: [NSValue] = []
        
        for i in 0 ..< numberOfValues {
            let scaleFactor = startScaleFactor + (endScaleFactor - startScaleFactor) * CGFloat(i) / CGFloat(numberOfValues - 1)
            
            var transform = CATransform3DIdentity
            transform = CATransform3DScale(transform, scaleFactor, 1, 1)
            
            values.append(NSValue(caTransform3D: transform))
        }
        return values
    }
    
    private func hamburgerToCrossValuesBottomLayer() -> [NSValue] {
        
        let numberOfValues = 4
        let endAngle: CGFloat = -(.pi/4)
        
        var values: [NSValue] = []
        
        for i in 0 ..< numberOfValues {
            let angle = endAngle / CGFloat((numberOfValues - 1) * i)
            
            var transform = CATransform3DIdentity
            
            var translateY = self.middleLayer.position.y - self.bottomLayer.position.y
            translateY *= CGFloat(i) / CGFloat(numberOfValues - 1)
            
            transform = CATransform3DTranslate(transform, 0, translateY, 0)
            transform = CATransform3DRotate(transform, angle, 0, 0, 1)
            
            values.append(NSValue(caTransform3D: transform))
        }
        return values
    }
    
    // MARK: - Arrow / Cross
    
    private func arrowToCrossValuesTopLayer() -> [NSValue] {
        
        let numberOfValues = 4
        
        let startScaleFactor: CGFloat = 0.5
        let endScaleFactor: CGFloat = 1
        
        var startTranslateX: CGFloat = 0
        var startTranslateY: CGFloat = 0
        
        let endTranslateX: CGFloat = 0
        let endTranslateY: CGFloat = self.middleLayer.position.y - self.topLayer.position.y
        
        let angle: CGFloat = .pi/4
        
        // Final position
        startTranslateX = self.lineWidth * (1 - middleLayerScaleFactor) / 2
        startTranslateY = self.middleLayer.position.y - self.topLayer.position.y
        // cancel scaleFactor
        startTranslateX += (self.lineWidth * (1 - startScaleFactor)) / 2 * -1
        // cancel rotation
        startTranslateX += CGFloat(fabs(Double(cosf(Float(angle))))) * (self.lineWidth * startScaleFactor) / 2 * -1
        startTranslateY += CGFloat(fabs(Double(sinf(Float(angle))))) * (self.lineWidth * startScaleFactor) / 2
        // Hack
        startTranslateX += 2
        
        var values: [NSValue] = []
        
        for i in 0 ..< numberOfValues {
            let scaleFactor = startScaleFactor + (endScaleFactor - startScaleFactor) * CGFloat(i) / CGFloat(numberOfValues - 1)
            let translateX = startTranslateX + (endTranslateX - startTranslateX) * CGFloat(i) / CGFloat(numberOfValues - 1)
            let translateY = startTranslateY + (endTranslateY - startTranslateY) * CGFloat(i) / CGFloat(numberOfValues - 1)
            
            var transform = CATransform3DIdentity
            
            transform = CATransform3DTranslate(transform, translateX, translateY, 0)
            transform = CATransform3DRotate(transform, angle, 0, 0, 1)
            transform = CATransform3DScale(transform, scaleFactor, 1, 1)
            
            values.append(NSValue(caTransform3D: transform))
        }
        return values
    }
    
    private func arrowToCrossValuesMiddleLayer() -> [NSValue] {
        
        let numberOfValues = 4
        
        let startScaleFactor: CGFloat = middleLayerScaleFactor
        let endScaleFactor: CGFloat = 0
        
        var values: [NSValue] = []
        
        for i in 0 ..< numberOfValues {
            let scaleFactor = startScaleFactor + (endScaleFactor - startScaleFactor) * CGFloat(i) / CGFloat(numberOfValues - 1)
            
            var transform = CATransform3DIdentity
            transform = CATransform3DScale(transform, scaleFactor, 1, 1)
            
            values.append(NSValue(caTransform3D: transform))
        }
        return values
    }
    
    private func arrowToCrossValuesBottomLayer() -> [NSValue] {
        let numberOfValues = 4;
        
        let startScaleFactor: CGFloat = 0.5;
        let endScaleFactor: CGFloat = 1
        
        var startTranslateX: CGFloat = 0;
        var startTranslateY: CGFloat = 0;
        let endTranslateX: CGFloat = 0;
        let endTranslateY: CGFloat = self.middleLayer.position.y - self.bottomLayer.position.y;
        
        let angle: CGFloat = -(.pi/4)
        
        // Final position
        startTranslateX = self.lineWidth * (1 - middleLayerScaleFactor) / 2
        startTranslateY = -(bottomLayer.position.y - middleLayer.position.y);
        
        // cancel scaleFactor
        startTranslateX += (self.lineWidth * (1 - startScaleFactor)) / 2 * -1
        
        // cancel rotation
        startTranslateX += CGFloat(fabs(Double(cosf(Float(angle))))) * (self.lineWidth * startScaleFactor) / 2 * -1
        startTranslateY += CGFloat(fabs(Double(sinf(Float(angle))))) * (self.lineWidth * startScaleFactor) / 2 * -1
        
        // Hack
        startTranslateX += 2
        
        var values: [NSValue] = []
        
        for i in 0 ..< numberOfValues {
            let scaleFactor = startScaleFactor + (endScaleFactor - startScaleFactor) * CGFloat(i) / CGFloat(numberOfValues - 1)
            let translateX = startTranslateX + (endTranslateX - startTranslateX) * CGFloat(i) / CGFloat(numberOfValues - 1)
            let translateY = startTranslateY + (endTranslateY - startTranslateY) * CGFloat(i) / CGFloat(numberOfValues - 1)
            
            var transform = CATransform3DIdentity
            
            transform = CATransform3DTranslate(transform, translateX, translateY, 0)
            transform = CATransform3DRotate(transform, angle, 0, 0, 1)
            transform = CATransform3DScale(transform, scaleFactor, 1, 1)
            
            values.append(NSValue(caTransform3D: transform))
        }
        return values
    }
}

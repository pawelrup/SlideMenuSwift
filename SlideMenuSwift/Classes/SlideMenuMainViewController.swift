//
//  SlideMenuMainViewController.swift
//  SideMenu
//
//  Created by Pawel Rup on 21.07.2017.
//  Copyright © 2017 Pawel Rup. All rights reserved.
//

import UIKit

private let kPanMinTranslationX: CGFloat = 15
private let kMenuTransformScale = CATransform3DMakeScale(0.9, 0.9, 0.9)
private let kMenuLayerInitialOpacity: Float = 0.4
private let kAutoresizingMaskAll: UIViewAutoresizing = [.flexibleWidth, .flexibleHeight, .flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]

public enum PrimaryMenu {
    case left
    case right
}

public enum SlideMenu {
    case left
    case right
}

public enum SlideMenuState {
    case closed
    case leftOpened
    case rightOpened
}

public enum SlidePanningState {
    case stopped
    case left
    case right
}

@objc public protocol SlideMenuMultipleStoryboarding: class {
    @objc optional func navigationControllerInLeftMenu(for indexPath: IndexPath) -> UINavigationController
    @objc optional func navigationControllerInRightMenu(for indexPath: IndexPath) -> UINavigationController
}

open class SlideMenuMainViewController: UIViewController, SlideMenuMultipleStoryboarding {
    
    private static var allInstances: [NSValue] = []
    
    fileprivate lazy var tapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer()
        gesture.addTarget(self, action: #selector(handleTapGesture(_:)))
        gesture.cancelsTouchesInView = true
        return gesture
    }()
    fileprivate lazy var panGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer()
        gesture.delegate = self
        gesture.addTarget(self, action: #selector(handlePanGesture(_:)))
        gesture.cancelsTouchesInView = true
        return gesture
    }()
    
    private var menuState: SlideMenuState = .closed
    private var panningState: SlidePanningState?
    private var panningPreviousPosition: CGFloat = 0
    private var panningPreviousEventDate: Date?
    private var panningXSpeed: CGFloat?
    private var panStarted: Bool = false
    private var initialOrientation: UIInterfaceOrientation?
    
    private var overlayView: UIView?
    private var darknessView: UIView?
    private var statusBarView: UIView?
    private var initialViewController: UINavigationController?
    
    private var leftSegue: SlideMenuLeftMenuSegue?
    private var rightSegue: SlideMenuRightMenuSegue?
    
    public internal (set) var leftMenu: SlideMenuLeftTableViewController?
    public internal (set) var rightMenu: SlideMenuRightTableViewController?
    public internal (set) var currentActiveNVC: UINavigationController?
    
    internal private (set) var isInitialStart: Bool = true
    internal (set) var leftPanDisabled: Bool = false
    internal (set) var rightPanDisabled: Bool = false
    
    weak var slideMenuDelegate: SlideMenuDelegate?
    
    // MARK: - Lifecycle
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        SlideMenuMainViewController.allInstances.append(NSValue(nonretainedObject: self))
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterfaceOrientationChangedNotification(_:)), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        self.initialOrientation = UIApplication.shared.statusBarOrientation
        self.setup()
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let leftMenu = self.leftMenu, self.deepnessForLeftMenu {
            leftMenu.view.layer.transform = kMenuTransformScale
            leftMenu.view.layer.opacity = kMenuLayerInitialOpacity
            leftMenu.view.autoresizingMask = kAutoresizingMaskAll
            leftMenu.view.isHidden = true
        }
        if let rightMenu = self.rightMenu, self.deepnessForRightMenu {
            rightMenu.view.layer.transform = kMenuTransformScale
            rightMenu.view.layer.opacity = kMenuLayerInitialOpacity
            rightMenu.view.autoresizingMask = kAutoresizingMaskAll
            rightMenu.view.isHidden = true
        }
        self.leftMenu?.tableView.scrollsToTop = false
        self.rightMenu?.tableView.scrollsToTop = false
    }
    
    @objc private func handleInterfaceOrientationChangedNotification(_ notification: Notification) {
        if let currentActiveNVC = self.currentActiveNVC, currentActiveNVC.shouldAutorotate {
            let bounds = self.view.bounds
            self.rightMenu?.view.frame = CGRect(x: bounds.size.width - self.rightMenuWidth, y: 0, width: self.rightMenuWidth, height: bounds.size.height)
            self.leftMenu?.view.frame = CGRect(origin: .zero, size: CGSize(width: bounds.size.width, height: bounds.size.height))
            if let overlayView = self.overlayView, let _ = overlayView.superview{
                overlayView.frame = CGRect(x: 0, y: 0, width: currentActiveNVC.view.frame.size.width, height: currentActiveNVC.view.frame.size.height)
            }
            let delayInSeconds: Double = 0.25
            DispatchQueue.main.asyncAfter(deadline: .now() + delayInSeconds, execute: { [weak self, currentActiveNVC] in
                self?.configure(slideLayer: currentActiveNVC.view.layer)
            })
            if UIDevice.current.userInterfaceIdiom != .pad {
                let toInterfaceOrientation = UIApplication.shared.statusBarOrientation
                var frame = currentActiveNVC.navigationBar.frame
                if toInterfaceOrientation == .portrait || toInterfaceOrientation == .portraitUpsideDown {
                    frame.size.height = 44
                } else {
                    frame.size.height = 32
                }
                currentActiveNVC.navigationBar.frame = frame
            }
        }
    }
    
    override open func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        if let currentActiveNVC = self.currentActiveNVC, currentActiveNVC.shouldAutorotate {
            currentActiveNVC.view.layer.shadowOpacity = 0
        }
    }
    
    deinit {
        SlideMenuMainViewController.allInstances.enumerated().forEach { (index, instance) in
            if let mainVC = instance.nonretainedObjectValue as? SlideMenuMainViewController, mainVC == self {
                SlideMenuMainViewController.allInstances.remove(at: index)
            }
        }
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Static methods
    
    public static func getInstance(for viewController: UIViewController) -> SlideMenuMainViewController? {
        if SlideMenuMainViewController.allInstances.count == 1 {
            return SlideMenuMainViewController.allInstances.first?.nonretainedObjectValue as? SlideMenuMainViewController
        }
        for instance in SlideMenuMainViewController.allInstances {
            if let mainVC = instance.nonretainedObjectValue as? SlideMenuMainViewController, mainVC.currentActiveNVC == viewController.navigationController || mainVC.currentActiveNVC == viewController {
                return mainVC
            }
        }
        return nil
    }
    
    // MARK: - Datasource
    
    public var leftMenuWidth: CGFloat {
        return 250
    }
    
    public var rightMenuWidth: CGFloat {
        return 250
    }
    
    public var openAnimationDuration: TimeInterval {
        return 0.25
    }
    
    public var closeAnimationDuration: TimeInterval {
        return 0.25
    }
    
    public var openAnimationOptions: UIViewAnimationOptions {
        return .curveLinear
    }
    
    public var closeAnimationOptions: UIViewAnimationOptions {
        return .curveLinear
    }
    
    public var primaryMenu: PrimaryMenu {
        return .left
    }
    
    public var initialIndexPathForLeftMenu: IndexPath {
        return IndexPath(row: 0, section: 0)
    }
    
    public var initialIndexPathForRightMenu: IndexPath {
        return IndexPath(row: 0, section: 0)
    }
    
    public func segueIdentifierInLeftMenu(forIndexPath indexPath: IndexPath) -> String? {
        return ""
    }
    
    public func segueIdentifierInRightMenu(forIndexPath indexPath: IndexPath) -> String? {
        return ""
    }
    
    public var panGestureWarkingAreaPercent: CGFloat {
        return 100
    }
    
    public var deepnessForLeftMenu: Bool {
        return false
    }
    
    public var deepnessForRightMenu: Bool {
        return false
    }
    
    public var maxDarknessWhileLeftMenu: CGFloat {
        return 0
    }
    
    public var maxDarknessWhileRightMenu: CGFloat {
        return 0
    }
    
    public var segueIdentifierForLeftMenu: String {
        return ""
    }
    
    public var segueIdentifierForRightMenu: String {
        return ""
    }
    
    public func configureLeftMenuButton() -> UIButton? {
        return nil
    }
    
    public func configureRightMenuButton() -> UIButton? {
        return nil
    }
    
    public func configure(slideLayer layer: CALayer) {
        layer.shadowColor = UIColor.gray.cgColor
        layer.shadowOpacity = 1
        layer.shadowOffset = .zero
        layer.masksToBounds = false
        layer.shadowPath = UIBezierPath(rect: layer.bounds).cgPath
    }
    
    // MARK: - Private methods
    
    private func set(rightMenu: SlideMenuRightTableViewController) {
        self.rightMenu = rightMenu
        var frame = self.rightMenu!.view.frame
        frame.size.width = self.rightMenuWidth
        self.rightMenu!.view.frame = frame
    }
    
    private func configureDarknessView() {
        self.darknessView?.removeFromSuperview()
        self.darknessView = UIView(frame: self.currentActiveNVC?.view.bounds ?? .zero)
        self.darknessView?.backgroundColor = .black
        switch self.menuState {
        case .closed:
            self.darknessView?.alpha = 0
        case .leftOpened:
            self.darknessView?.alpha = self.maxDarknessWhileLeftMenu
        case .rightOpened:
            self.darknessView?.alpha = self.maxDarknessWhileRightMenu
        }
        
        self.darknessView?.layer.zPosition = 1
        
        self.darknessView?.autoresizingMask = kAutoresizingMaskAll
        self.currentActiveNVC?.view.addSubview(self.darknessView!)
    }
    
    private func rightMenuWillReveal() {
        self.configureDarknessView()
    }
    
    private func leftMenuWillReveal() {
        self.configureDarknessView()
    }
    
    // MARK: -
    
    private func setup() {
        func canPerformSegue(id: String) -> Bool {
            guard let segues = self.value(forKey: "storyboardSegueTemplates") as? [NSObject] else { return false }
            let filtered = segues.filter({ $0.value(forKey: "identifier") as? String == id })
            return filtered.count > 0
        }
        
        #if SlideMenuWithoutStoryboards
            switch self.primaryMenu {
            case .left:
                if let leftMenu = self.leftMenu {
                    self.leftSegue = SlideMenuLeftMenuSegue(identifier: self.segueIdentifierForLeftMenu, source: self, destination: leftMenu)
                    self.leftSegue?.perform()
                }
                if let rightMenu = self.rightMenu {
                    self.rightSegue = SlideMenuRightMenuSegue(identifier: self.segueIdentifierForRightMenu, source: self, destination: rightMenu)
                    self.rightSegue?.perform()
                }
            case .right:
                if let rightMenu = self.rightMenu {
                    self.rightSegue = SlideMenuRightMenuSegue(identifier: self.segueIdentifierForRightMenu, source: self, destination: rightMenu)
                    self.rightSegue?.perform()
                }
                if let leftMenu = self.leftMenu {
                    self.leftSegue = SlideMenuLeftMenuSegue(identifier: self.segueIdentifierForLeftMenu, source: self, destination: leftMenu)
                    self.leftSegue?.perform()
                }
            }
        #else
            switch self.primaryMenu {
            case .left:
                
                if canPerformSegue(id: self.segueIdentifierForLeftMenu) {
                    self.performSegue(withIdentifier: self.segueIdentifierForLeftMenu, sender: self)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if canPerformSegue(id: self.segueIdentifierForRightMenu) {
                            self.performSegue(withIdentifier: self.segueIdentifierForRightMenu, sender: self)
                        }
                    }
                } else {
                    self.performSegue(withIdentifier: self.segueIdentifierForRightMenu, sender: self)
                    NSLog("WARNING: You setted primaryMenu to left , but you have no segue with identifier 'leftMenu'")
                }
                
            case .right:
                
                if canPerformSegue(id: self.segueIdentifierForRightMenu) {
                    self.performSegue(withIdentifier: self.segueIdentifierForRightMenu, sender: self)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if canPerformSegue(id: self.segueIdentifierForLeftMenu) {
                            self.performSegue(withIdentifier: self.segueIdentifierForLeftMenu, sender: self)
                        }
                    }
                } else {
                    self.performSegue(withIdentifier: self.segueIdentifierForLeftMenu, sender: self)
                    NSLog("WARNING: You setted primaryMenu to right , but you have no segue with identifier 'rightMenu'")
                }
            }
        #endif
        self.currentActiveNVC?.view.addGestureRecognizer(self.panGesture)
        self.isInitialStart = false
    }
    
    // MARK: - Public Actions
    
    public func openLeftMenu() {
        self.openLeftMenu(animated: true)
    }
    
    public func openLeftMenu(animated: Bool) {
        self.slideMenuDelegate?.leftMenuWillOpen()
        if self.darknessView == nil {
            self.configureDarknessView()
        }
        self.rightMenu?.view.isHidden = true
        self.leftMenu?.view.isHidden = false
        
        var frame = self.currentActiveNVC?.view.frame ?? .zero
        frame.origin.x = self.leftMenuWidth
        
        UIView.animate(withDuration: animated ? self.openAnimationDuration : 0, delay: 0, options: self.openAnimationOptions, animations: {
            self.currentActiveNVC?.view.frame = frame
            if self.deepnessForLeftMenu {
                self.leftMenu?.view.layer.transform = CATransform3DMakeScale(1.0, 1.0, 1.0)
                self.leftMenu?.view.layer.opacity = 1
                
                if let statusBarView = self.statusBarView {
                    statusBarView.layer.opacity = 0
                }
                self.darknessView?.alpha = self.maxDarknessWhileLeftMenu
            }
        }, completion: { (_) in
            self.addGestures()
            self.enableGestures()
            self.menuState = .leftOpened
            
            self.slideMenuDelegate?.leftMenuDidOpen()
        })
    }
    
    public func openRightMenu() {
        self.openRightMenu(animated: true)
    }
    
    public func openRightMenu(animated: Bool) {
        self.slideMenuDelegate?.rightMenuWillOpen()
        if self.darknessView == nil {
            self.configureDarknessView()
        }
        self.rightMenu?.view.isHidden = false
        self.leftMenu?.view.isHidden = true
        
        var frame = self.currentActiveNVC?.view.frame ?? .zero
        frame.origin.x = -1 * self.leftMenuWidth
        
        UIView.animate(withDuration: animated ? self.openAnimationDuration : 0, delay: 0, options: self.openAnimationOptions, animations: {
            self.currentActiveNVC?.view.frame = frame
            if self.deepnessForLeftMenu {
                self.rightMenu?.view.layer.transform = CATransform3DMakeScale(1.0, 1.0, 1.0)
                self.rightMenu?.view.layer.opacity = 1
                
                if let statusBarView = self.statusBarView {
                    statusBarView.layer.opacity = 0
                }
                self.darknessView?.alpha = self.maxDarknessWhileRightMenu
            }
        }, completion: { (_) in
            self.addGestures()
            self.enableGestures()
            self.menuState = .rightOpened
            
            self.slideMenuDelegate?.rightMenuDidOpen()
        })
    }
    
    public func closeLeftMenu() {
        self.closeLeftMenu(animated: true)
    }
    
    public func closeLeftMenu(animated: Bool) {
        self.slideMenuDelegate?.leftMenuWillClose()
        var frame = self.currentActiveNVC?.view.frame ?? .zero
        frame.origin.x = 0
        
        UIView.animate(withDuration: animated ? self.closeAnimationDuration : 0, delay: 0, options: self.closeAnimationOptions, animations: {
            self.currentActiveNVC?.view.frame = frame
            if self.deepnessForLeftMenu {
                self.leftMenu?.view.layer.transform = kMenuTransformScale
                self.leftMenu?.view.layer.opacity = kMenuLayerInitialOpacity
            }
            if let statusBarView = self.statusBarView {
                statusBarView.layer.opacity = 1
            }
            self.darknessView?.alpha = 0
        }, completion: { (_) in
            self.overlayView?.removeFromSuperview()
            self.desableGestures()
            self.menuState = .closed
            self.currentActiveNVC?.view.addGestureRecognizer(self.panGesture)
            self.slideMenuDelegate?.leftMenuDidClose()
        })
    }
    
    public func closeRightMenu() {
        self.closeRightMenu(animated: true)
    }
    
    public func closeRightMenu(animated: Bool) {
        self.slideMenuDelegate?.rightMenuWillClose()
        var frame = self.currentActiveNVC?.view.frame ?? .zero
        frame.origin.x = 0
        
        UIView.animate(withDuration: animated ? self.closeAnimationDuration : 0, delay: 0, options: self.closeAnimationOptions, animations: {
            self.currentActiveNVC?.view.frame = frame
            if self.deepnessForRightMenu {
                self.rightMenu?.view.layer.transform = kMenuTransformScale
                self.rightMenu?.view.layer.opacity = kMenuLayerInitialOpacity
            }
            if let statusBarView = self.statusBarView {
                statusBarView.layer.opacity = 1
            }
            self.darknessView?.alpha = 0
        }, completion: { (_) in
            self.overlayView?.removeFromSuperview()
            self.desableGestures()
            self.menuState = .closed
            self.currentActiveNVC?.view.addGestureRecognizer(self.panGesture)
            self.slideMenuDelegate?.rightMenuDidClose()
        })
    }
    
    public func closeMenu() {
        switch self.menuState {
        case .leftOpened:
            self.closeLeftMenu()
        case .rightOpened:
            self.closeRightMenu()
        default:
            break
        }
    }
    
    public func switchCurrentActiveController(to navigationController: UINavigationController, from menu: UITableViewController) {
        self.leftPanDisabled = false
        self.rightPanDisabled = false
        
        if self.isInitialStart {
            switch self.primaryMenu {
            case .left:
                if menu.isKind(of: SlideMenuLeftTableViewController.self) {
                    self.initialViewController = navigationController
                }
                if let _ = self.leftMenu, menu.isKind(of: SlideMenuRightTableViewController.self) {
                    if let currentActiveNVC = self.currentActiveNVC {
                        currentActiveNVC.view.removeFromSuperview()
                    }
                    self.currentActiveNVC = self.initialViewController
                    self.view.addSubview(self.currentActiveNVC!.view)
                }
            case .right:
                if menu.isKind(of: SlideMenuLeftTableViewController.self) {
                    if let currentActiveNVC = self.currentActiveNVC {
                        currentActiveNVC.view.removeFromSuperview()
                    }
                    self.currentActiveNVC = self.initialViewController
                    self.view.addSubview(self.currentActiveNVC!.view)
                }
                if menu.isKind(of: SlideMenuRightTableViewController.self) {
                    self.initialViewController = navigationController
                }
            }
        }
        
        if let currentActiveNVC = self.currentActiveNVC {
            currentActiveNVC.view.removeFromSuperview()
        }
        self.currentActiveNVC = navigationController
        
        self.view.addSubview(navigationController.view)
        self.addChildViewController(navigationController)
        self.configureDarknessView()
        
        if !UIApplication.shared.isStatusBarHidden {
            if let statusBarView = self.statusBarView {
                var frame = statusBarView.frame
                if frame.size.height > 20 {
                    frame.size.height = 20
                }
                frame.origin.y = -1 * frame.size.height
                statusBarView.frame = frame
                statusBarView.layer.opacity = 1
                statusBarView.removeFromSuperview()
                self.currentActiveNVC?.view.addSubview(statusBarView)
                
                var contentFrame = self.currentActiveNVC?.view.frame ?? .zero
                contentFrame.origin.y = frame.size.height
                contentFrame.size.height = self.view.frame.size.height - frame.size.height
                self.currentActiveNVC?.view.frame = contentFrame
            }
        }
        
        self.closeMenu()
        self.currentActiveNVC?.view.addGestureRecognizer(self.panGesture)
        
        if menu.isKind(of: SlideMenuLeftTableViewController.self), let indexPath = self.rightMenu?.tableView.indexPathForSelectedRow {
            self.rightMenu?.tableView.deselectRow(at: indexPath, animated: false)
        } else if menu.isKind(of: SlideMenuRightTableViewController.self), let indexPath = self.leftMenu?.tableView.indexPathForSelectedRow {
            self.leftMenu?.tableView.deselectRow(at: indexPath, animated: false)
        }
    }
    
    public func openContentViewController(for menu: SlideMenu, at indexPath: IndexPath) {
        switch menu {
        case .left:
            guard let leftMenu = self.leftMenu else { return }
            leftMenu.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            if let navigationController = (self as SlideMenuMultipleStoryboarding).navigationControllerInLeftMenu?(for: indexPath) {
                let segue = SlideMenuContentSegue(identifier: "ContentSugue", source: leftMenu, destination: navigationController)
                segue.perform()
            } else {
                guard let identifier = self.segueIdentifierInLeftMenu(forIndexPath: indexPath) else { return }
                leftMenu.performSegue(withIdentifier: identifier, sender: leftMenu)
            }
            
        case .right:
            guard let rightMenu = self.rightMenu else { return }
            rightMenu.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            if let navigationController = (self as SlideMenuMultipleStoryboarding).navigationControllerInRightMenu?(for: indexPath) {
                let segue = SlideMenuContentSegue(identifier: "ContentSugue", source: rightMenu, destination: navigationController)
                segue.perform()
            } else {
                guard let identifier = self.segueIdentifierInRightMenu(forIndexPath: indexPath) else { return }
                rightMenu.performSegue(withIdentifier: identifier, sender: rightMenu)
            }
        }
    }
    
    public func addGestures() {
        if let overlayView = self.overlayView {
            overlayView.removeFromSuperview()
        } else {
            self.overlayView = UIView(frame: self.currentActiveNVC?.view.bounds ?? .zero)
        }
        
        var frame = self.overlayView!.frame
        frame.size = self.currentActiveNVC?.view.bounds.size ?? .zero
        self.overlayView!.frame = frame
        self.overlayView!.layer.zPosition = .greatestFiniteMagnitude
        self.overlayView!.backgroundColor = .clear
        
        self.currentActiveNVC?.view.addSubview(self.overlayView!)
        
        self.overlayView!.addGestureRecognizer(self.tapGesture)
        self.overlayView!.addGestureRecognizer(self.panGesture)
    }
    
    public func fixStatusBar(with view: UIView) {
        self.statusBarView?.removeFromSuperview()
        self.statusBarView = view
        if !UIApplication.shared.isStatusBarHidden, let statusBarView = self.statusBarView {
            var frame = statusBarView.frame
            if frame.size.height > 20 {
                frame.size.height = 20
            }
            frame.origin.y = -1 * frame.size.height
            statusBarView.frame = frame
            statusBarView.layer.opacity = 1
            self.currentActiveNVC?.view.addSubview(statusBarView)
            
            var contentFrame = self.currentActiveNVC?.view.frame ?? .zero
            contentFrame.origin.y = frame.size.height
            contentFrame.size.height = self.view.frame.size.height - frame.size.height
            self.currentActiveNVC?.view.frame = contentFrame
        }
    }
    
    public func unfixStatusBarView() {
        self.statusBarView?.removeFromSuperview()
        self.statusBarView = nil
    }
    
    public func enableGestures() {
        self.tapGesture.isEnabled = true
        //self.panGesture.isEnabled = true
    }
    
    public func desableGestures() {
        self.tapGesture.isEnabled = false
        //self.panGesture.isEnabled = false
    }
    
    // MARK: - Selectors
    
    @objc internal func openLeftMenuSelector() {
        self.openLeftMenu()
    }
    
    @objc internal func openRightMenuSelector() {
        self.openRightMenu()
    }
    
    @objc private func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        self.closeMenu()
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        var panStartPosition: CGPoint = .zero
        
        if self.leftPanDisabled && self.rightPanDisabled {
            return
        }
        
        guard var panningView = gesture.view else { return }
        if self.menuState == .closed, let superview = panningView.superview {
            panningView = superview
        }
        
        let translation = gesture.translation(in: panningView)
        if gesture.state == .began {
            panStartPosition = gesture.location(in: panningView)
            self.panStarted = true
        } else if gesture.state == .ended || gesture.state == .cancelled {
            if self.menuState != .closed {
                if self.menuState == .leftOpened {
                    if panningView.frame.origin.x < (self.leftMenuWidth / 2) {
                        self.closeLeftMenu()
                    } else {
                        self.openLeftMenu()
                    }
                } else if self.menuState == .rightOpened {
                    if self.view.frame.size.width - (panningView.frame.origin.x + panningView.frame.size.width) < (self.rightMenuWidth / 2) {
                        self.closeRightMenu()
                    } else {
                        self.openRightMenu()
                    }
                }
            } else {
                if self.panningState == .right {
                    if panningView.frame.origin.x < (self.leftMenuWidth / 2) {
                        self.closeLeftMenu()
                    } else {
                        self.openLeftMenu()
                    }
                }
                if self.panningState == .left {
                    if self.view.frame.size.width - (panningView.frame.origin.x + panningView.frame.size.width) < (self.rightMenuWidth / 2) {
                        self.closeRightMenu()
                    } else {
                        self.openRightMenu()
                    }
                }
            }
            self.panningState = .stopped
        } else {
            if !__CGPointEqualToPoint(panStartPosition, .zero) {
                let actualWidth = panningView.frame.size.width * (self.panGestureWarkingAreaPercent / 100)
                guard !(panStartPosition.x > actualWidth && panStartPosition.x < panningView.frame.size.width - actualWidth && self.menuState == .closed) else { return }
                if self.panStarted {
                    self.panStarted = false
                    if panningView.frame.origin.x + translation.x < 0 {
                        self.panningState = .left
                        self.rightMenuWillReveal()
                        if self.menuState == .closed {
                            self.leftMenu?.view.isHidden = true
                            self.rightMenu?.view.isHidden = false
                        }
                    } else if panningView.frame.origin.x + translation.x > 0 {
                        self.panningState = .right
                        self.leftMenuWillReveal()
                        if self.menuState == .closed {
                            self.leftMenu?.view.isHidden = false
                            self.rightMenu?.view.isHidden = true
                        }
                    }
                }
                
                switch self.menuState {
                case .leftOpened:
                    if fabs(translation.x) > kPanMinTranslationX && translation.x < 0 {
                        self.closeLeftMenu()
                    } else if (panningView.frame.origin.x + translation.x) < self.leftMenuWidth && (panningView.frame.origin.x + translation.x) >= 0 {
                        panningView.center = CGPoint(x: panningView.center.x + translation.x, y: panningView.center.y)
                        self.configure3DTransform(for: .left, panningView: panningView)
                    }
                case .rightOpened:
                    if fabs(translation.x) > kPanMinTranslationX && translation.x > 0 {
                        self.closeRightMenu()
                    } else if self.view.frame.size.width - (panningView.frame.origin.x + panningView.frame.size.width + translation.x) < self.rightMenuWidth &&
                        panningView.frame.origin.x <= 0 {
                        panningView.center = CGPoint(x: panningView.center.x + translation.x, y: panningView.center.y)
                        self.configure3DTransform(for: .right, panningView: panningView)
                    }
                case .closed:
                    if self.panningState == .right, let _ = self.leftMenu {
                        if fabs(translation.x) > kPanMinTranslationX && translation.x > 0 {
                            self.openLeftMenu()
                        } else if (panningView.frame.origin.x + translation.x) < self.leftMenuWidth && (panningView.frame.origin.x + translation.x) > 0 {
                            panningView.center = CGPoint(x: panningView.center.x + translation.x, y: panningView.center.y)
                            self.configure3DTransform(for: .left, panningView: panningView)
                        }
                    } else if self.panningState == .left, let _ = self.rightMenu {
                        if fabs(translation.x) > kPanMinTranslationX && translation.x < 0 {
                            self.openRightMenu()
                        } else if self.view.frame.size.width - (panningView.frame.origin.x + panningView.frame.size.width + translation.x) <= self.rightMenuWidth {
                            if panningView.frame.origin.x + translation.x <= 0 {
                                panningView.center = CGPoint(x: panningView.center.x + translation.x, y: panningView.center.y)
                                self.configure3DTransform(for: .right, panningView: panningView)
                            }
                        }
                    }
                }
            }
            
            if let panningPreviousEventDate = self.panningPreviousEventDate {
                let movement = panningView.frame.origin.x - self.panningPreviousPosition
                let movementDuration = CGFloat(Date().timeIntervalSince(panningPreviousEventDate) * 1000)
                self.panningXSpeed = movement/movementDuration
            }
            self.panningPreviousEventDate = Date()
            self.panningPreviousPosition = panningView.frame.origin.x
            
            gesture.setTranslation(.zero, in: panningView)
        }
    }
    
    private func configure3DTransform(for menu: SlideMenu, panningView: UIView) {
        
        var cx: CGFloat = 0
        var cy: CGFloat = 0
        var cz: CGFloat = 0
        var opacity: Float = 0
        
        // **** DEEPNESS EFFECT ****
        
        if menu == .left && panningView.frame.origin.x != 0 && self.deepnessForLeftMenu {
            cx = kMenuTransformScale.m11 + (panningView.frame.origin.x / self.leftMenuWidth) * (1.0 - kMenuTransformScale.m11)
            cy = kMenuTransformScale.m22 + (panningView.frame.origin.x / self.leftMenuWidth) * (1.0 - kMenuTransformScale.m22)
            cz = kMenuTransformScale.m33 + (panningView.frame.origin.x / self.leftMenuWidth) * (1.0 - kMenuTransformScale.m33)
            
            opacity = kMenuLayerInitialOpacity + (Float(panningView.frame.origin.x) / Float(self.leftMenuWidth)) * (1.0 - kMenuLayerInitialOpacity)
            
            self.leftMenu?.view.layer.transform = CATransform3DMakeScale(cx, cy, cz)
            self.leftMenu?.view.layer.opacity = opacity
        } else if menu == .right && panningView.frame.origin.x != 0 && self.deepnessForRightMenu {
            cx = kMenuTransformScale.m11 + (-panningView.frame.origin.x / self.rightMenuWidth) * (1.0 - kMenuTransformScale.m11)
            cy = kMenuTransformScale.m22 + (-panningView.frame.origin.x / self.rightMenuWidth) * (1.0 - kMenuTransformScale.m22)
            cz = kMenuTransformScale.m33 + (-panningView.frame.origin.x / self.rightMenuWidth) * (1.0 - kMenuTransformScale.m33)
            
            opacity = kMenuLayerInitialOpacity + (-Float(panningView.frame.origin.x) / Float(self.rightMenuWidth)) * (1.0 - kMenuLayerInitialOpacity)
            
            self.rightMenu?.view.layer.transform = CATransform3DMakeScale(cx, cy, cz)
            self.rightMenu?.view.layer.opacity = opacity
        }
        
        // **** DEEPNESS EFFECT ****
        // **** STATUS BAR FIX ****
        
        if menu == .left && panningView.frame.origin.x != 0, let statusBarView = self.statusBarView {
            statusBarView.layer.opacity = 1 - Float(panningView.frame.origin.x) - Float(self.leftMenuWidth)
        } else if menu == .right && panningView.frame.origin.x != 0, let statusBarView = self.statusBarView {
            statusBarView.layer.opacity = 1 - Float(panningView.frame.origin.x) - Float(self.rightMenuWidth)
        }
        
        // **** STATUS BAR FIX ****
        // **** DARKNESS EFFECT ****
        
        switch menu {
        case .left:
            let alpha = self.maxDarknessWhileLeftMenu * (panningView.frame.origin.x / self.leftMenuWidth)
            self.darknessView?.alpha = alpha
        case .right:
            let alpha = self.maxDarknessWhileRightMenu * (fabs(panningView.frame.origin.x) / self.rightMenuWidth)
            self.darknessView?.alpha = alpha
        }
        
        // **** DARKNESS EFFECT ****
    }
}

// MARK: - UIGestureRecognizerDelegate
extension SlideMenuMainViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let view = touch.view, view.isKind(of: UISlider.self) {
            return false
        }
        return true
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let velocity = self.panGesture.velocity(in: self.panGesture.view)
        let isHorizontalGesture = fabs(velocity.y) < fabs(velocity.x)
        
        if isHorizontalGesture {
            if velocity.x > 0 && self.rightPanDisabled {
                return false
            }
            if velocity.x < 0 && self.leftPanDisabled {
                return false
            }
        }
        
        return isHorizontalGesture
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        let velocity = self.panGesture.velocity(in: self.panGesture.view)
        let isHorizontalGesture = fabs(velocity.y) < fabs(velocity.x)
        
        if let view = otherGestureRecognizer.view, view.isKind(of: UITableView.self) {
            if isHorizontalGesture {
                let directionIsLeft = velocity.x < 0
                if directionIsLeft {
                    self.panGesture.isEnabled = false
                    self.panGesture.isEnabled = true
                    if let _ = self.rightMenu {
                        return false
                    } else {
                        return true
                    }
                } else {
                    if let tableView = otherGestureRecognizer.view as? UITableView {
                        let point = otherGestureRecognizer.location(in: tableView)
                        if let indexPath = tableView.indexPathForRow(at: point), let cell = tableView.cellForRow(at: indexPath), cell.isEditing {
                            self.panGesture.isEnabled = false
                            self.panGesture.isEnabled = true
                            return true
                        }
                    }
                }
            }
        } else if let view = otherGestureRecognizer.view, let classFromString = NSClassFromString("UITableViewCellScrollView"), view.isKind(of: classFromString) {
            return false
        }
        
        return false
    }
}

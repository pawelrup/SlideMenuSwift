//
//  UIViewController+SideMenu.swift
//  SideMenu
//
//  Created by Pawel Rup on 22.07.2017.
//  Copyright © 2017 Pawel Rup. All rights reserved.
//

import UIKit

extension UIViewController {
    
    var mainSlideMenu: SlideMenuMainViewController? {
        return SlideMenuMainViewController.getInstance(for: self)
    }
    
    // MARK: - Public Actions
    
    @nonobjc open override static func load() {
        self.swizzle(originalSelector: #selector(viewWillDisappear(_:)), toSelector: #selector(my_viewWillDisappear(_:)))
        super.load()
    }
    
    // MARK: - Swizzle Utils methods
    
    private static func swizzle(originalSelector: Selector, toSelector swizzleSelector: Selector) {
        let originalMethod = class_getInstanceMethod(self, originalSelector)
        let newMethod = class_getInstanceMethod(self, swizzleSelector)
        method_exchangeImplementations(originalMethod, newMethod)
    }
    
    // MARK: -
    
    func addLeftMenuButton() {
        let mainVC = SlideMenuMainViewController.getInstance(for: self)
        let navItem = self.navigationItem
        let leftBtn = mainVC?.configureLeftMenuButton() ?? UIButton(type: .custom) //TODO: Animated hamburger button as default
        leftBtn.addTarget(mainVC, action: #selector(SlideMenuMainViewController.openLeftMenuSelector), for: .touchUpInside)
        navItem.leftBarButtonItem = UIBarButtonItem(customView: leftBtn)
    }
    
    func addRightMenuButton() {
        let mainVC = SlideMenuMainViewController.getInstance(for: self)
        let navItem = self.navigationItem
        let rightBtn = mainVC?.configureRightMenuButton() ?? UIButton(type: .custom) //TODO: Animated hamburger button as default
        rightBtn.addTarget(mainVC, action: #selector(SlideMenuMainViewController.openRightMenuSelector), for: .touchUpInside)
        navItem.leftBarButtonItem = UIBarButtonItem(customView: rightBtn)
    }
    
    func removeLeftMenuButton() {
        let navItem = self.navigationItem
        navItem.leftBarButtonItem = nil
    }
    
    func removeRightMenuButton() {
        let navItem = self.navigationItem
        navItem.rightBarButtonItem = nil
    }
    
    func enableSlidePanGestureForLeftMenu() {
        let mainVC = SlideMenuMainViewController.getInstance(for: self)
        mainVC?.rightPanDisabled = false
    }
    
    func enableSlidePanGestureForRightMenu() {
        let mainVC = SlideMenuMainViewController.getInstance(for: self)
        mainVC?.leftPanDisabled = false
    }
    
    func disableSlidePanGestureForLeftMenu() {
        let mainVC = SlideMenuMainViewController.getInstance(for: self)
        mainVC?.rightPanDisabled = true
    }
    
    func disableSlidePanGestureForRightMenu() {
        let mainVC = SlideMenuMainViewController.getInstance(for: self)
        mainVC?.leftPanDisabled = true
    }
    
    func my_viewWillDisappear(_ animated: Bool) {
        let mainVC = SlideMenuMainViewController.getInstance(for: self)
        mainVC?.leftPanDisabled = false
        mainVC?.rightPanDisabled = false
        self.my_viewWillDisappear(animated)
    }
}

//
//  SlideMenuContentSegue.swift
//  SideMenu
//
//  Created by Pawel Rup on 22.07.2017.
//  Copyright © 2017 Pawel Rup. All rights reserved.
//

import UIKit

open class SlideMenuContentSegue: UIStoryboardSegue {
    
    fileprivate var menuButton: SlideMenuHamburgerButton = {
        let button = SlideMenuHamburgerButton(frame: CGRect(origin: .zero, size: CGSize(width: 25, height: 13)))
        button.backgroundColor = .clear
        return button
    }()

    override open func perform() {
        let sourceVC = self.source as! UITableViewController
        let destinationNVC = self.destination as! UINavigationController
        
        let mainVC = sourceVC.parent as! SlideMenuMainViewController
        
        var navItem = mainVC.currentActiveNVC?.navigationBar.topItem
        
        if navItem == nil {
            navItem = destinationNVC.navigationBar.topItem
        }
        
        if !mainVC.isInitialStart {
            let openedFrame = mainVC.currentActiveNVC?.view.frame ?? .zero
            mainVC.currentActiveNVC?.view.removeFromSuperview()
            if let currentActiveNVC = mainVC.currentActiveNVC {
                currentActiveNVC.viewControllers.forEach { (viewController) in
                    viewController.removeFromParentViewController()
                }
            }
            mainVC.currentActiveNVC?.viewControllers.removeAll()
            mainVC.currentActiveNVC = nil
            
            mainVC.currentActiveNVC = destinationNVC
            mainVC.currentActiveNVC?.view.frame = openedFrame
            navItem = destinationNVC.navigationBar.topItem
        }
        
        if let _ = mainVC.leftMenu {
            let leftBtn = mainVC.configureLeftMenuButton() ?? UIButton(type: .custom) //TODO: Animated hamburger button as default
            leftBtn.addTarget(mainVC, action: #selector(SlideMenuMainViewController.openLeftMenuSelector), for: .touchUpInside)
            navItem?.leftBarButtonItem = UIBarButtonItem(customView: leftBtn)
        }
        
        if let _ = mainVC.rightMenu {
            let rightBtn = mainVC.configureLeftMenuButton() ?? UIButton(type: .custom) //TODO: Animated hamburger button as default
            rightBtn.addTarget(mainVC, action: #selector(SlideMenuMainViewController.openRightMenuSelector), for: .touchUpInside)
            navItem?.rightBarButtonItem = UIBarButtonItem(customView: rightBtn)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now()) { 
            mainVC.configure(slideLayer: destinationNVC.view.layer)
        }
        mainVC.switchCurrentActiveController(to: destinationNVC, from: sourceVC)
    }
}

// MARK: - SlideMenuDelegate
extension SlideMenuContentSegue: SlideMenuDelegate {
    public func leftMenuWillOpen() {
        self.menuButton.set(currentMode: .arrow)
    }
    
    public func leftMenuWillClose() {
        self.menuButton.set(currentMode: .hambuger)
    }
}

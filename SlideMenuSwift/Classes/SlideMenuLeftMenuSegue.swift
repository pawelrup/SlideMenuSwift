//
//  SlideMenuLeftMenuSegue.swift
//  SideMenu
//
//  Created by Pawel Rup on 22.07.2017.
//  Copyright © 2017 Pawel Rup. All rights reserved.
//

import UIKit

public class SlideMenuLeftMenuSegue: UIStoryboardSegue {
    
    override public func perform() {
        let mainVC = self.source as! SlideMenuMainViewController
        let leftMenu = self.destination as! SlideMenuLeftTableViewController
        
        mainVC.leftMenu = leftMenu
        leftMenu.mainVC = mainVC
        
        mainVC.addChildViewController(leftMenu)
        
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            let bounds = mainVC.view.bounds
            leftMenu.view.frame = CGRect(origin: .zero, size: bounds.size)
        }
        
        mainVC.view.addSubview(leftMenu.view)
        leftMenu.navigationController?.setNavigationBarHidden(true, animated: false)
        let initialIndexPath = mainVC.initialIndexPathForLeftMenu
        
        #if SlideMenuWithoutStoryboards
            leftMenu.tableView(leftMenu.tableView, didSelectRowAt: initialIndexPath)
        #else
            if let navigationController = (mainVC as SlideMenuMultipleStoryboarding).navigationControllerInLeftMenu?(for: initialIndexPath) {
                let segue = SlideMenuContentSegue(identifier: "contentSugue", source: leftMenu, destination: navigationController)
                segue.perform()
            } else if let segueIdentifier = mainVC.segueIdentifierInLeftMenu(forIndexPath: initialIndexPath) {
                leftMenu.performSegue(withIdentifier: segueIdentifier, sender: self)
            }
        #endif
    }
}

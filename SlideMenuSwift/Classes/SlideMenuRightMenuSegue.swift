//
//  SlideMenuRightMenuSegue.swift
//  SideMenu
//
//  Created by Pawel Rup on 22.07.2017.
//  Copyright © 2017 Pawel Rup. All rights reserved.
//

import UIKit

public class SlideMenuRightMenuSegue: UIStoryboardSegue {

    override public func perform() {
        let mainVC = self.source as! SlideMenuMainViewController
        let rightMenu = self.destination as! SlideMenuRightTableViewController
        
        mainVC.rightMenu = rightMenu
        rightMenu.mainVC = mainVC
        
        mainVC.addChildViewController(rightMenu)
        
        DispatchQueue.main.asyncAfter(deadline: .now()) { 
            let bounds = mainVC.view.bounds
            rightMenu.view.frame = CGRect(x: bounds.size.width - CGFloat(mainVC.rightMenuWidth), y: 0, width: CGFloat(mainVC.rightMenuWidth), height: bounds.size.height)
        }
        mainVC.view.addSubview(rightMenu.view)
        let initialIndexPath = mainVC.initialIndexPathForRightMenu
        rightMenu.navigationController?.setNavigationBarHidden(true, animated: false)
        
        #if SlideMenuWithoutStoryboards
            rightMenu.tableView(rightMenu.tableView, didSelectRowAt: initialIndexPath)
        #else
            if let navigationController = (mainVC as SlideMenuMultipleStoryboarding).navigationControllerInRightMenu?(for: initialIndexPath) {
                let segue = SlideMenuContentSegue(identifier: "ContentSugue", source: rightMenu, destination: navigationController)
                segue.perform()
            } else if let segueIdentifier = mainVC.segueIdentifierInRightMenu(forIndexPath: initialIndexPath) {
                rightMenu.performSegue(withIdentifier: segueIdentifier, sender: self)
            }
        #endif
    }
}

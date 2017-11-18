//
//  SlideMenuRightTableViewController.swift
//
//  Created by Paweł Rup on 21.07.2017.
//  Copyright © 2017 lobocode. All rights reserved.
//

import UIKit

open class SlideMenuRightTableViewController: UITableViewController {
    
    public var mainVC: SlideMenuMainViewController!
    
    open func open(contentNavigationController navigationController: UINavigationController) {
        #if SlideMenuWithoutStoryboards
            NSLog("This methos is only for NON storyboard use! You must define SlideMenuWithoutStoryboards in other swift flags")
        #else
            let contentSegue = SlideMenuContentSegue(identifier: "contentSegue", source: self, destination: navigationController)
            contentSegue.perform()
        #endif
    }
    
    // MARK: - Table view data source
    
    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let navigationController = (self.mainVC as SlideMenuMultipleStoryboarding).navigationControllerInRightMenu?(for: indexPath) {
            let segue = SlideMenuContentSegue(identifier: "ContentSugue", source: self, destination: navigationController)
            segue.perform()
        } else {
            if let segueIdentifier = self.mainVC.segueIdentifierInRightMenu(forIndexPath: indexPath), segueIdentifier.count > 0 {
                self.performSegue(withIdentifier: segueIdentifier, sender: self)
            }
        }
    }
}

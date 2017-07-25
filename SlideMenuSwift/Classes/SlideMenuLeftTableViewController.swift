//
//  SlideMenuLeftTableViewController.swift
//  SideMenu
//
//  Created by Pawel Rup on 21.07.2017.
//  Copyright © 2017 Pawel Rup. All rights reserved.
//

import UIKit

class SlideMenuLeftTableViewController: UITableViewController {
    
    var mainVC: SlideMenuMainViewController!
    
    func open(contentNavigationController navigationController: UINavigationController) {
        #if SlideMenuWithoutStoryboards
            NSLog("This methos is only for NON storyboard use! You must define SlideMenuWithoutStoryboards in other swift flags")
        #else
            let contentSegue = SlideMenuContentSegue(identifier: "contentSegue", source: self, destination: navigationController)
            contentSegue.perform()
        #endif
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let navigationController = (self.mainVC as SlideMenuMultipleStoryboarding).navigationControllerInLeftMenu?(for: indexPath) {
            let segue = SlideMenuContentSegue(identifier: "ContentSugue", source: self, destination: navigationController)
            segue.perform()
        } else {
            if let segueIdentifier = self.mainVC.segueIdentifierInLeftMenu(forIndexPath: indexPath), segueIdentifier.characters.count > 0 {
                self.performSegue(withIdentifier: segueIdentifier, sender: self)
            }
        }
    }
}

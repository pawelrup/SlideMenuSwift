//
//  MainViewController.swift
//
//  Created by Paweł Rup on 22.07.2017.
//  Copyright © 2017 lobocode. All rights reserved.
//

import UIKit
import SlideMenuSwift

class MainViewController: SlideMenuMainViewController {
    
    lazy var menuButton: SlideMenuHamburgerButton = {
        let button = SlideMenuHamburgerButton(frame: CGRect(origin: .zero, size: CGSize(width: 25, height: 13)))
        button.backgroundColor = .clear
        button.lineColor = .lightGray
        return button
    }()

    // MARK: - Overriden Methods
    
    override func segueIdentifierInLeftMenu(forIndexPath indexPath: IndexPath) -> String? {
        var identifier = ""
        switch indexPath.row {
        case 0:
            identifier = "firstRow"
        case 1:
            identifier = "secondRow"
        default:
            break
        }
        return identifier
    }

    override func segueIdentifierInRightMenu(forIndexPath indexPath: IndexPath) -> String? {
        var identifier = ""
        switch indexPath.row {
        case 0:
            identifier = "firstRow"
        case 1:
            identifier = "secondRow"
        default:
            break
        }
        return identifier
    }
    
    override var segueIdentifierForLeftMenu: String {
        return "leftMenu"
    }
    
    override var segueIdentifierForRightMenu: String {
        return "rightMenu"
    }
    
    override var leftMenuWidth: CGFloat {
        return UIScreen.main.bounds.width * 3/4
    }
    
    override var rightMenuWidth: CGFloat {
        return UIScreen.main.bounds.width * 3/4
    }
    
    override func configureLeftMenuButton() -> UIButton? {
//        let button = UIButton(type: .custom)
//        let frame = CGRect(origin: .zero, size: CGSize(width: 25, height: 13))
//        button.frame = frame
//        button.backgroundColor = .clear
//        button.setImage(UIImage(named: "simpleMenuButton"), for: .normal)
        
        return self.menuButton
    }
    
    override func configureRightMenuButton() -> UIButton? {
        let button = UIButton(type: .custom)
        let frame = CGRect(origin: .zero, size: CGSize(width: 25, height: 13))
        button.frame = frame
        button.backgroundColor = .clear
        button.setImage(UIImage(named: "simpleMenuButton"), for: .normal)
        return button
    }
    
    override func configure(slideLayer layer: CALayer) {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 1
        layer.shadowOffset = .zero
        layer.shadowRadius = 5
        layer.masksToBounds = false
        layer.shadowPath = UIBezierPath(rect: self.view.layer.bounds).cgPath
    }
    
    override var openAnimationOptions: UIViewAnimationOptions {
        return .curveEaseOut
    }
    
    override var closeAnimationOptions: UIViewAnimationOptions {
        return .curveEaseOut
    }
    
    override var primaryMenu: PrimaryMenu {
        return .left
    }
    
    override var deepnessForLeftMenu: Bool {
        return true
    }
    
    override var deepnessForRightMenu: Bool {
        return true
    }
    
    override var maxDarknessWhileLeftMenu: CGFloat {
        return 0.5
    }
    
    override var maxDarknessWhileRightMenu: CGFloat {
        return 0.5
    }
}

// MARK: - SlideMenuDelegate
extension MainViewController: SlideMenuDelegate {
    func leftMenuWillOpen() {
        self.menuButton.set(currentMode: .arrow)
    }
    
    func leftMenuWillClose() {
        self.menuButton.set(currentMode: .hambuger)
    }
}

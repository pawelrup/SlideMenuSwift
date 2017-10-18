//
//  SlideMenuDelegate.swift
//  SideMenu
//
//  Created by Pawel Rup on 21.07.2017.
//  Copyright © 2017 Pawel Rup. All rights reserved.
//

import Foundation

@objc public protocol SlideMenuDelegate: class {
    @objc optional func leftMenuWillOpen()
    @objc optional func leftMenuDidOpen()
    @objc optional func rightMenuWillOpen()
    @objc optional func rightMenuDidOpen()
    @objc optional func leftMenuWillClose()
    @objc optional func leftMenuDidClose()
    @objc optional func rightMenuWillClose()
    @objc optional func rightMenuDidClose()
}

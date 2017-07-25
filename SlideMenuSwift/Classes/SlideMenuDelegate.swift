//
//  SlideMenuDelegate.swift
//  SideMenu
//
//  Created by Pawel Rup on 21.07.2017.
//  Copyright © 2017 Pawel Rup. All rights reserved.
//

import Foundation

protocol SlideMenuDelegate: class {
    func leftMenuWillOpen()
    func leftMenuDidOpen()
    func rightMenuWillOpen()
    func rightMenuDidOpen()
    func leftMenuWillClose()
    func leftMenuDidClose()
    func rightMenuWillClose()
    func rightMenuDidClose()
}

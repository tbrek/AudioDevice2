//
//  AppDelegate.swift
//  AudioDevice
//
//  Created by Sunnyyoung on 2017/8/4.
//  Copyright © 2017年 Sunnyyoung. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        AudioDeviceListener.shared.startListener()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        AudioDeviceListener.shared.stopListener()
    }

}

//
//  AppDelegate.swift
//  AudioDevice
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

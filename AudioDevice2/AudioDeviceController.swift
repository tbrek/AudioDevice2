//
//  AudioDeviceController.swift
//  AudioSwitcher
//


import Cocoa
import CoreServices
import CoreAudio

var temporaryName = "Start"
var counter = 0
var trimmed1: String!
var trimmed2: String!
var currentOutputDevice: String!
var currentInputDevice: String!

class AudioDeviceController: NSObject {
    var menu: NSMenu!
    private var statusItem: NSStatusItem!
    
    
    override init() {
        super.init()
        self.setupItems()
        NotificationCenter.addObserver(observer: self, selector: #selector(reloadMenu), name: .audioDevicesDidChange)
        NotificationCenter.addObserver(observer: self, selector: #selector(reloadMenu), name: .audioOutputDeviceDidChange)
        NotificationCenter.addObserver(observer: self, selector: #selector(reloadMenu), name: .audioInputDeviceDidChange)
    }

    deinit {
        NotificationCenter.removeObserver(observer: self, name: .audioDevicesDidChange)
    }

    private func setupItems() {
        self.menu = {
            let menu = NSMenu()
            menu.delegate = self
            return menu
        }()
        self.statusItem = {
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            item.target = self
            item.menu = self.menu
            return item
        }()
        reloadMenu()
    }

    @objc func getCurrentOutput() {
        let task = Process()
        task.launchPath = "/Applications/AudioDevice.app/Contents/Resources/audiodevice"
        task.arguments = ["output"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.launch()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
        trimmed1 = output.replacingOccurrences(of: "\n", with: "") as String
        currentOutputDevice = trimmed1 as String
    }
    
    @objc func getCurrentInput() {
        let task2 = Process()
        task2.launchPath = "/Applications/AudioDevice.app/Contents/Resources/audiodevice"
        task2.arguments = ["input"]
        let pipe2 = Pipe()
        task2.standardOutput = pipe2
        task2.standardError = pipe2
        task2.launch()
        task2.waitUntilExit()
        let data2 = pipe2.fileHandleForReading.readDataToEndOfFile()
        let input: String = NSString(data: data2, encoding: String.Encoding.utf8.rawValue)! as String
        trimmed2 = input.replacingOccurrences(of: "\n", with: "") as String
        currentInputDevice = trimmed2 as String
    }
    
    @objc func updateMenu() {
        getCurrentInput()
        getCurrentOutput()
        trimmed1 = trimmed1 + "\n"
        let outputDevice = NSAttributedString(string: trimmed1, attributes: [ NSAttributedStringKey.font: NSFont.systemFont(ofSize: 7)])
        let inputDevice = NSAttributedString(string: trimmed2, attributes: [ NSAttributedStringKey.font: NSFont.systemFont(ofSize: 7)])
        let combination = NSMutableAttributedString()
        combination.append(outputDevice)
        combination.append(inputDevice)
        self.statusItem.attributedTitle = combination
        var iconTemp = currentOutputDevice
        if iconTemp?.range(of: "BT") != nil {
            iconTemp = "BT"
        }
        switch iconTemp {
        case "BT"?:
            let icon = NSImage(named: NSImage.Name(rawValue: "Bluetooth"))
            icon?.isTemplate = true
            statusItem.image = icon
        case "Internal Speakers"?:
            let icon = NSImage(named: NSImage.Name(rawValue: "Internal Speakers"))
            icon?.isTemplate = true
            statusItem.image = icon
        case "Display Audio"?:
            let icon = NSImage(named: NSImage.Name(rawValue: "Display Audio"))
            icon?.isTemplate = true
            statusItem.image = icon
        case "Headphones"?:
            let icon = NSImage(named: NSImage.Name(rawValue: "Headphones"))
            icon?.isTemplate = true
            statusItem.image = icon
        default:
            statusItem.image = nil
        }
        
        
        
    }
    
    @objc func reloadMenu() {
        self.menu.removeAllItems()
        self.menu.addItem(NSMenuItem(title: NSLocalizedString("Output Device:", comment: "")))
        self.menu.addItem(NSMenuItem.separator())
        self.menu.addItem(NSMenuItem(title: NSLocalizedString("Input Device:", comment: "")))
        self.menu.addItem(NSMenuItem.separator())
        self.menu.addItem(NSMenuItem(title: NSLocalizedString("Quit", comment: ""), target: self, action: #selector(quitAction(_:)), keyEquivalent: "q"))
        updateMenu()
        
    }
    
//        let listener = AudioDeviceListener.shared
//        self.menu.removeAllItems()
//        self.menu.addItem(NSMenuItem(title: NSLocalizedString("OutputDevices", comment: "")))
//        listener.devices.forEach { (device) in
//            guard device.type == .output else {
//                return
//            }
//            self.menu.addItem({
//                let item = NSMenuItem(title: device.name, target: self, action: #selector(selectOutputDeviceAction(_:)))
//                item.tag = Int(device.id)
//                item.state = listener.selectedOutputDeviceID == device.id ? .on : .off
//                return item
//                }())
//        }
//        self.menu.addItem(NSMenuItem.separator())
//        self.menu.addItem(NSMenuItem(title: NSLocalizedString("InputDevices", comment: "")))
//        listener.devices.forEach { (device) in
//            guard device.type == .input else {
//                return
//            }
//            self.menu.addItem({
//                let item = NSMenuItem(title: device.name, target: self, action: #selector(selectInputDeviceAction(_:)))
//                item.tag = Int(device.id)
//                item.state = listener.selectedInputDeviceID == device.id ? .on : .off
//                return item
//            }())
//        }
//        self.menu.addItem(NSMenuItem.separator())
//        self.menu.addItem(NSMenuItem(title: NSLocalizedString("Quit", comment: ""), target: self, action: #selector(quitAction(_:)), keyEquivalent: "q"))
////        statusItem.title = temporaryName
//        self.menu.update()
    

    // MARK: Event method
    @objc private func selectOutputDeviceAction(_ sender: NSMenuItem) {
        
    }

    @objc private func selectInputDeviceAction(_ sender: NSMenuItem) {
        
    }

    @objc private func quitAction(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(nil)
    }
}

extension AudioDeviceController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        NSLog("Click on menu")
//        self.updateMenu()
    }
}


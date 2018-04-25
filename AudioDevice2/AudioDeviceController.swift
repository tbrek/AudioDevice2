//
//  AudioDeviceController.swift
//  AudioSwitcher
//


import Cocoa
import CoreServices
import CoreAudio

var temporaryName = "Start"
var counter = 0

class AudioDeviceController: NSObject {
    var menu: NSMenu!
    private var statusItem: NSStatusItem!
    
    
    override init() {
        super.init()
        self.setupItems()
        NotificationCenter.addObserver(observer: self, selector: #selector(reloadMenu), name: .audioDevicesDidChange)
        NotificationCenter.addObserver(observer: self, selector: #selector(outputChanged), name: .audioOutputDeviceDidChange)
        NotificationCenter.addObserver(observer: self, selector: #selector(inputChanged), name: .audioInputDeviceDidChange)
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
            item.image = #imageLiteral(resourceName: "StatusItem")
            item.target = self
            item.menu = self.menu
            item.title = temporaryName
            return item
        }()
    }

    @objc func outputChanged() {
        temporaryName = "Output"
        reloadMenu()
    }
    
    @objc func inputChanged() {
        temporaryName = "Input"
        reloadMenu()
    }
    
    @objc func reloadMenu() {
        let listener = AudioDeviceListener.shared
        self.menu.removeAllItems()
        self.menu.addItem(NSMenuItem(title: NSLocalizedString("OutputDevices", comment: "")))
        listener.devices.forEach { (device) in
            guard device.type == .output else {
                return
            }
            self.menu.addItem({
                let item = NSMenuItem(title: device.name, target: self, action: #selector(selectOutputDeviceAction(_:)))
                item.tag = Int(device.id)
                item.state = listener.selectedOutputDeviceID == device.id ? .on : .off
                return item
                }())
        }
        self.menu.addItem(NSMenuItem.separator())
        self.menu.addItem(NSMenuItem(title: NSLocalizedString("InputDevices", comment: "")))
        listener.devices.forEach { (device) in
            guard device.type == .input else {
                return
            }
            self.menu.addItem({
                let item = NSMenuItem(title: device.name, target: self, action: #selector(selectInputDeviceAction(_:)))
                item.tag = Int(device.id)
                item.state = listener.selectedInputDeviceID == device.id ? .on : .off
                return item
            }())
        }
        self.menu.addItem(NSMenuItem.separator())
        self.menu.addItem(NSMenuItem(title: NSLocalizedString("Quit", comment: ""), target: self, action: #selector(quitAction(_:)), keyEquivalent: "q"))
//        statusItem.title = temporaryName
        self.menu.update()
    }

    // MARK: Event method
    @objc private func selectOutputDeviceAction(_ sender: NSMenuItem) {
        let listener = AudioDeviceListener.shared
        guard let device = listener.devices.first(where: {$0.id == UInt32(sender.tag)}) else {
            return
        }
        listener.selectedOutputDeviceID = listener.selectedOutputDeviceID != device.id ? device.id : nil
    }

    @objc private func selectInputDeviceAction(_ sender: NSMenuItem) {
        let listener = AudioDeviceListener.shared
        guard let device = listener.devices.first(where: {$0.id == UInt32(sender.tag)}) else {
            return
        }
        listener.selectedInputDeviceID = listener.selectedInputDeviceID != device.id ? device.id : nil
    }

    @objc private func quitAction(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(nil)
    }
}

extension AudioDeviceController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        temporaryName = "Kliknąłem"
        self.reloadMenu()
    }
}


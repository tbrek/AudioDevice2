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
var inputsArray: [String]!
var outputsArray: [String]!
let volumeSlider = NSSlider(frame: NSRect(x: 20, y: 0, width: 200, height: 19))
let audiodevicePath = "/Applications/Audiodevice.app/Contents/Resources/audiodevice"


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
        NotificationCenter.removeObserver(observer: self, name: .audioOutputDeviceDidChange)
        NotificationCenter.removeObserver(observer: self, name: .audioInputDeviceDidChange)
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
        task.launchPath = audiodevicePath
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
        let task = Process()
        task.launchPath = audiodevicePath
        task.arguments = ["input"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.launch()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let input: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
        trimmed2 = input.replacingOccurrences(of: "\n", with: "") as String
        currentInputDevice = trimmed2 as String
    }
    
    @objc func getInputs() {
        let task = Process()
        task.launchPath = audiodevicePath
        task.arguments = ["input", "list"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.launch()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        var inputs: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
        inputs = String(inputs.dropLast())
        inputsArray = inputs.components(separatedBy: ["\n"])
    }
    
    @objc func getOutputs() {
        let task = Process()
        task.launchPath = audiodevicePath
        task.arguments = ["output", "list"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.launch()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        var outputs: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
        outputs = String(outputs.dropLast())
        outputsArray = outputs.components(separatedBy: ["\n"])
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
        if ((iconTemp?.range(of: "BT") != nil) || (iconTemp?.range(of: "Bose") != nil)) {
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
        getCurrentInput()
        getCurrentOutput()
        getInputs()
        getOutputs()
        self.menu.removeAllItems()
        self.menu.addItem(NSMenuItem(title: "Volume:", target:self))
        
        let volumeSliderView = NSView(frame: NSRect(x: 0, y: 0, width: 250, height: 19))
        let volumeItem = NSMenuItem()
        volumeSliderView.addSubview(volumeSlider)
        volumeSlider.minValue = 0.0
        volumeSlider.maxValue = 1
        volumeSlider.floatValue = 0.5
        volumeSlider.target = self
        volumeSlider.action = #selector(setDeviceVolume)
        volumeItem.view = volumeSliderView
//        volumeSlider.isContinuous = true
//        mySlider.addTarget(self, action: #selector(NSViewController.sliderValueDidChange(_:)), for: .valueChanged)
        self.menu.addItem(volumeItem)
        
        
        self.menu.addItem(NSMenuItem(title: NSLocalizedString("Output Device:", comment: "")))
        outputsArray.forEach { device in
            self.menu.addItem({
                let item = NSMenuItem(title: device, target: self, action: #selector(selectOutputDeviceActions(_ :)))
                item.state = currentOutputDevice == device ? .on : .off
                return item
                }())
        }
        self.menu.addItem(NSMenuItem.separator())
        self.menu.addItem(NSMenuItem(title: NSLocalizedString("Input Device:", comment: "")))
        inputsArray.forEach { device in
            self.menu.addItem({
                let item = NSMenuItem(title: device, target: self, action: #selector(selectInputDeviceAction(_:)))
                item.state = currentInputDevice == device ? .on : .off
                return item
                }())
        }
        self.menu.addItem(NSMenuItem.separator())
        self.menu.addItem(NSMenuItem(title: "Sound Preferences...", target: self, action: #selector(openSoundPreferences(_:))))
        self.menu.addItem(NSMenuItem.separator())
        self.menu.addItem(NSMenuItem(title: NSLocalizedString("Quit", comment: ""), target: self, action: #selector(quitAction(_:)), keyEquivalent: "q"))
        updateMenu()
        
    }
    
    @objc func selectOutputDeviceActions(_ sender: NSMenuItem) {
        let task = Process()
        task.launchPath = audiodevicePath
        task.arguments = ["output", sender.title]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.launch()
        task.waitUntilExit()
        updateMenu()
//        reloadMenu()
    }

    @objc func selectInputDeviceAction(_ sender: NSMenuItem) {
        let task = Process()
        task.launchPath = audiodevicePath
        task.arguments = ["input", sender.title]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.launch()
        task.waitUntilExit()
        updateMenu()
//        reloadMenu()
    }

    @objc func openSoundPreferences(_ sender: Any) {
        NSWorkspace.shared.openFile("/System/Library/PreferencePanes/Sound.prefPane")
    }
    
    @objc private func quitAction(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(nil)
    }
    
    func getDeviceVolume() {
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var deviceID = kAudioDeviceUnknown
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioHardwarePropertyDefaultOutputDevice),
            mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &propertySize, &deviceID)
        let channelsCount = 2
        var channels = [UInt32](repeating: 0, count: channelsCount)
        propertySize = UInt32(MemoryLayout<UInt32>.size * channelsCount)
        var leftLevel = Float32(-1)
        var rigthLevel = Float32(-1)
        propertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioDevicePropertyPreferredChannelsForStereo),
            mScope: AudioObjectPropertyScope(kAudioDevicePropertyScopeOutput),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
        let status = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, &channels)
        propertyAddress.mSelector = kAudioDevicePropertyVolumeScalar
        propertySize = UInt32(MemoryLayout<Float32>.size)
        propertyAddress.mElement = channels[0]
        AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, &leftLevel)
        propertyAddress.mElement = channels[1]
        AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, &rigthLevel)
        print(leftLevel, rigthLevel)
        volumeSlider.floatValue = leftLevel
    }
    
    @objc func setDeviceVolume(slider: NSSlider) {
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var deviceID = kAudioDeviceUnknown
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioHardwarePropertyDefaultOutputDevice),
            mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &propertySize, &deviceID)
        let channelsCount = 2
        var channels = [UInt32](repeating: 0, count: channelsCount)
        propertySize = UInt32(MemoryLayout<UInt32>.size * channelsCount)
        var leftLevel = slider.floatValue
        var rigthLevel = slider.floatValue
        propertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioDevicePropertyPreferredChannelsForStereo),
            mScope: AudioObjectPropertyScope(kAudioDevicePropertyScopeOutput),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
        let status = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, &channels)
        propertyAddress.mSelector = kAudioDevicePropertyVolumeScalar
        propertySize = UInt32(MemoryLayout<Float32>.size)
        propertyAddress.mElement = channels[0]
        AudioObjectSetPropertyData(deviceID, &propertyAddress, 0, nil, propertySize, &leftLevel)
        propertyAddress.mElement = channels[1]
        AudioObjectSetPropertyData(deviceID, &propertyAddress, 0, nil, propertySize, &rigthLevel)
        print(leftLevel, rigthLevel)

    }
    
    
    
}

extension AudioDeviceController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        getDeviceVolume()
//        self.updateMenu()
    }
}


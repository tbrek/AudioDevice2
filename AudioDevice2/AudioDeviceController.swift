//
//  AudioDeviceController.swift
//  AudioSwitcher
//


import Cocoa
import CoreServices
import CoreAudio
import CoreImage

var trimmed1: String!
var trimmed2: String!
var currentOutputDevice: String!
var currentInputDevice: String!
var inputsArray: [String]!
var outputsArray: [String]!
let volumeSlider = NSSlider(frame: NSRect(x: 20, y: 0, width: 150, height: 19))
let audiodevicePath = "/Applications/Audiodevice2.app/Contents/Resources/audiodevice"
var leftLevel = Float32(-1)
var rightLevel = Float32(-1)
var icon: NSImage!
var volumeIndicator: String!
var volume = Float32(-1)
var isMuted: Bool!
var muteVal = Float32(-1)
var showInputDevice: Bool!
var showOutputDevice: Bool!
var timer: Timer!
var useShortNames: Bool!
let defaults = UserDefaults.standard

class AudioDeviceController: NSObject {
    var menu: NSMenu!
    private var statusItem: NSStatusItem!
    
    override init() {
        super.init()
        showOutputDevice = defaults.object(forKey: "showOutputDevice") as! Bool?
        showInputDevice  = defaults.object(forKey: "showInputDevice") as! Bool?
        useShortNames = defaults.object(forKey: "useShortNames") as! Bool?
        self.setupItems()
        NotificationCenter.addObserver(observer: self, selector: #selector(reloadMenu), name: .audioDevicesDidChange)
        NotificationCenter.addObserver(observer: self, selector: #selector(reloadMenu), name: .audioOutputDeviceDidChange)
        NotificationCenter.addObserver(observer: self, selector: #selector(reloadMenu), name: .audioInputDeviceDidChange)
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateIcon), userInfo: nil, repeats: true)
    }

    deinit {
        NotificationCenter.removeObserver(observer: self, name: .audioDevicesDidChange)
        NotificationCenter.removeObserver(observer: self, name: .audioOutputDeviceDidChange)
        NotificationCenter.removeObserver(observer: self, name: .audioInputDeviceDidChange)
        timer.invalidate()
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
        if (menu.item(withTitle: "Use Short Names")?.state == .on) {
            trimmed1 = String(trimmed1.prefix(4))
            trimmed2 = String(trimmed2.prefix(4))
        }
        if ((menu.item(withTitle: "Show Output")?.state == .on) && (menu.item(withTitle: "Show Input")?.state == .on)) {
            trimmed1 = trimmed1 + "\n"
            let outputDevice = NSAttributedString(string: trimmed1, attributes: [ NSAttributedStringKey.font: NSFont.systemFont(ofSize: 7)])
            let inputDevice = NSAttributedString(string: trimmed2, attributes: [ NSAttributedStringKey.font: NSFont.systemFont(ofSize: 7)])
            let combination = NSMutableAttributedString()
            combination.append(outputDevice)
            combination.append(inputDevice)
            self.statusItem.attributedTitle = combination
        }
        if ((menu.item(withTitle: "Show Output")?.state == .on) && (menu.item(withTitle: "Show Input")?.state == .off)) {
            self.statusItem.title = trimmed1
        }
        if ((menu.item(withTitle: "Show Output")?.state == .off) && (menu.item(withTitle: "Show Input")?.state == .on)) {
            self.statusItem.title = trimmed2
        }
        if ((menu.item(withTitle: "Show Output")?.state == .off) && (menu.item(withTitle: "Show Input")?.state == .off)) {
            self.statusItem.title = ""
        }
        updateIcon()
    }
    
    @objc func updateIcon() {
        getDeviceVolume()
        var iconTemp = currentOutputDevice
        volume = volumeSlider.floatValue
//        print(volume)
        if (volume < 0.34 && volume > 0)        { volumeIndicator = "_min" }
        if (volume > 0.34 && volume < 0.668)    { volumeIndicator = "_mid" }
        if (volume > 0.668)                     { volumeIndicator = "_max" }
        if (volume == 0)                        { volumeIndicator = "_muted" }
        if isMuted == true                      { volumeIndicator = "_muted" }
        if ((iconTemp?.range(of: "BT") != nil) || (iconTemp?.range(of: "Bose") != nil)) {
            iconTemp = "BT"
        }
        switch iconTemp {
        case "BT"?:
            icon = NSImage(named: NSImage.Name(rawValue: "Bluetooth" + volumeIndicator))
        case "Internal Speakers"?:
            icon = NSImage(named: NSImage.Name(rawValue: "Internal Speakers" + volumeIndicator))
        case "Display Audio"?:
            icon = NSImage(named: NSImage.Name(rawValue: "Display Audio" + volumeIndicator))
        case "Headphones"?:
            icon = NSImage(named: NSImage.Name(rawValue: "Headphones" + volumeIndicator))
        default:
            icon = NSImage(named: NSImage.Name(rawValue: "Default" + volumeIndicator))
        }
        icon?.isTemplate = true
        statusItem.image = icon
    }
    
    @objc func reloadMenu() {
        getCurrentInput()
        getCurrentOutput()
        getInputs()
        getOutputs()
        self.menu.removeAllItems()
        self.menu.addItem(NSMenuItem(title: "Volume:", target:self))
        let volumeSliderView = NSView(frame: NSRect(x: 0, y: 0, width: 170, height: 19))
        let volumeItem = NSMenuItem()
        volumeSliderView.addSubview(volumeSlider)
        volumeSlider.minValue = 0.0
        volumeSlider.maxValue = 1
        volumeSlider.floatValue = 0.5
        volumeSlider.target = self
        volumeSlider.action = #selector(setDeviceVolume)
        volumeItem.view = volumeSliderView
        volumeSlider.isContinuous = true
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
        self.menu.addItem(NSMenuItem(title: "Show Output", target: self, action: #selector(showOutput(_: ))))
        menu.item(withTitle: "Show Output")?.state = showOutputDevice == true ? .on : .off
        self.menu.addItem(NSMenuItem(title: "Show Input", target: self, action: #selector(showInput(_: ))))
        menu.item(withTitle: "Show Input")?.state = showInputDevice == true ? .on : .off
        self.menu.addItem(NSMenuItem(title: "Use Short Names", target: self, action: #selector(useShortNamesClicked(_: ))))
        menu.item(withTitle: "Use Short Names")?.state = useShortNames == true ? .on : .off
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
    }

    @objc func useShortNamesClicked(_ sender: NSMenuItem) {
        if (self.menu.item(withTitle: "Use Short Names")?.state == .on) {
            self.menu.item(withTitle: "Use Short Names")?.state = .off
            useShortNames = false
        }
        else {
            self.menu.item(withTitle: "Use Short Names")?.state = .on
            useShortNames = true
        }
        defaults.set(useShortNames, forKey: "useShortNames")
        updateMenu()
        print(useShortNames)
    }
    
    @objc func openSoundPreferences(_ sender: Any) {
        NSWorkspace.shared.openFile("/System/Library/PreferencePanes/Sound.prefPane")
    }
    
    @objc private func quitAction(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(nil)
    }
    
    @objc private func showOutput(_ sender: NSMenuItem) {
        if (self.menu.item(withTitle: "Show Output")?.state == .on) {
            self.menu.item(withTitle: "Show Output")?.state = .off
            showOutputDevice = false
            }
            else {
            self.menu.item(withTitle: "Show Output")?.state = .on
            showOutputDevice = true
            }
        defaults.set(showOutputDevice, forKey: "showOutputDevice")
        updateMenu()
    }
    
    @objc private func showInput(_ sender: NSMenuItem) {
        if (self.menu.item(withTitle: "Show Input")?.state == .on) {
            self.menu.item(withTitle: "Show Input")?.state = .off
            showInputDevice = false
            }
            else {
                self.menu.item(withTitle: "Show Input")?.state = .on
                showInputDevice = true
            }
        defaults.set(showInputDevice, forKey: "showInputDevice")
        updateMenu()
    }
    
    func getDeviceVolume() {
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var deviceID = kAudioDeviceUnknown
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioHardwarePropertyDefaultOutputDevice),
            mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &propertySize, &deviceID)
        propertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioDevicePropertyMute),
            mScope: AudioObjectPropertyScope(kAudioDevicePropertyScopeOutput),
            mElement: 0)
        AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, &muteVal)
        if muteVal == 0 { isMuted = false }
        else {
            isMuted = true
        }
        let channelsCount = 2
        var channels = [UInt32](repeating: 0, count: channelsCount)
        propertySize = UInt32(MemoryLayout<UInt32>.size * channelsCount)
        propertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioDevicePropertyPreferredChannelsForStereo),
            mScope: AudioObjectPropertyScope(kAudioDevicePropertyScopeOutput),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
        _ = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, &channels)
        propertyAddress.mSelector = kAudioDevicePropertyVolumeScalar
        propertySize = UInt32(MemoryLayout<Float32>.size)
        propertyAddress.mElement = channels[0]
        AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, &leftLevel)
        propertyAddress.mElement = channels[1]
        AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, &rightLevel)
        volumeSlider.floatValue = leftLevel
//        print(leftLevel, rightLevel, muteVal)
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
        leftLevel = slider.floatValue
        rightLevel = slider.floatValue
        propertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioDevicePropertyPreferredChannelsForStereo),
            mScope: AudioObjectPropertyScope(kAudioDevicePropertyScopeOutput),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
        _ = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, &channels)
        propertyAddress.mSelector = kAudioDevicePropertyVolumeScalar
        propertySize = UInt32(MemoryLayout<Float32>.size)
        propertyAddress.mElement = channels[0]
        AudioObjectSetPropertyData(deviceID, &propertyAddress, 0, nil, propertySize, &leftLevel)
        propertyAddress.mElement = channels[1]
        AudioObjectSetPropertyData(deviceID, &propertyAddress, 0, nil, propertySize, &rightLevel)
    }

    @objc func printVolume() {
        print(currentOutputDevice, leftLevel, rightLevel)
    }
}

extension AudioDeviceController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        getDeviceVolume()
    }
}


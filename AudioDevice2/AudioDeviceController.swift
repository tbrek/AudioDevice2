//
//  AudioDeviceController.swift
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
var timer1: Timer!
var timer2: Timer!
var useShortNames: Bool!
var deviceColor: NSColor!
let defaults = UserDefaults.standard
var type: String!
let volumeItem = NSMenuItem()

class AudioDeviceController: NSObject {
    var menu: NSMenu!
    private var statusItem: NSStatusItem!
    
    private weak var preferencesWindow: NSWindow!
    private weak var showInputCheck: NSButton!
    private weak var showOutputCheck: NSButton!
    private weak var useShortNamesCheck: NSButton!
    
    override init() {
        type = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
        let volumeSliderView = NSView(frame: NSRect(x: 0, y: 0, width: 170, height: 19))
                volumeSliderView.addSubview(volumeSlider)
                volumeSlider.minValue = 0.0
                volumeSlider.maxValue = 1
                volumeSlider.floatValue = 0.5
                volumeItem.view = volumeSliderView
                volumeSlider.isContinuous = true
        super.init()
        showOutputDevice = defaults.object(forKey: "showOutputDevice") as! Bool?
        showInputDevice  = defaults.object(forKey: "showInputDevice") as! Bool?
        useShortNames = defaults.object(forKey: "useShortNames") as! Bool?
        self.setupItems()
        NotificationCenter.addObserver(observer: self, selector: #selector(reloadMenu), name: .audioDevicesDidChange)
        NotificationCenter.addObserver(observer: self, selector: #selector(reloadMenu), name: .audioOutputDeviceDidChange)
        NotificationCenter.addObserver(observer: self, selector: #selector(reloadMenu), name: .audioInputDeviceDidChange)
        timer1 = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateIcon), userInfo: nil, repeats: true)
        timer2 = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(checkifHeadphonesSpekers), userInfo: nil, repeats: true)
    }

    deinit {
        NotificationCenter.removeObserver(observer: self, name: .audioDevicesDidChange)
        NotificationCenter.removeObserver(observer: self, name: .audioOutputDeviceDidChange)
        NotificationCenter.removeObserver(observer: self, name: .audioInputDeviceDidChange)
        timer1.invalidate()
        timer2.invalidate()
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
        if (useShortNames == true) {
            switch trimmed1 {
            case "Display Audio"?:
                trimmed1 = "Disp. Audio"
            case "Bose OE"?:
                trimmed1 = "Bose"
            case "Headphones"?:
                trimmed1 = "Head"
            case "Internal Speakers"?:
                trimmed1 = "Int. Speak."
            default:
                trimmed1 = String(trimmed1.prefix(4))
            }
            switch trimmed2 {
            case "Display Audio"?:
                trimmed2 = "Disp. Audio"
            case "Bose OE"?:
                trimmed2 = "Bose"
            case "External Microphone"?:
                trimmed2 = "Ext. Mic"
            case "Internal Microphone"?:
                trimmed2 = "Int. Mic"
            default:
                trimmed2 = String(trimmed2.prefix(4))
            }
        }
        
        if (showOutputDevice == true) && (showInputDevice == true) {
            trimmed1 = trimmed1 + "\n"
            let outputDevice = NSAttributedString(string: trimmed1, attributes: [ NSAttributedStringKey.font: NSFont.systemFont(ofSize: 7)])
            let inputDevice = NSAttributedString(string: trimmed2, attributes: [ NSAttributedStringKey.font: NSFont.systemFont(ofSize: 7)])
            let combination = NSMutableAttributedString()
            combination.append(outputDevice)
            combination.append(inputDevice)
            self.statusItem.attributedTitle = combination
            
        }
        if (showOutputDevice == true) && (showInputDevice == false) {
            self.statusItem.title = trimmed1
        }
        if (showOutputDevice == false) && (showInputDevice == true) {
            self.statusItem.title = trimmed2
        }
        if (showOutputDevice == false) && (showInputDevice == false) {
            self.statusItem.title = ""
        }
        updateIcon()
    }
    
    @objc func checkifHeadphonesSpekers() {
        if (currentOutputDevice == "Internal Speakers" || currentOutputDevice == "Headphones") {
            reloadMenu()
        }
    }
    
    
    @objc func updateIcon() {
        
        type = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
        getDeviceVolume()
        var iconTemp = currentOutputDevice
        volume = volumeSlider.floatValue
        if isMuted == true                      {
            volumeIndicator = "_muted"
        }
        else {
            if (volume < 0.25 && volume > 0)         { volumeIndicator = "_25"  }
            if (volume < 0.50 && volume >= 0.25)     { volumeIndicator = "_50"  }
            if (volume < 0.75 && volume >= 0.50)     { volumeIndicator = "_75"  }
            if (volume >= 0.75)                      { volumeIndicator = "_100" }
            if (volume == 0)                         { volumeIndicator = "_0"   }
        }
        if ((iconTemp?.range(of: "BT") != nil) || (iconTemp?.range(of: "Bose") != nil)) {
            iconTemp = "BT"
        }
        switch iconTemp {
        case "BT"?:
            icon = NSImage(named: NSImage.Name(rawValue: type + "_Bluetooth" + volumeIndicator))
        case "Internal Speakers"?:
            icon = NSImage(named: NSImage.Name(rawValue: type + "_Speakers" + volumeIndicator))
        case "Display Audio"?:
            icon = NSImage(named: NSImage.Name(rawValue: type + "_Display" + volumeIndicator))
        case "Headphones"?:
            icon = NSImage(named: NSImage.Name(rawValue: type + "_Headphones" + volumeIndicator))
        default:
            icon = NSImage(named: NSImage.Name(rawValue: type + "_Default" + volumeIndicator))
        }
        statusItem.image = icon
    }
    
    @objc func reloadMenu() {
        getCurrentInput()
        getCurrentOutput()
        getInputs()
        getOutputs()
        self.menu.removeAllItems()
        self.menu.addItem(NSMenuItem(title: "Volume:", target:self))
        volumeSlider.target = self
        volumeSlider.action = #selector(setDeviceVolume(slider:))
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
        self.menu.addItem(NSMenuItem(title: "Preferences...", target: self, action: #selector(openPreferences(_:))))
        self.menu.addItem(NSMenuItem.separator())
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

    @IBAction func useShortNamesClicked(_ sender: Any) {
        useShortNames = useShortNamesCheck.state == .on ? true : false
        defaults.set(useShortNames, forKey: "useShortNames")
        updateMenu()
    }
    
    @IBAction func showInputClicked(_ sender: Any) {
        showInputDevice = showInputCheck.state == .on ? true : false
        defaults.set(showInputDevice, forKey: "showInputDevice")
        updateMenu()
    }
    
    @IBAction func showOutputClicked(_ sender: Any) {
        showOutputDevice = showOutputCheck.state == .on ? true : false
        defaults.set(showOutputDevice, forKey: "showOutputDevice")
        updateMenu()
    }
    
    @objc func openSoundPreferences(_ sender: Any) {
        NSWorkspace.shared.openFile("/System/Library/PreferencePanes/Sound.prefPane")
    }
    
    @objc func openPreferences(_ sender: Any) {
        showOutputCheck?.state = showOutputDevice == true ? .on : .off
        showInputCheck?.state = showInputDevice == true ? .on : .off
        useShortNamesCheck?.state = useShortNames == true ? .on : .off
        self.preferencesWindow.orderFrontRegardless()
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


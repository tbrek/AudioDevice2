//
//  AudioDeviceController.swift
//

import Cocoa
import CoreServices
import CoreAudio
import CoreImage
import Quartz
import AudioToolbox

var audiodevicePath: String!
var autoPauseOnScreenLock: Bool!
var autoPauseOnOutputChange: Bool!
var hideAppPrefs: Bool!
var commandObject: NSAppleScript!
var currentOutputDevice: String!
var currentInputDevice: String!
var deviceColor: NSColor!
var defaults = UserDefaults.standard
var inputsArray: [String]!
var outputsArray: [String]!

var leftLevel = Float32(-1)
var rightLevel = Float32(-1)
var icon: NSImage!
var iTunesStatus: NSAppleEventDescriptor!

var isMuted: Bool!
var muteVal = Float32(-1)
var showInputDevice: Bool!
var showOutputDevice: Bool!
var spotifyStatus: NSAppleEventDescriptor!
var currentTrackTitle: NSAppleEventDescriptor!
var currentTrackArtist: NSAppleEventDescriptor!
var timer1: Timer!
var timer2: Timer!
var timer3: Timer!
var trimmed1: String!
var trimmed2: String!

var useShortNames: Bool!

var volumeIndicator: String!
var volume = Float32(-1)

let volumeSliderView = NSView(frame: NSRect(x: 0, y: 0, width: 225, height: 19))
let volumeSlider = NSSlider(frame: NSRect(x: 20, y: 0, width: 185, height: 19))
let volumeItem = NSMenuItem()
var middle = 112
let mediaControlPreviousButton       = NSButton(frame: NSRect(x: 62, y: 0, width: 19, height: 19))
let mediaControlPlayPauseButton      = NSButton(frame: NSRect(x: middle-10, y: 0, width: 19, height: 19))
let mediaControlNextButton           = NSButton(frame: NSRect(x: 143, y: 0, width: 19, height: 19))
var mediaControlsView                = NSView(frame: NSRect(x: 0, y:0, width: 225, height:19))
var mediaItem = NSMenuItem()
var nowPlaying = NSMenuItem(title: "  ", action: nil)


var urlPath: URL!
var isSpotifyRunning: Bool = false
var isiTunesRunning: Bool = false
var isSpotifyPlaying: Bool = false
var isiTunesPlaying: Bool = false
var command: String!
var error: NSDictionary?

class AudioDeviceController: NSObject {
    var menu: NSMenu!
    private var statusItem: NSStatusItem!
    private weak var preferencesWindow: NSWindow!
    private weak var showInputCheck: NSButton!
    private weak var showOutputCheck: NSButton!
    private weak var hideAppPrefsCheck: NSButton!
    private weak var useShortNamesCheck: NSButton!
    private weak var autoPauseOnScreenLockCheck: NSButton!
    private weak var autoPauseOnOutputChangeCheck: NSButton!
    private weak var buttonPayPal: NSButton!
    private weak var labelVersion: NSTextField!
    
    override init() {
        
        let launchedBefore = defaults.bool(forKey: "launchedBefore")
        if launchedBefore  {
//            hideAppPrefsCheck?.state = hideAppPrefs == true ? .on : .off
            // Not a first launch
        }
        else {
            // First launch, setting up defaults file
            defaults.set(true, forKey: "launchedBefore")
            defaults.set(true, forKey: "showInputDevice")
            defaults.set(true, forKey: "showOutputDevice")
            defaults.set(true, forKey: "useShortNames")
            defaults.set(true, forKey: "autoPauseOnOutputChange")
            defaults.set(true, forKey: "autoPauseOnScreenLock")
            defaults.set(true, forKey: "hideAppPrefs")
        }
    
        // Setup volumeSlider
        volumeSliderView.addSubview(volumeSlider)
        volumeSlider.minValue = 0.0
        volumeSlider.maxValue = 1
        volumeSlider.floatValue = 0.5
        volumeItem.view = volumeSliderView
        volumeSlider.isContinuous = true
        super.init()
        urlPath = Bundle.main.url(forResource: "audiodevice", withExtension: "")
        audiodevicePath = urlPath.path
        autoPauseOnScreenLock   = defaults.object(forKey: "autoPauseOnScreenLock") as! Bool?
        autoPauseOnOutputChange = defaults.object(forKey: "autoPauseOnOutputChange") as! Bool?
        showOutputDevice        = defaults.object(forKey: "showOutputDevice") as! Bool?
        showInputDevice         = defaults.object(forKey: "showInputDevice") as! Bool?
        useShortNames           = defaults.object(forKey: "useShortNames") as! Bool?
        hideAppPrefs            = defaults.object(forKey: "hideAppPrefs") as! Bool?
        checkPlayers()
        self.setupItems()
        NotificationCenter.addObserver(observer: self, selector: #selector(reloadMenu), name: .audioDevicesDidChange)
        NotificationCenter.addObserver(observer: self, selector: #selector(outputChanged), name: .audioOutputDeviceDidChange)
        NotificationCenter.addObserver(observer: self, selector: #selector(reloadMenu), name: .audioInputDeviceDidChange)
        timer1 = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateIcon), userInfo: nil, repeats: true)
        timer2 = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(checkifHeadphonesSpeakers), userInfo: nil, repeats: true)
        let center = DistributedNotificationCenter.default()
        center.addObserver(self, selector: #selector(screenLocked), name: NSNotification.Name(rawValue: "com.apple.screenIsLocked"), object: nil)
        center.addObserver(self, selector: #selector(screenUnlocked), name: NSNotification.Name(rawValue: "com.apple.screenIsUnlocked"), object: nil)
        
    }

    deinit {
        NotificationCenter.removeObserver(observer: self, name: .audioDevicesDidChange)
        NotificationCenter.removeObserver(observer: self, name: .audioOutputDeviceDidChange)
        NotificationCenter.removeObserver(observer: self, name: .audioInputDeviceDidChange)
        let center = DistributedNotificationCenter.default()
        center.removeObserver(self, forKeyPath: NSNotification.Name(rawValue: "com.apple.screenIsLocked").rawValue)
        center.removeObserver(self, forKeyPath: NSNotification.Name(rawValue: "com.apple.screenIsUnlocked").rawValue)
        timer1.invalidate()
        timer2.invalidate()
    }
        
    @objc func playPause() {
        checkPlayers()
        if (isSpotifyPlaying == true) {
            mediaControlPlayPauseButton.image = NSImage(named: "Pause")
            nowPlaying.isEnabled = true
            pausePlayers()
        } else {
            mediaControlPlayPauseButton.image = NSImage(named: "Play")
            nowPlaying.isEnabled = true
            resumePlayers()
        }
    }
    
    func refreshNowPlaying () {
        command = "tell application \"Spotify\" to set spotifyState to name of the current track"
        commandObject = NSAppleScript(source: command)
        currentTrackTitle = commandObject!.executeAndReturnError(&error)
//        NSLog((currentTrackTitle?.stringValue)!)
        command = "tell application \"Spotify\" to set spotifyState to artist of the current track"
        commandObject = NSAppleScript(source: command)
        currentTrackArtist = commandObject!.executeAndReturnError(&error)
//        NSLog((currentTrackArtist?.stringValue)!)
        let nowPlayingTitleShort = (currentTrackTitle!.stringValue ?? "").prefix(25)
        let nowPlayingArtistShort = (currentTrackArtist!.stringValue ?? "").prefix(25)

        let nowPlayingTitle = NSAttributedString(string: String(nowPlayingTitleShort), attributes: [ NSAttributedString.Key.font: NSFont.systemFont(ofSize: 12)])
        let nowPlayingArtist = NSAttributedString(string: String(nowPlayingArtistShort), attributes: [ NSAttributedString.Key.font: NSFont.systemFont(ofSize: 11)])
        let combination = NSMutableAttributedString()
        
        combination.append(nowPlayingTitle)
        if (nowPlayingTitleShort.count == 25) {
            combination.append(NSAttributedString(string: "..."))
        }
        combination.append(NSAttributedString(string: "\n"))
        combination.append(nowPlayingArtist)
        combination.append(NSAttributedString(string: "\n", attributes: [NSAttributedString.Key.font: NSFont.systemFont(ofSize: 6)]))
        nowPlaying.attributedTitle = combination
        nowPlaying.isEnabled = true

    }
    
    @objc func next() {
        if (isSpotifyRunning == true) {
            command = "if application \"Spotify\" is running then tell application \"Spotify\" to next track"
            commandObject = NSAppleScript(source: command)
            commandObject!.executeAndReturnError(&error)
            mediaControlPlayPauseButton.image = NSImage(named: "Pause")
            command = "tell application \"Spotify\" to set spotifyState to (player state as text)"
            commandObject = NSAppleScript(source: command)
            spotifyStatus = commandObject!.executeAndReturnError(&error)
            refreshNowPlaying()
        }
        
        if (isiTunesRunning == true) {
            command = "if application \"iTunes\" is running then tell application \"iTunes\" to next track"
            commandObject = NSAppleScript(source: command)
            commandObject!.executeAndReturnError(&error)
            mediaControlPlayPauseButton.image = NSImage(named: "Pause")
            command = "tell application \"iTunes\" to set iTunesState to (player state as text)"
            commandObject = NSAppleScript(source: command)
            iTunesStatus = commandObject!.executeAndReturnError(&error)
            refreshNowPlaying()
        }
    }
    
    @objc func previous() {
        if (isSpotifyRunning == true) {
            command = "if application \"Spotify\" is running then tell application \"Spotify\" to previous track"
            commandObject = NSAppleScript(source: command)
            commandObject!.executeAndReturnError(&error)
            mediaControlPlayPauseButton.image = NSImage(named: "Pause")
            command = "tell application \"Spotify\" to set spotifyState to (player state as text)"
            commandObject = NSAppleScript(source: command)
            spotifyStatus = commandObject!.executeAndReturnError(&error)
            refreshNowPlaying()
        }
        
        if (isiTunesRunning == true) {
            command = "if application \"iTunes\" is running then tell application \"iTunes\" to previous track"
            commandObject = NSAppleScript(source: command)
            commandObject!.executeAndReturnError(&error)
            mediaControlPlayPauseButton.image = NSImage(named: "Pause")
            command = "tell application \"iTunes\" to set iTunesState to (player state as text)"
            commandObject = NSAppleScript(source: command)
            iTunesStatus = commandObject!.executeAndReturnError(&error)
            refreshNowPlaying()
        }
    }
    
    @objc func outputChanged() {
    if (autoPauseOnOutputChange == true) {
        checkPlayers()
        pausePlayers()
    }
    reloadMenu()
    }
    
    @objc func checkPlayers() {
        let ws = NSWorkspace.shared
        let apps = ws.runningApplications
        isSpotifyRunning = false
        isiTunesRunning = false
        for currentApp in apps
            {
                if (currentApp.localizedName == "Spotify") {
                    isSpotifyRunning = true
                    command = "tell application \"Spotify\" to set spotifyState to (player state as text)"
                    commandObject = NSAppleScript(source: command)
                    spotifyStatus = commandObject!.executeAndReturnError(&error)
                    if (spotifyStatus?.stringValue == "playing") {
                        mediaControlPlayPauseButton.image = NSImage(named: "Pause")
                        nowPlaying.isEnabled = true
                        isSpotifyPlaying = true
                        
                    } else {
                        mediaControlPlayPauseButton.image = NSImage(named: "Play")
                        isSpotifyPlaying = false
                    }
                    refreshNowPlaying()
                }
                
                if (currentApp.localizedName == "iTunes") {
                    isiTunesRunning = true
                    command = "tell application \"iTunes\" to set iTunesState to (player state as text)"
                    commandObject = NSAppleScript(source: command)
                    iTunesStatus = commandObject!.executeAndReturnError(&error)
                    if (iTunesStatus?.stringValue == "playing") {
                        mediaControlPlayPauseButton.image = NSImage(named: "Pause")
                        nowPlaying.isEnabled = true
                    } else {
                        mediaControlPlayPauseButton.image = NSImage(named: "Play")
                    }
                }
            }
    }
    
    @objc func resumePlayers() {
        if (isSpotifyRunning == true) {
            command = "if application \"Spotify\" is running then tell application \"Spotify\" to play"
            commandObject = NSAppleScript(source: command)
            commandObject!.executeAndReturnError(&error)
            mediaControlPlayPauseButton.image = NSImage(named: "Pause")
//            command = "tell application \"Spotify\" to set spotifyState to (player state as text)"
//            commandObject = NSAppleScript(source: command)
//            spotifyStatus = commandObject!.executeAndReturnError(&error)
            isSpotifyPlaying = true
        }
        
        if (isiTunesRunning == true) {
            command = "if application \"iTunes\" is running then tell application \"iTunes\" to play"
            commandObject = NSAppleScript(source: command)
            commandObject!.executeAndReturnError(&error)
            mediaControlPlayPauseButton.image = NSImage(named: "Pause")
//            command = "tell application \"iTunes\" to set iTunesState to (player state as text)"
//            commandObject = NSAppleScript(source: command)
//            iTunesStatus = commandObject!.executeAndReturnError(&error)
            isiTunesPlaying = true
        }
    }
    
    
    @objc func pausePlayers() {
        if (isSpotifyRunning == true) {
//            command = "tell application \"Spotify\" to set spotifyState to (player state as text)"
//            commandObject = NSAppleScript(source: command)
//            spotifyStatus = commandObject!.executeAndReturnError(&error)
            command = "if application \"Spotify\" is running then tell application \"Spotify\" to pause"
            commandObject = NSAppleScript(source: command)
            commandObject!.executeAndReturnError(&error)
            mediaControlPlayPauseButton.image = NSImage(named: "Play")
            isSpotifyPlaying = false
        }
        
        if (isiTunesRunning == true) {
//            command = "tell application \"iTunes\" to set iTunesState to (player state as text)"
//            commandObject = NSAppleScript(source: command)
//            iTunesStatus = commandObject!.executeAndReturnError(&error)
            command = "if application \"iTunes\" is running then tell application \"iTunes\" to pause"
            commandObject = NSAppleScript(source: command)
            commandObject!.executeAndReturnError(&error)
            mediaControlPlayPauseButton.image = NSImage(named: "Play")
            isiTunesPlaying = false
        }
    }
    
    @objc func screenLocked() {
        if (autoPauseOnScreenLock == true) {
            checkPlayers()
            pausePlayers()
        }
        
    }
    
    @objc func screenUnlocked() {
        if (spotifyStatus?.stringValue == "playing") {
            let command = "if application \"Spotify\" is running then tell application \"Spotify\" to play"
            let commandObject = NSAppleScript(source: command)
            var error: NSDictionary?
            commandObject!.executeAndReturnError(&error)
            mediaControlPlayPauseButton.image = NSImage(named: "Pause")
        }
        
        if (iTunesStatus?.stringValue == "playing") {
            let command = "if application \"iTunes\" is running then tell application \"iTunes\" to play"
            let commandObject = NSAppleScript(source: command)
            var error: NSDictionary?
            commandObject!.executeAndReturnError(&error)
            mediaControlPlayPauseButton.image = NSImage(named: "Play")
        }
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
            case "MacBook Pro Speakers"?:
                trimmed1 = "MB Speak."
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
            case "MacBook Pro Microphone"?:
                trimmed2 = "MB Mic"
            default:
                trimmed2 = String(trimmed2.prefix(4))
            }
        }
        
        if (showOutputDevice == true) && (showInputDevice == true) {
            trimmed1 = trimmed1 + "\n"
            let outputDevice = NSAttributedString(string: trimmed1, attributes: [ NSAttributedString.Key.font: NSFont.systemFont(ofSize: 7)])
            let inputDevice = NSAttributedString(string: trimmed2, attributes: [ NSAttributedString.Key.font: NSFont.systemFont(ofSize: 7)])
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
    
    @objc func checkifHeadphonesSpeakers() {
        if (currentOutputDevice == "Internal Speakers" || currentOutputDevice == "Headphones" || currentOutputDevice == "MacBook Pro Speakers") {
//            reloadMenu()
        }
    }
    
    @objc func updateIcon() {
//        checkPlayers()

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
            icon = NSImage(named: "Bluetooth" + volumeIndicator)
        case "Internal Speakers"?:
            icon = NSImage(named: "Speakers" + volumeIndicator)
        case "MacBook Pro Speakers"?:
            icon = NSImage(named: "Speakers" + volumeIndicator)
        case "Display Audio"?:
            icon = NSImage(named: "Display" + volumeIndicator)
        case "Headphones"?:
            icon = NSImage(named: "Headphones" + volumeIndicator)
        default:
            icon = NSImage(named: "Default" + volumeIndicator)
        }
        statusItem.image = icon
        
    }
    
    @objc func bringPlayerToFrom() {
        if (isSpotifyRunning == true && isiTunesPlaying == false) {
            NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications/Spotify.app"))
        }
        if (isiTunesRunning == true && isSpotifyPlaying == false) {
            NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications/iTunes.app"))
        }
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
        

        let nowPlayingHeader = NSMenuItem(title: "", action:nil)
        nowPlayingHeader.attributedTitle = NSAttributedString(string: "Now playing:", attributes: [ NSAttributedString.Key.font: NSFont.systemFont(ofSize: 12)])
        self.menu.addItem(nowPlayingHeader)
        
        self.menu.addItem(nowPlaying)
        nowPlaying.action = #selector(bringPlayerToFrom)
        nowPlaying.target = self
        
        nowPlaying.attributedTitle = NSAttributedString(string: "", attributes: [ NSAttributedString.Key.font: NSFont.systemFont(ofSize: 12)])
        // Create media controls\

//        mediaControlsView.setFrameSize(NSSize(width: 200, height: 19))
        mediaControlPreviousButton.image = NSImage(named: "Previous")
        mediaControlPreviousButton.target = self
        mediaControlPreviousButton.action = #selector(previous)
        mediaControlPreviousButton.isBordered = false
        mediaControlsView.addSubview(mediaControlPreviousButton)
        mediaControlPlayPauseButton.image = NSImage(named: "Play")
        mediaControlPlayPauseButton.target = self
        mediaControlPlayPauseButton.action = #selector(playPause)
        mediaControlPlayPauseButton.isBordered = false
        mediaControlsView.addSubview(mediaControlPlayPauseButton)
        mediaControlNextButton.image = NSImage(named: "Next")
        mediaControlNextButton.target = self
        mediaControlNextButton.action = #selector(next)
        mediaControlNextButton.isBordered = false
        mediaControlsView.addSubview(mediaControlNextButton)
        mediaItem.view = mediaControlsView
        self.menu.addItem(mediaItem)
        
        self.menu.addItem(NSMenuItem.separator())
        
        self.menu.addItem(NSMenuItem(title: "Sound Preferences...", target: self, action: #selector(openSoundPreferences(_:))))
        self.menu.addItem(NSMenuItem(title: "Preferences...", target: self, action: #selector(openPreferences(_:))))
        self.menu.addItem(NSMenuItem.separator())
        self.menu.addItem(NSMenuItem.separator())
        self.menu.addItem(NSMenuItem(title: NSLocalizedString("Quit", comment: ""), target: self, action: #selector(quitAction(_:)), keyEquivalent: "q"))
        menu.item(withTitle: "Quit")?.isHidden = true
        menu.item(withTitle: "Preferences...")?.isHidden = true

        // Reisze volumeSliderView & volumeSlider if needed
//        volumeSliderView.setFrameSize(NSSize(width: 200, height: 19))
//        NSLog("Menu %f", menu.size.width)
//        volumeSlider.setFrameSize(NSSize(width: 160, height: 19))
        
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
    
    @IBAction func autoPauseOnScreenClicked(_ sender: Any) {
        autoPauseOnScreenLock = autoPauseOnScreenLockCheck.state == .on ? true : false
        defaults.set(autoPauseOnScreenLock, forKey: "autoPauseOnScreenLock")
    }
    
    @IBAction func autoPauseOnOutputChangeClicked(_ sender: Any) {
        autoPauseOnOutputChange = autoPauseOnOutputChangeCheck.state == .on ? true : false
        defaults.set(autoPauseOnOutputChange, forKey: "autoPauseOnOutputChange")
    }
    
    @IBAction func hideAppPrefsClicked(_ sender: Any) {
        hideAppPrefs = hideAppPrefsCheck.state == .on ? true : false
        defaults.set(hideAppPrefs, forKey: "hideAppPrefs")
    }
    
        
    @objc func openSoundPreferences(_ sender: Any) {
        NSWorkspace.shared.openFile("/System/Library/PreferencePanes/Sound.prefPane")
    }
    
    @objc func openPreferences(_ sender: Any) {
        labelVersion?.stringValue = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
        showOutputCheck?.state = showOutputDevice == true ? .on : .off
        showInputCheck?.state = showInputDevice == true ? .on : .off
        useShortNamesCheck?.state = useShortNames == true ? .on : .off
        hideAppPrefsCheck?.state = hideAppPrefs == true ? .on : .off
        autoPauseOnScreenLockCheck?.state = autoPauseOnScreenLock == true ? .on : .off
        autoPauseOnOutputChangeCheck?.state = autoPauseOnOutputChange == true ? .on : .off
        self.preferencesWindow.orderFrontRegardless()
    }
    
    @objc private func quitAction(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(nil)
    }
    
    @IBAction func donatePayPal(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "https://www.paypal.me/tbrek/")!)
    }
    
    func getDeviceVolume() {
        
        // check if it's muted
        
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
        
        
        var defaultOutputDeviceID = AudioDeviceID(0)
        var defaultOutputDeviceIDSize = UInt32(MemoryLayout.size(ofValue: defaultOutputDeviceID))
        
        var getDefaultOutputDevicePropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
        
        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &getDefaultOutputDevicePropertyAddress,
            0,
            nil,
            &defaultOutputDeviceIDSize,
            &defaultOutputDeviceID)
        
        
        var volume = Float32(0.0)
        var volumeSize = UInt32(MemoryLayout.size(ofValue: volume))
        
        var volumePropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMasterVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMaster)
        
        AudioObjectGetPropertyData(
            defaultOutputDeviceID,
            &volumePropertyAddress,
            0,
            nil,
            &volumeSize,
            &volume)
        volumeSlider.floatValue = volume
    }
    
    @objc func setDeviceVolume(slider: NSSlider) {
        
        var defaultOutputDeviceID = AudioDeviceID(0)
        var defaultOutputDeviceIDSize = UInt32(MemoryLayout.size(ofValue: defaultOutputDeviceID))
        
        var getDefaultOutputDevicePropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
        
        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &getDefaultOutputDevicePropertyAddress,
            0,
            nil,
            &defaultOutputDeviceIDSize,
            &defaultOutputDeviceID)
        
        var volume = Float32(0.50) // 0.0 ... 1.0
        let volumeSize = UInt32(MemoryLayout.size(ofValue: volume))
        
        var volumePropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMasterVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMaster)
        
        volume = slider.floatValue
        AudioObjectSetPropertyData(
            defaultOutputDeviceID,
            &volumePropertyAddress,
            0,
            nil,
            volumeSize,
            &volume)
    }
}

extension AudioDeviceController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        
        if (hideAppPrefs == true ) {
            menu.item(withTitle: "Quit")?.isHidden = true
            menu.item(withTitle: "Preferences...")?.isHidden = true
        } else {
            menu.item(withTitle: "Quit")?.isHidden = false
            menu.item(withTitle: "Preferences...")?.isHidden = false
        }
        
        if NSEvent.modifierFlags.contains(NSEvent.ModifierFlags.option) {
            menu.item(withTitle: "Quit")?.isHidden = false
            menu.item(withTitle: "Preferences...")?.isHidden = false
        }
        
        
        if (isSpotifyRunning == false && isiTunesRunning == false) {
            nowPlaying.attributedTitle = NSAttributedString(string: "No active media player")
            mediaControlPlayPauseButton.isEnabled = false
            mediaControlNextButton.isEnabled = false
            mediaControlPreviousButton.isEnabled = false
        } else {
            mediaControlPlayPauseButton.isEnabled = true
            mediaControlNextButton.isEnabled = true
            mediaControlPreviousButton.isEnabled = true
        }
        checkPlayers()
        getDeviceVolume()
    }
}

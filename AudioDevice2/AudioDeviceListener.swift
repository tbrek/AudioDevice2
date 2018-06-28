//
//  AudioDeviceListener.swift
//  AudioSwitcher
//
//  Copyright © 2018 Tom Brek. All rights reserved.
//

import Cocoa
import CoreServices
import CoreAudio
import AudioToolbox

enum AudioDeviceNotification: String {
    case audioDevicesDidChange
    case audioInputDeviceDidChange
    case audioOutputDeviceDidChange
    var stringValue: String {
        return "AudioDevice" + rawValue
    }

    var notificationName: NSNotification.Name {
        return NSNotification.Name(stringValue)
    }
}

enum AudioDeviceType {
    case output
    case input
}

struct AudioDevice {
    var type: AudioDeviceType
    var id: AudioDeviceID
    var name: String
    var selected: Bool
}

struct AudioAddress {
    static var outputDevice = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice,
                                                         mScope: kAudioObjectPropertyScopeGlobal,
                                                         mElement: kAudioObjectPropertyElementMaster)
    static var inputDevice = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultInputDevice,
                                                        mScope: kAudioObjectPropertyScopeGlobal,
                                                        mElement: kAudioObjectPropertyElementMaster)
    static var devices = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices,
                                                    mScope: kAudioObjectPropertyScopeGlobal,
                                                    mElement: kAudioObjectPropertyElementMaster)
    static var deviceName = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyDeviceNameCFString,
                                                       mScope: kAudioObjectPropertyScopeGlobal,
                                                       mElement: kAudioObjectPropertyElementMaster)
    static var streamConfiguration = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyStreamConfiguration,
                                                                mScope: kAudioDevicePropertyScopeInput,
                                                                mElement: kAudioObjectPropertyElementMaster)
}

struct AudioListener {
    static var devices: AudioObjectPropertyListenerProc = {_, _, _, _ in
        NotificationCenter.post(AudioDeviceNotification: .audioDevicesDidChange)
        return 0
    }

    static var output: AudioObjectPropertyListenerProc = {_, _, _, _ in
        NotificationCenter.post(AudioDeviceNotification: .audioOutputDeviceDidChange)
        return 0
    }

    static var input: AudioObjectPropertyListenerProc = {_, _, _, _ in
        NotificationCenter.post(AudioDeviceNotification: .audioInputDeviceDidChange)
        return 0
    }
}

class AudioDeviceListener {
    static let shared = AudioDeviceListener()
    
    // MARK: Lifecycle
    init() {
        NotificationCenter.addObserver(observer: self, selector: #selector(handleNotification(_:)), name: .audioDevicesDidChange)
        NotificationCenter.addObserver(observer: self, selector: #selector(handleNotification(_:)), name: .audioOutputDeviceDidChange)
        NotificationCenter.addObserver(observer: self, selector: #selector(handleNotification(_:)), name: .audioInputDeviceDidChange)
    }

    deinit {
        NotificationCenter.removeObserver(observer: self, name: .audioDevicesDidChange)
        NotificationCenter.removeObserver(observer: self, name: .audioOutputDeviceDidChange)
        NotificationCenter.removeObserver(observer: self, name: .audioInputDeviceDidChange)
    }

    // MARK: Public method
    func startListener() {
        AudioObjectAddPropertyListener(AudioObjectID(kAudioObjectSystemObject), &AudioAddress.devices, AudioListener.devices, nil)
        AudioObjectAddPropertyListener(AudioObjectID(kAudioObjectSystemObject), &AudioAddress.outputDevice, AudioListener.output, nil)
        AudioObjectAddPropertyListener(AudioObjectID(kAudioObjectSystemObject), &AudioAddress.inputDevice, AudioListener.input, nil)
    }

    func stopListener() {
        AudioObjectRemovePropertyListener(AudioObjectID(kAudioObjectSystemObject), &AudioAddress.devices, AudioListener.devices, nil)
        AudioObjectRemovePropertyListener(AudioObjectID(kAudioObjectSystemObject), &AudioAddress.outputDevice, AudioListener.output, nil)
        AudioObjectRemovePropertyListener(AudioObjectID(kAudioObjectSystemObject), &AudioAddress.inputDevice, AudioListener.input, nil)
    }

    // MARK: Notification handler
    @objc private func handleNotification(_ notification: Notification) {
        if notification.name == AudioDeviceNotification.audioDevicesDidChange.notificationName {
        } else if notification.name == AudioDeviceNotification.audioOutputDeviceDidChange.notificationName {
        } else if notification.name == AudioDeviceNotification.audioInputDeviceDidChange.notificationName {
        }
    }
}

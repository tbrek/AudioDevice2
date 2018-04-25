//
//  AudioDeviceListener.swift
//  AudioSwitcher
//
//  Copyright © 2018 Tom Brek. All rights reserved.
//

import Cocoa
import CoreServices
import CoreAudio

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

//    var devices: [AudioDevice] {
//        let objectID = AudioObjectID(kAudioObjectSystemObject)
//        var address = AudioAddress.devices
//        var size = UInt32(0)
//        AudioObjectGetPropertyDataSize(objectID, &address, 0, nil, &size)
//        var deviceIDs: [AudioDeviceID] = {
//            var deviceIDs = [AudioDeviceID]()
//            for _ in 0..<Int(size) / MemoryLayout<AudioDeviceID>.size {
//                deviceIDs.append(AudioDeviceID())
//            }
//            return deviceIDs
//        }()
//        AudioObjectGetPropertyData(objectID, &address, 0, nil, &size, &deviceIDs)
//        let devices: [AudioDevice] = {
//            var devices = [AudioDevice]()
//            for id in deviceIDs {
//                let name: String = {
//                    var name: CFString = "" as CFString
//                    var address = AudioAddress.deviceName
//                    var size = UInt32(0)
//                    AudioObjectGetPropertyDataSize(id, &address, 0, nil, &size)
//                    AudioObjectGetPropertyData(id, &address, 0, nil, &size, &name)
//                    return name as String
//                }()
//                let type: AudioDeviceType = {
//                    var address = AudioAddress.streamConfiguration
//                    var size = UInt32(0)
//                    AudioObjectGetPropertyDataSize(id, &address, 0, nil, &size)
//                    let bufferList = AudioBufferList.allocate(maximumBuffers: Int(size))
//                    AudioObjectGetPropertyData(id, &address, 0, nil, &size, bufferList.unsafeMutablePointer)
//                    let channelCount: Int = {
//                        var count = 0
//                        for index in 0 ..< Int(bufferList.unsafeMutablePointer.pointee.mNumberBuffers) {
//                            count += Int(bufferList[index].mNumberChannels)
//                        }
//                        return count
//                    }()
//                    free(bufferList.unsafeMutablePointer)
//                    return (channelCount > 0) ? .input : .output
//                }()
//                let device = AudioDevice(type: type, id: id, name: name, selected: true)
//                devices.append(device)
//            }
//            return devices
//        }()
//        return devices
//    }

    var selectedOutputDeviceID: AudioDeviceID? {
        didSet {
            guard var deviceID = self.selectedOutputDeviceID else {
                return
            }
            self.setOutputDevice(id: &deviceID)
        }
    }
    var selectedInputDeviceID: AudioDeviceID? {
        didSet {
            guard var deviceID = self.selectedInputDeviceID else {
                return
            }
            self.setInputDevice(id: &deviceID)
        }
    }

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
            NSLog("Something has changed")
        } else if notification.name == AudioDeviceNotification.audioOutputDeviceDidChange.notificationName {
           NSLog("Output has changed")
        } else if notification.name == AudioDeviceNotification.audioInputDeviceDidChange.notificationName {
           NSLog("Input has changed")
        }
    }

    private func setOutputDevice(id: inout AudioDeviceID) {
//        AudioObjectSetPropertyData(AudioObjectID(kAudioObjectSystemObject), &AudioAddress.outputDevice, 0, nil, UInt32(MemoryLayout<AudioDeviceID>.size), &id)
        
    }

    private func setInputDevice(id: inout AudioDeviceID) {
//        AudioObjectSetPropertyData(AudioObjectID(kAudioObjectSystemObject), &AudioAddress.inputDevice, 0, nil, UInt32(MemoryLayout<AudioDeviceID>.size), &id)
    }
}

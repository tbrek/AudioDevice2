//
//  NotificationCenter+Extension.swift
//  AudioDevice
//

import Cocoa
import Combine

extension NotificationCenter {
    static func post(AudioDeviceNotification name: AudioDeviceNotification, object: Any? = nil) {
        NotificationCenter.default.post(name: name.notificationName, object: object)
    }

    static func addObserver(name: AudioDeviceNotification, object: AnyObject? = nil) -> Publisher {
        NotificationCenter.default.publisher(for: name.notificationName, object: object)
    }
}

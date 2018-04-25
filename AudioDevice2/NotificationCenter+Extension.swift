//
//  NotificationCenter+Extension.swift
//  AudioDevice
//

import Cocoa

extension NotificationCenter {
    static func post(AudioDeviceNotification name: AudioDeviceNotification, object: Any? = nil) {
        NotificationCenter.default.post(name: name.notificationName, object: object)
    }

    static func addObserver(observer: Any, selector: Selector, name: AudioDeviceNotification, object: Any? = nil) {
        NotificationCenter.default.addObserver(observer, selector: selector, name: name.notificationName, object: object)
    }

    static func removeObserver(observer: Any, name: AudioDeviceNotification, object: Any? = nil) {
        NotificationCenter.default.removeObserver(observer, name: name.notificationName, object: object)
    }
}

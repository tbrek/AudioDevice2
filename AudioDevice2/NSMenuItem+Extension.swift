//
//  NSMenuItem+Extension.swift
//  AudioDevice
//

import Cocoa

extension NSMenuItem {
    public convenience init(title string: String, target: AnyObject? = nil, action selector: Selector? = nil, keyEquivalent charCode: String? = nil) {
        self.init(title: string, action: selector, keyEquivalent: charCode ?? "")
        self.target = target
    }
}

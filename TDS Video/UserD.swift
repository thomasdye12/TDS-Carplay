//
//  UserD.swift
//  TDS Video
//
//  Created by Thomas Dye on 25/03/2025.
//



extension UserDefaults {
    @objc dynamic var TDVideoSharedURL: String {
        return string(forKey: "TDVideo-SharedURL")!
    }
}



import UIKit

class TDSVideoURlFromOutSideOFAppListener {
    static let shared = TDSVideoURlFromOutSideOFAppListener()

    private  let notificationName = "group.net.thomasdye.TDS-docs.TDVideo-SharedURL"
    private  let sharedDefaults = UserDefaults(suiteName: "group.net.thomasdye.TDS-docs")

    var onUpdate: ((String) -> Void)?

    private init() {
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            { (_, observer, _, _, _) in
                guard let observer = observer else { return }
                let instance = Unmanaged<TDSVideoURlFromOutSideOFAppListener>.fromOpaque(observer).takeUnretainedValue()
                instance.defaultsChanged()
            },
            notificationName as CFString,
            nil,
            .deliverImmediately
        )
    }

    deinit {
        CFNotificationCenterRemoveObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            CFNotificationName(notificationName as CFString),
            nil
        )
    }

    private func defaultsChanged() {
        let newValue = sharedDefaults?.string(forKey: "TDVideo-SharedURL") ?? ""
        DispatchQueue.main.async {
            self.onUpdate?(newValue)
        }
    }
}

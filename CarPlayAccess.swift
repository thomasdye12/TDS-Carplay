//
//  CarPlayAccess.swift
//  TDS Video
//
//  Created by Thomas Dye on 16/04/2025.
//


import UIKit

class TDSCarplayAccess {
    static var shared = TDSCarplayAccess()

    private let settingsKey = "ShowTDSCarPlaySettings"

    var ShowTDSCarPlaySettings: Bool = true
    var DisableIsStationary: Bool {
        get {
            UserDefaults.standard.bool(forKey: settingsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: settingsKey)
        }
    }


    private init() {
        ShowTDSCarPlaySettings = true
        UserDefaults.standard.set(true, forKey: settingsKey)
    }

    func CheckIfShowCarPlaySettings() {
        ShowTDSCarPlaySettings = true
        UserDefaults.standard.set(true, forKey: settingsKey)
    }

}

struct CarplaySettingsResponse: Decodable {
    let showCarplaySettings: Bool?
}

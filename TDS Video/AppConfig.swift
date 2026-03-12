//
//  AppConfig.swift
//  TDS Video
//
//  Centralised configuration — keeps secrets and endpoints out of scattered source files.
//  For production, consider loading sensitive values from a server-side config or
//  the Keychain instead of bundling them in the binary.
//

import Foundation

enum AppConfig {

    // MARK: - API

    static let apiBaseURL = URL(string: "https://api.thomasdye.net/app/ThomasRandom/TDSVideo")!

    static var trackingURL: URL {
        apiBaseURL.appendingPathComponent("ApppTrackingV2")
    }

    static var paymentVerifyURL: URL {
        apiBaseURL.appendingPathComponent("verifyPayment")
    }

    // MARK: - Payment

    static let paymentBaseURL = "https://payments.thomasdye.net/CP/b82b9c80-b318-47fb-9b2e-b4857cffe42a/"

    // MARK: - Networking

    static let httpServerPort: UInt16 = 8080
    static let screenCapturePort: UInt16 = 12345

    // MARK: - App Groups

    static let sharedDocsGroup = "group.net.thomasdye.TDS-docs"
    static let authCredsGroup  = "group.net.thomasdye.Auth_Creds"

    // MARK: - Contact

    static let supportEmail = "apple@thomasdye.net"
}

//
//  TDSVideoAPI.swift
//  TDS Video
//
//  Created by Thomas Dye on 17/03/2025.
//

import Foundation
import Security
import CommonCrypto
import SwiftUI
import CoreMotion

struct TDSDeviceInfo: Codable {
    let uuid: String
    let openCount: Int
    let latitude: Double?
    let longitude: Double?
    let hasSeenPayment:Bool
}

struct TDSDeviceURL: Codable {
    let url:String
}


class TDSVideoAPI:NSObject,ObservableObject {
    static let shared = TDSVideoAPI()
    private let serverURL = URL(string: "https://api.thomasdye.net/app/ThomasRandom/TDSVideo/ApppTrackingV2")!
    private let pinnedPublicKeyHash = "dLd2Fq91ht5iLfGjD6gNvTt5p6otE41l9Bss5hicNoQ=" // Replace with actual hash
    // dLd2Fq91ht5iLfGjD6gNvTt5p6otE41l9Bss5hicNoQ=
    let motionActivityManager = CMMotionActivityManager()
    var showPayment:Bool = false
    var paymentscreen:UIViewController?
    
    private override init() {
    }
    
    private let callCountKey = "TDSVideoAPICallCount"

    private var callCount: Int {
        get {
            return UserDefaults.standard.integer(forKey: callCountKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: callCountKey)
        }
    }

//    // Stored property for the selected orientation
//        @Published var selectedOrientation: ScreenOrientation {
//            get {
//                // Retrieve the stored value from UserDefaults
//                if let storedValue = UserDefaults.standard.value(forKey: orientationKey) as? Int,
//                   let orientation = ScreenOrientation(rawValue: storedValue) {
//                    return orientation
//                } else {
//                    return .left // Default value if not set
//                }
//            }
//            set {
//                // Store the new value in UserDefaults
//                
//            }
//        }
    
    func DeviceBooted(VC:UIViewController) async {
         let uuid = BackgroundAuthID(DeviceUUID: UUID().uuidString)
        self.showPayment = false
        // Increment call count
           callCount += 1
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
             self.sendDeviceUUID(UUID: uuid,callCount:self.callCount)
        }
        if callCount > 4 {
            self.showPayment = true
        }
        
        
//        let HasSeenPaymentScreenBefore = UserDefaults.standard.string(forKey: "buymeACoffeePressedV2")
//        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
//        if HasSeenPaymentScreenBefore  == buildNumber{
//            self.showPayment = false
//        }
        let PAYMENTTDSVIDEO = UserDefaults.standard.bool(forKey: "PAYMENTTDSVIDEO")
        if PAYMENTTDSVIDEO == true  {
            self.showPayment = false
        }
        if showPayment {
            DispatchQueue.main.async {
                self.paymentscreen =  UIHostingController(rootView: SupportScreen(AppOpenAmount: self.callCount))
                self.paymentscreen?.modalPresentationStyle = .fullScreen
                if let paymentscreen = self.paymentscreen {
                    VC.present(paymentscreen, animated: true)
                }
            }
           
        }
        
    }

    func sendDeviceUUID(UUID:String,callCount:Int) {

        
        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.setValue("Bearer \(auth.GetToken())", forHTTPHeaderField: "Authorization")
        
        // Fetch user's location
        let latitude = TDSLocationAPI.shared.latitude
        let longitude = TDSLocationAPI.shared.longitude

           // Create the request body using the struct
        let deviceInfo = TDSDeviceInfo(uuid: UUID, openCount: callCount, latitude: latitude, longitude: longitude, hasSeenPayment: UserDefaults.standard.bool(forKey: "buymeACoffeePressed"))

           // Convert struct to JSON
        guard let jsonData = try? JSONEncoder().encode(deviceInfo) else {
            print("Failed to encode JSON")
            return
        }
               
               
        request.httpBody = jsonData
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Request failed: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Response status code: \(httpResponse.statusCode)")
            }
        }
        
        task.resume()
        
    }
    
    

    
//
    
    func BuyMeACoffeePressedFromPayment() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
            self.BuyMeACoffeePressedFromPayment()
        })
        
    }
    func HidebyuymeACoffeePressed() {
        UserDefaults.standard.set(true, forKey: "buymeACoffeePressed")
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
        UserDefaults.standard.set(buildNumber, forKey: "buymeACoffeePressedV2")
        self.paymentscreen?.dismiss(animated: true)
    }
    func sendEmail() {
        let subject = "TDS Video Support Request device UUID: \(UIDevice.current.identifierForVendor?.uuidString ?? "")"
          let body = ""
          let email = "apple@thomasdye.net" // Replace with your email
          let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
          let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
          
          if let emailURL = URL(string: "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)") {
              UIApplication.shared.open(emailURL)
              print("Email button pressed")
          }
      }
    

    func deleteOldFiles(from directory: URL, olderThan days: Int) {
        let fileManager = FileManager.default
        let calendar = Calendar.current
        let expirationDate = calendar.date(byAdding: .day, value: -days, to: Date())

        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentModificationDateKey], options: [.skipsHiddenFiles])
            
            for fileURL in fileURLs {
                let resourceValues = try fileURL.resourceValues(forKeys: [.contentModificationDateKey])
                
                if let modificationDate = resourceValues.contentModificationDate,
                   let expirationDate = expirationDate,
                   modificationDate < expirationDate {
                    try fileManager.removeItem(at: fileURL)
                    print("Deleted old file: \(fileURL.lastPathComponent)")
                }
            }
        } catch {
            print("Error while deleting old files: \(error.localizedDescription)")
        }
    }
    
    
    func HidePaymentScreen() {
        UserDefaults.standard.set(true, forKey: "PAYMENTTDSVIDEO")
        self.paymentscreen?.dismiss(animated: true)
        self.showPayment = false
        
    }

    
}

extension TDSVideoAPI: URLSessionDelegate {

}

extension Data {
    func sha256() -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        self.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(self.count), &hash)
        }
        return Data(hash)
    }
}
public enum ScreenOrientation: Int, @unchecked Sendable, CaseIterable {
    case up = 0
    case down = 1
    case left = 2
    case right = 3
    case upMirrored = 4
    case downMirrored = 5
    case leftMirrored = 6
    case rightMirrored = 7
    
    func humanReadable() -> String {
        switch self {
        case .up:
            return "Up"
        case .down:
            return "Down"
        case .left:
            return "Left"
        case .right:
            return "Right"
        case .upMirrored:
            return "Up Mirrored"
        case .downMirrored:
            return "Down Mirrored"
        case .leftMirrored:
            return "Left Mirrored"
        case .rightMirrored:
            return "Right Mirrored"
        }
    }
}

public enum AspectRatio : Int, @unchecked Sendable, CaseIterable {

    case scaleToFill = 0

    case scaleAspectFit = 1

    case scaleAspectFill = 2

    case redraw = 3

    case center = 4

    case top = 5

    case bottom = 6

    case left = 7

    case right = 8

    case topLeft = 9

    case topRight = 10

    case bottomLeft = 11

    case bottomRight = 12
    
    func humanReadableName() -> String {
          switch self {
          case .scaleToFill: return "Scale To Fill"
          case .scaleAspectFit: return "Scale Aspect Fit"
          case .scaleAspectFill: return "Scale Aspect Fill"
          case .redraw: return "Redraw"
          case .center: return "Center"
          case .top: return "Top"
          case .bottom: return "Bottom"
          case .left: return "Left"
          case .right: return "Right"
          case .topLeft: return "Top Left"
          case .topRight: return "Top Right"
          case .bottomLeft: return "Bottom Left"
          case .bottomRight: return "Bottom Right"
          }
      }
    
}


func BackgroundAuthID(DeviceUUID:String?) -> String {
    if let id = UserDefaults.standard.string(forKey: "BackgroundAuthID")  {
        return id
    }
    let newID = (DeviceUUID ?? UUID().uuidString )
    UserDefaults.standard.set(newID, forKey: "BackgroundAuthID")
    return newID
    
}

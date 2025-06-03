//
//  paymentscreen.swift
//  TDS Video
//
//  Created by Thomas Dye on 18/03/2025.
//
import SwiftUI
import UIKit
//struct SupportScreen: View {
//    var AppOpenAmount:Int
//    var body: some View {
//        VStack(spacing: 20) {
//            Image("test1")
//                .resizable()
//                .aspectRatio(contentMode: .fit)
//                .cornerRadius(10)
//                .padding()
//                .frame(width: 150)
//            
//            Text("Support the App")
//                .font(.largeTitle)
//                .bold()
//                .padding(.top)
//            
//            Text("I hope you're enjoying the app! We've noticed you've opened it \(AppOpenAmount) times—awesome! If you find it useful, consider making a contribution to help support its development. Your support keeps the app running smoothly and helps us bring new updates!")
//                .font(.body)
//                .multilineTextAlignment(.center)
//                .padding(.horizontal)
//            
//            Button(action: {
//                       if let url = URL(string: "https://www.buymeacoffee.com/Thomadye") {
//                           UIApplication.shared.open(url)
//                           print("Buy Me a Coffee link pressed")
//                           TDSVideoAPI.shared.BuyMeACoffeePressedFromPayment()
//                       }
//                   }) {
//                       HStack {
//                           Image(systemName: "cup.and.saucer.fill")
//                               .font(.title)
//                           Text("Buy Me a Coffee")
//                               .font(.headline)
//                       }
//                       .foregroundColor(.white)
//                       .padding()
//                       .frame(maxWidth: .infinity)
//                       .background(Color.orange)
//                       .cornerRadius(10)
//                       .padding(.horizontal)
//                   }
//            Button(action: {
//                TDSVideoAPI.shared.sendEmail()
//                    }) {
//                        HStack {
//                            Image(systemName: "envelope.fill")
//                                .font(.title)
//                            Text("Got a bug or issue? Send an email!")
//                                .font(.headline)
//                        }
//                        .foregroundColor(.white)
//                        .padding()
//                        .frame(maxWidth: .infinity)
//                        .background(Color.blue)
//                        .cornerRadius(10)
//                        .padding(.horizontal)
//                    }
//            Button(action: {
//                TDSVideoAPI.shared.HidebyuymeACoffeePressed()
//                    }) {
//                        HStack {
////                            Image(systemName: "envelope.fill")
////                                .font(.title)
//                            Text("Already Donated / Hide ")
//                                .font(.headline)
//                        }
//                        .foregroundColor(.white)
//                        .padding()
//                        .frame(maxWidth: .infinity)
//                        .background(Color.gray)
//                        .cornerRadius(10)
//                        .padding(.horizontal)
//                    }
//            Text("Created by Thomas Dye, Copyright © 2025 Thomas Dye. All rights reserved.")
//                .font(.caption2)
//                .foregroundColor(.secondary)
//            
//            
//        }
//        .padding()
//    }
//}

import SwiftUI

struct SupportScreen: View {
    var AppOpenAmount: Int
    
    var body: some View {
        VStack(spacing: 20) {
            Image("test1")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .cornerRadius(10)
//                .padding(.top)
                .frame(width: 100)
            
            Text("Supporting the App")
                .font(.largeTitle)
                .bold()
            
            // Display app usage and downloads
            Text("Thank you for downloading my App. I Am sure you have heard about it from somewhere. To be able to keep up with demand and provide the best possible experience for you. I have had to make the app a paid experience. I am Sorry for that as I am sure you are not happy about it, however I will make sure to keep the app up to date and you can always contact me with an Issue.")
                .font(.body)
                .multilineTextAlignment(.center)
//                .padding(.horizontal)
            
            Button(action: {
                // TODO: Replace with your actual YouTube channel URL
                if let url = URL(string: "https://payments.thomasdye.net/CP/b82b9c80-b318-47fb-9b2e-b4857cffe42a/?deviceID=\(UIDevice.current.identifierForVendor?.uuidString ?? "SOMEIDNOTKNOW")") {
                    UIApplication.shared.open(url)
                    print("ONE TIME - Payment link link pressed")
                }
            }) {
                HStack {
                    Image(systemName: "link")
                        .font(.title)
                    Text("Pay To use £10")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red)
                .cornerRadius(10)
                .padding(.horizontal)
            }
            
            Text("To see what the app can do you can watch my video on youtube where I show you about it.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button(action: {
                // TODO: Replace with your actual YouTube channel URL
                if let url = URL(string: "https://youtu.be/gI3Tj2KP290") {
                    UIApplication.shared.open(url)
                    print("YouTube Subscribe link pressed")
//                    TDSVideoAPI.shared.HidebyuymeACoffeePressed()
                }
            }) {
                HStack {
                    Image(systemName: "play.rectangle.fill")
                        .font(.title)
                    Text("Watch on YouTube")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red)
                .cornerRadius(10)
                .padding(.horizontal)
            }
            
            // Report bugs
            Button(action: {
                TDSVideoAPI.shared.sendEmail()
            }) {
                HStack {
                    Image(systemName: "envelope.fill")
                        .font(.title)
                    Text("Got a bug or issue? Send an email!")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(10)
                .padding(.horizontal)
            }
            Spacer()
            
//            // Hide view
//            Button(action: {
//                TDSVideoAPI.shared.HidebyuymeACoffeePressed()
//            }) {
//                Text("Already Donated / Hide")
//                    .font(.caption2)
//                    .foregroundColor(.white)
//                    .padding(2)
//                    .frame(maxWidth: .infinity)
//                    .background(Color.gray)
//                    .cornerRadius(10)
//                    .padding(.horizontal)
//            }
            
            // Footer
            Text("Created by Thomas Dye. © 2025 Thomas Dye. All rights reserved.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    SupportScreen(AppOpenAmount: 50)
}

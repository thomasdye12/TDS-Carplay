//
//  paymentscreen.swift
//  TDS Video
//
//  Created by Thomas Dye on 18/03/2025.
//
import SwiftUI

struct SupportScreen: View {
    var AppOpenAmount:Int
    var body: some View {
        VStack(spacing: 20) {
            Image("test1")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .cornerRadius(10)
                .padding()
                .frame(width: 150)
            
            Text("Support the App")
                .font(.largeTitle)
                .bold()
                .padding(.top)
            
            Text("I hope you're enjoying the app! We've noticed you've opened it \(AppOpenAmount) times—awesome! If you find it useful, consider making a contribution to help support its development. Your support keeps the app running smoothly and helps us bring new updates!")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                       if let url = URL(string: "https://www.buymeacoffee.com/Thomadye") {
                           UIApplication.shared.open(url)
                           print("Buy Me a Coffee link pressed")
                           TDSVideoAPI.shared.BuyMeACoffeePressedFromPayment()
                       }
                   }) {
                       HStack {
                           Image(systemName: "cup.and.saucer.fill")
                               .font(.title)
                           Text("Buy Me a Coffee")
                               .font(.headline)
                       }
                       .foregroundColor(.white)
                       .padding()
                       .frame(maxWidth: .infinity)
                       .background(Color.orange)
                       .cornerRadius(10)
                       .padding(.horizontal)
                   }
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
            Button(action: {
                TDSVideoAPI.shared.HidebyuymeACoffeePressed()
                    }) {
                        HStack {
//                            Image(systemName: "envelope.fill")
//                                .font(.title)
                            Text("Already Donated / Hide ")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
            Text("Created by Thomas Dye, Copyright © 2025 Thomas Dye. All rights reserved.")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            
        }
        .padding()
    }
}

#Preview {
    SupportScreen(AppOpenAmount: 50)
}

//
//  WebViewForDRM.swift
//  TDS Video
//
//  Created by Thomas Dye on 13/04/2025.
//

import SwiftUI
import WebKit

struct WebView2: UIViewControllerRepresentable {
//    var url: URL
    
    func makeUIViewController(context: Context) -> CustomSafariController {
        let webViewController = CustomSafariController.shared
//        CustomWebViewController.shared.IsIncar = false
        return webViewController
    }

    func updateUIViewController(_ uiViewController: CustomSafariController, context: Context) {
//        uiViewController.loadURL(url)
    }
    
    
}

struct WebViewContainer2: View {
    @State private var ShowCarButtons: Bool = false
    @State private var showURLInput: Bool = false
    @State private var userInputURL: String = ""

    var body: some View {
        VStack {
            WebView2()

            Spacer()
        }
        .toolbar(content: {
            Button("Google", action: {
                CustomSafariController.shared.loadURL(URL(string: "https://google.com")!)
            })
            
            Button("Send to Car", action: {
                TDSVideoShared.shared.CarPlayComp?(.init(type: .web, URL: nil))
            })
            Menu("More Options") {
                Button("Control Button", action: {
                    ShowCarButtons = true
                })
                Button("Reload", action: {
                    showURLInput = true
                })
            }
            
        })
        .sheet(isPresented: $showURLInput) {
            URLInputSheet(showURLInput: $showURLInput, userInputURL: $userInputURL)
        }
        .sheet(isPresented: $ShowCarButtons) {
            WebViewButtons()
        }
        .ignoresSafeArea(.all)
    }
}



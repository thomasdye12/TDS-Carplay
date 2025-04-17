//
//  ScreenMirroringView.swift
//  TDS Video
//
//  Created by Thomas Dye on 16/04/2025.
//

import SwiftUI


struct ScreenMirroringView: UIViewControllerRepresentable {
    
    var CarPlayVideoImageView: UIImageView = UIImageView()
    
    func makeUIViewController(context: Context) -> UIViewController {
        
         let rootViewController = UIViewController()
            // Remove all existing constraints affecting CarPlayVideoImageView
            NSLayoutConstraint.deactivate(self.CarPlayVideoImageView.constraints)
            self.CarPlayVideoImageView.removeFromSuperview()
            rootViewController.view.addSubview(self.CarPlayVideoImageView)
            self.CarPlayVideoImageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                self.CarPlayVideoImageView.topAnchor.constraint(equalTo: rootViewController.view.topAnchor, constant: 0),
                self.CarPlayVideoImageView.bottomAnchor.constraint(equalTo: rootViewController.view.bottomAnchor, constant: 0),
                self.CarPlayVideoImageView.leadingAnchor.constraint(equalTo: rootViewController.view.leadingAnchor, constant: 0),
                self.CarPlayVideoImageView.trailingAnchor.constraint(equalTo: rootViewController.view.trailingAnchor, constant: 0)
            ])

            rootViewController.view.setNeedsLayout()
            rootViewController.view.layoutIfNeeded()
        
        ScreenCaptureManager.shared.addImageView(imageView: CarPlayVideoImageView,orientation:  .up)
        return rootViewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

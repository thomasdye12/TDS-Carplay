//
//  CarPlayViewContollerProtocal.swift
//  TDS Video
//
//  Created by Thomas Dye on 06/03/2025.
//


import UIKit

open class CarPlayViewControllerProtocol: UIViewController {
    open func loadViewIncar(_ window: UIWindow?) -> CarPlayViewControllerProtocol {
        fatalError("Subclasses must override loadViewInCar(view:)")
    }
}

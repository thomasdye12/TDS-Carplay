//
//  CustomWebViews.swift
//  TDS Video
//
//  Created by Thomas Dye on 21/03/2025.
//


import UIKit

struct ZoomSettings: Codable {
    var widthMultiplier: CGFloat
    var heightMultiplier: CGFloat
    var originX: CGFloat
    var originY: CGFloat
    var originXMultiplier: CGFloat?
    var originYMultiplier: CGFloat?
    var contentZoom: CGFloat?
    var offsetRawValue: String?

    init(
        widthMultiplier: CGFloat,
        heightMultiplier: CGFloat,
        originX: CGFloat,
        originY: CGFloat,
        originXMultiplier: CGFloat? = nil,
        originYMultiplier: CGFloat? = nil,
        contentZoom: CGFloat? = nil,
        offsetRawValue: String? = nil
    ) {
        self.widthMultiplier = widthMultiplier
        self.heightMultiplier = heightMultiplier
        self.originX = originX
        self.originY = originY
        self.originXMultiplier = originXMultiplier
        self.originYMultiplier = originYMultiplier
        self.contentZoom = contentZoom
        self.offsetRawValue = offsetRawValue
    }
}

struct WebQuickSelect: Codable, Identifiable, Equatable {
    var id: UUID
    var title: String
    var urlString: String
}

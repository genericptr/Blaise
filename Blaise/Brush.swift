//
//  Brush.swift
//  Blaise
//
//  Created by Ryan Joseph on 4/8/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Foundation
import CoreGraphics
import AppKit

class Brush {
	var size: Float = 4.0
	var pressure: Float = 1.0
	var color: RGBA8 = RGBA8(255, 0, 0, 255)
	var antialias = true
	var pressureSensitive = true

	func brushSize() -> Float {
		return size * pressure
	}

	func getColor() -> CGColor {
		return color.getColor().cgColor
	}

	func apply(_ context: CGContext) {
	}
}

class PaintBrush: Brush {
	override func apply(_ context: CGContext) {
		context.setBlendMode(.normal)
		context.setShouldAntialias(antialias)
		context.setFillColor(getColor())
		context.setStrokeColor(getColor())
		context.setLineCap(.round)
		context.setLineWidth(CGFloat(brushSize()))
	}
}

class Eraser: Brush {
	override func apply(_ context: CGContext) {
		context.setLineCap(.round)
		context.setLineWidth(CGFloat(brushSize()))
		context.setBlendMode(.clear)
		context.setShouldAntialias(false)
	}
}

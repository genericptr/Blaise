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

enum BrushStates: Int {
	case size, antialias
}

struct BrushState {
	var states: [BrushStates]
	var size: Float
	var antialias: Bool
}

class Brush {
	var size: Float = 8.0
	var pressure: Float = 1.0
	var color: RGBA8 = RGBA8.blackColor()
	var antialias = false
	var pressureEnabled = true
	var accumulate = false
	
	func brushSize() -> Float {
		if pressureEnabled {
			return size * pressure
		} else {
			return size
		}
	}

	func getColor() -> CGColor {
		return color.getColor().cgColor
	}

	func apply(_ context: CGContext) {
	}
}

// MARK: PaintBrush

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

// MARK: Eraser

class Eraser: Brush {
	override func apply(_ context: CGContext) {
		context.setLineCap(.round)
		context.setLineWidth(CGFloat(brushSize()))
		context.setBlendMode(.clear)
		context.setShouldAntialias(false)
	}
}

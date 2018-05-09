//
//  Brush.swift
//  Blaise
//
//  Created by Ryan Joseph on 4/8/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Foundation
import AppKit

class Tool {
	weak var context: RenderContext!
	
	func begin() {}
	func end() {}
	func apply(location: V2) { Fatal("Tool does nothing") }
	func apply(from: V2, to: V2) { Fatal("Tool does nothing") }
}

enum BrushModes {
	case normal, clear
}

enum BrushStates: Int {
	case size, antialias
}

struct BrushState {
	var states: [BrushStates]
	var size: Float
	var antialias: Bool
}

class Brush: Tool {
	var size: Float = 8.0
	var pressure: Float = 1.0
	var color: RGBA8 = RGBA8.blackColor()
	var hardness: Float = 1.0
	var opacity: Float = 1.0
	var flow: Float = 1.0
	
	var antialias = false
	var pressureEnabled = true
	var accumulate = false
	
	func minStrokeLength() -> Float {
		
		var length: Float = 0
//		if size > 1 {
//			length = brushSize() / 5
//			if length < 1 {
//				length = 1
//			}
//		} else {
//			length = 0
//		}
		return length
	}
	
	func brushSize() -> Float {
		if pressureEnabled {
			return size * pressure
		} else {
			return size
		}
	}
	
}

// MARK: PaintBrush

class PaintBrush: Brush {
	var lastLocation: V2?

	override func begin() {
		lastLocation = nil
	}
	
	override func end() {
		lastLocation = nil
		context.overlapPoint = V2i(-1, -1)
	}
	
	override func apply(from: V2, to: V2) {
//		context.strokePoints(from: from, to: to)
		context.brush = self
		context.strokeLine(from: from.trunc(), to: to.trunc())
	}
	
	override func apply(location: V2) {
		
		var from: V2
		if lastLocation == nil {
			from = location
		} else {
			from = lastLocation!
		}
		
		context.brush = self

		if brushSize() > 1 {
			context.strokeLine_aa(from: from, to: location)
//			context.strokeLine(from: from.trunc(), to: location.trunc())
		} else {
			context.strokePoints_aa(from: from, to: location)
//			context.strokePoints(from: from.trunc(), to: location.trunc())
		}

		context.overlapPoint = location.trunc()
		lastLocation = location
	}
}

// MARK: Eraser

class Eraser: Brush {
}

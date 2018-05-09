//
//  RenderAction.swift
//  Blaise
//
//  Created by Ryan Joseph on 4/29/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Foundation
import AppKit
import OpenGL

struct RenderActionPixel {
	var oldColor: RGBA8
	var newColor: RGBA8
	var alpha: UInt8
	var empty: Bool
	
	init(newColor: RGBA8, oldColor: RGBA8, empty: Bool, alpha: UInt8) {
		self.newColor = newColor
		self.oldColor = oldColor
		self.empty = empty
		self.alpha = alpha
	}
	
	init() {
		alpha = 0
		empty = true
		newColor = RGBA8(0, 0, 0, 0)
		oldColor = RGBA8(0, 0, 0, 0)
	}
}

class RenderLastAction {
	var buffer: Matrix<RenderActionPixel>
	var changedPixels: [CellPos]
	var region: Box
	
	func clear() {
		for p in changedPixels {
			buffer[p.x.uint, p.y.uint] = RenderActionPixel()
		}
		changedPixels.removeAll(keepingCapacity: true)
		region = Box.infinite()
	}
	
	func isPixelSet(_ x: UInt, _ y: UInt, alpha: inout UInt8) -> Bool {
		if !buffer[x, y].empty {
			alpha = buffer[x, y].alpha
			return true
		} else {
			return false
		}
	}
	
	func setPixel(_ x: UInt, _ y: UInt, newColor: RGBA8, oldColor: RGBA8, alpha: UInt8) {
		if buffer[x, y].empty {
			buffer[x, y] = RenderActionPixel(newColor: newColor, oldColor: oldColor, empty: false, alpha: alpha)
			changedPixels.append(CellPos(x.int, y.int))
		} else {
			buffer[x, y].newColor = newColor
		}
	}
	
	init(width: UInt, height: UInt) {
		region = Box.infinite()
		changedPixels = []
		buffer = Matrix<RenderActionPixel>(width: width, height: height, defaultValue: RenderActionPixel())
	}
}

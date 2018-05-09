//
//  UndoManager.swift
//  Blaise
//
//  Created by Ryan Joseph on 4/13/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Foundation

struct UndoablePixel {
	var x, y: UInt
	var newColor: RGBA8
	var oldColor: RGBA8
	func getPoint() -> CellPos {
		return CellPos(Int(x), Int(y))
	}
}

class UndoableAction: MemoryUsage {
	var pixels: [UndoablePixel] = []
	var name: String
	
	func calculateTotalMemoryUsage(bytes: inout UInt64) {
		bytes += UInt64(pixels.count * MemoryLayout<UndoablePixel>.stride)
	}

	func addPixel(x: UInt, y: UInt, newColor: RGBA8, oldColor: RGBA8) {
		let newPixel = UndoablePixel(x: x, y: y, newColor: newColor, oldColor: oldColor)
		pixels.append(newPixel)
	}
	
	init(name: String) {
		self.name = name
	}
}

class UndoManager: MemoryUsage {
	var stack: [UndoableAction] = []
	
	func calculateTotalMemoryUsage(bytes: inout UInt64) {
		for action in stack {
			action.calculateTotalMemoryUsage(bytes: &bytes)
		}
	}
	
	static var shared: UndoManager {
		get {
			if let manager = SharedUndoManager {
				return manager
			} else {
				SharedUndoManager = UndoManager()
				return SharedUndoManager!
			}
		}
	}
	
	func pop() -> UndoableAction? {
		return stack.popLast()
	}
	
	func addAction(_ action: UndoableAction) {
		stack.append(action)
	}
	
	private static var SharedUndoManager: UndoManager?
}



//
//  Types.swift
//  Blaise
//
//  Created by Ryan Joseph on 4/14/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Foundation

class Matrix<T> {
	var table: [T]
	var width, height: UInt
	var bounds: CGRect {
		get { return CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)) }
	}

	var elementStride: Int { return MemoryLayout<T>.stride }
	
	subscript (x: UInt, y: UInt) -> T {
		return getValue(x: x, y: y)
	}
	
	func indexOf(x: UInt, y: UInt) -> Int {
		return Int(x + (y * width))
	}
	
	
	func fill(_ with: T) {
		// NOTE: allocate new memory or iterate?
		table = Array(repeating: with, count: table.count)
//        for i in 0..<table.count {
//            table[i] = with
//        }
	}
	
	@inline(__always) func isValid(_ x: UInt, _ y: UInt) -> Bool {
		let index = indexOf(x: x, y: y)
		return (index < table.count && index >= 0)
	}
	
	@inline(__always) func getValue(x: UInt, y: UInt) -> T {
		let index = indexOf(x: x, y: y)
		return table[index]
	}
	
	func setValue(x: UInt, y: UInt, value: T) {
		let index = indexOf(x: x, y: y)
		table[index] = value
	}

	func setValue(_ x: UInt, _ y: UInt, _ value: T) {
		let index = indexOf(x: x, y: y)
		table[index] = value
	}

	init(width: UInt, height: UInt, defaultValue: T) {
		self.width = width
		self.height = height
		table = Array(repeating: defaultValue, count: Int(width * height))
	}
}

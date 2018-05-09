//
//  Types.swift
//  Blaise
//
//  Created by Ryan Joseph on 4/14/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Foundation

struct MatrixIterator<T>: IteratorProtocol {
	private let matrix: Matrix<T>
	private var index = 0
	
	init(matrix: Matrix<T>) {
		self.matrix = matrix
	}
	
	mutating func next() -> T? {
		let T = matrix.table[index]
		index += 1
		return T
	}
}

class Matrix<T> {
	
	var table: [T]
	var width, height: UInt
	var count: Int
	var bounds: CGRect {
		return CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))
	}

//	typealias Element = T
//	func makeIterator() -> MatrixIterator {
//		return MatrixIterator(matrix: self>)
//	}
	
	var elementStride: Int { return MemoryLayout<T>.stride }
	
	subscript <U: BinaryInteger>(x: U, y: U) -> T {
		get { return getValue(x, y) }
		set { setValue(x, y, newValue) }
	}
	
	subscript (cell: CellPos) -> T {
		return getValue(x: cell.x.uint, y: cell.y.uint)
	}

	func indexOf<U: BinaryInteger>(_ x: U, _ y: U) -> Int {
		return Int(x) + (Int(y) * width)
	}

	
	func fill(_ with: T) {
		// NOTE: allocate new memory or iterate?
//		table = Array(repeating: with, count: table.count)
		for i in 0..<table.count {
				table[i] = with
		}
	}
	
	@inline(__always) func isValid<U: BinaryInteger>(_ x: U, _ y: U) -> Bool {
		let index = indexOf(x, y)
		return (index < table.count && index >= 0)
	}
	
	@inline(__always) func getValueOrDefault<U: BinaryInteger>(_ x: U, _ y: U, default defaultValue: T) -> T {
		let index = indexOf(x, y)
		if (index < table.count && index >= 0) {
			return table[index]
		} else {
			return defaultValue
		}
	}

	@inline(__always) func getValueSafe<U: BinaryInteger>(_ x: U, _ y: U) -> T? {
		let index = indexOf(x, y)
		if (index < table.count && index >= 0) {
			return table[index]
		} else {
			return nil
		}
	}
	
	@inline(__always) func getValue<U: BinaryInteger>(_ x: U, _ y: U) -> T {
		let index = indexOf(x, y)
		return table[index]
	}

	@inline(__always) func getValue<U: BinaryInteger>(x: U, y: U) -> T {
		let index = indexOf(x, y)
		return table[index]
	}
	
	func setValue<U: BinaryInteger>(x: U, y: U, value: T) {
		let index = indexOf(x, y)
		table[index] = value
	}

	func setValue<U: BinaryInteger>(_ x: U, _ y: U, _ value: T) {
		let index = indexOf(x, y)
		table[index] = value
	}

	init(width: UInt, height: UInt, defaultValue: T) {
		self.width = width
		self.height = height
		count = Int(width * height)
		table = Array(repeating: defaultValue, count: count)
	}
	
	init(width: UInt, height: UInt) {
		self.width = width
		self.height = height
		count = Int(width * height)
		table = []
		table.reserveCapacity(count)
	}
	
}

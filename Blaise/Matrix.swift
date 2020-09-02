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

protocol MatrixTableProtocol {
	associatedtype Element
	var count: Int { get }
	subscript <U: BinaryInteger>(index: U) -> Element { get set }
	func getValue<U: BinaryInteger>(_ index: U) -> Element
	func setValue<U: BinaryInteger>(_ index: U, _ value: Element)
	init(width: UInt, height: UInt)
}

class FlatMatrixTable<T>: MatrixTableProtocol {
	private var table: [T]
	
	var count: Int { return table.count }

	public func getValue<U: BinaryInteger>(_ index: U) -> T {
		return table[Int(index)]
	}
	
	public func setValue<U: BinaryInteger>(_ index: U, _ value: T) {
		table[Int(index)] = value
	}
	
	subscript <U: BinaryInteger>(index: U) -> T {
		get { return getValue(index) }
		set { setValue(index, newValue) }
	}
	
	required init(width: UInt, height: UInt) {
		table = []
		table.reserveCapacity(Int(width * height))
	}
}

/*
	if we save to disk in a flat matrix then we can seek
	to cells and just update changed cells directly when the file is open
	which would make automatic saving really fast

	if we save as tightly packed jagged arrays if a column
	array changes then we have to resize the entire flat array
	which we export to
*/

// TODO: jagged matrix value (T) needs to conform to
// jagged matrix cell protocol so we can keep the column index
//

/*
class JaggedMatrixTable<T>: MatrixTableProtocol {
	private var rows: [[T]]
	
	public func resize(width: UInt, height: UInt) {
		rows = []
		rows.reserve(height)
		for r in 0..<height {
			rows.append([])
		}
		table.reserveCapacity(count)
	}
	
	public func getValue<U: BinaryInteger>(index: U) -> T {
		return table[index]
	}
	
	public func setValue<U: BinaryInteger>(index: U, value: T) {
		table[index] = value
	}
	
	subscript <U: BinaryInteger>(index: U) -> T {
		get { return getValue(index) }
		set { setValue(index, newValue) }
	}
}
*/

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
		get { return getValue(x: cell.x.uint, y: cell.y.uint) }
		set { setValue(cell.x.uint, cell.y.uint, newValue) }
	}

	func indexOf<U: BinaryInteger>(_ x: U, _ y: U) -> Int {
		return Int(x) + (Int(y) * width)
	}

	func resize (x: Int, y: Int, withValue: () -> T) {
		var temp: [T] = []
		let newSize = count + height * x + width * y
		temp.reserveCapacity(newSize)
		
		var destIndex: Int = 0
		var column: Int = 0
		for srcIndex in 0..<count {
//			temp[destIndex] = table[srcIndex]
			var newValue: T
			if table.count < srcIndex {
				newValue = withValue()
			} else {
				newValue = table[srcIndex]
			}
			temp.insert(newValue, at: destIndex)
			column += 1
			if column == width {
				destIndex += x
				
				// TODO: insert x elements. how do we copy default value??
//				temp.insert(table[srcIndex], at: destIndex)
				for _ in 0..<x {
					let newValue = withValue()
					temp.insert(newValue, at: destIndex)
				}
				
				column = 0
			}
			
			destIndex += 1
		}
		
		table = temp
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

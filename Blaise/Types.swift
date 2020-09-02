//
//  Types.swift
//  Blaise
//
//  Created by Ryan Joseph on 4/14/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Foundation
import AppKit

// TODO: deprecated for "spans" vec2 extension
struct CellDim {
	var width, height: UInt
	
	func sum() -> UInt {
		return width + height
	}
	
	func volume() -> UInt {
		return width * height
	}

	var w: UInt {
		get { return width; }
	}
	var h: UInt {
		get { return height; }
	}
	
	init(_ w: UInt, _ h: UInt) {
		width = w
		height = h
	}
}

struct Vec2<T: Numeric>: CustomStringConvertible {
	var x, y: T
	
	init(_ x: T, _ y: T) {
		self.x = x
		self.y = y
	}
	
	var description: String { return "{\(x),\(y)}" }
	
	// operators
	static func ==(left: Vec2, right: Vec2) -> Bool {
		return (left.x == right.x) && (left.y == right.y)
	}
	
	static func !=(left: Vec2, right: Vec2) -> Bool {
		return (left.x != right.x) || (left.y != right.y)
	}
	
	static func + (left: Vec2, right: Vec2) -> Vec2 {
		return Vec2(left.x + right.x, left.y + right.y)
	}
	
	static func - (left: Vec2, right: Vec2) -> Vec2 {
		return Vec2(left.x - right.x, left.y - right.y)
	}
	
	static func * (left: Vec2, right: Vec2) -> Vec2 {
		return Vec2(left.x * right.x, left.y * right.y)
	}
	
	static func + (left: Vec2, right: T) -> Vec2 {
		return Vec2(left.x + right, left.y + right)
	}

	static func - (left: Vec2, right: T) -> Vec2 {
		return Vec2(left.x - right, left.y - right)
	}
	
	static func * (left: Vec2, right: T) -> Vec2 {
		return Vec2(left.x * right, left.y * right)
	}

	static func -= (left: inout Vec2, right: T) {
		left = left - right
	}
	static func += (left: inout Vec2, right: T) {
		left = left + right
	}
	static func *= (left: inout Vec2, right: T) {
		left = left * right
	}

	static func -= (left: inout Vec2, right: Vec2) {
		left = left - right
	}
	static func += (left: inout Vec2, right: Vec2) {
		left = left + right
	}
	static func *= (left: inout Vec2, right: Vec2) {
		left = left * right
	}
	
}

extension Vec2 where T: Comparable {
	
	func clamp(_ minX: T, _ minY: T, _ maxX: T, _ maxY: T) -> Vec2 {
		var newVec = self
		
		if newVec.x < minX { newVec.x = minX }
		if newVec.y < minY { newVec.y = minY }
		if newVec.x > maxX { newVec.x = maxX }
		if newVec.y > maxY { newVec.y = maxY }
		
		return newVec
	}

	func clamp(_ min: Vec2, _ max: Vec2) -> Vec2 {
		return clamp(min.x, min.y, max.x, max.y)
	}

}

extension Vec2 where T: SignedInteger {
	static func / (left: Vec2, right: T) -> Vec2 {
		return Vec2(left.x / right, left.y / right)
	}
	static func / (left: Vec2, right: Vec2) -> Vec2 {
		return Vec2(left.x / right.x, left.y / right.y)
	}
	static func /= (left: inout Vec2, right: T) {
		left = left / right
	}
	static func /= (left: inout Vec2, right: Vec2) {
		left = left / right
	}
}

extension Vec2 where T: FloatingPoint {
	static func / (left: Vec2, right: T) -> Vec2 {
		return Vec2(left.x / right, left.y / right)
	}
	static func / (left: Vec2, right: Vec2) -> Vec2 {
		return Vec2(left.x / right.x, left.y / right.y)
	}
	static func /= (left: inout Vec2, right: T) {
		left = left / right
	}
	static func /= (left: inout Vec2, right: Vec2) {
		left = left / right
	}
}

// linear algebra utils
extension Vec2 {
	
	func lerp (t: T, p: Vec2) -> Vec2 {
		return (self * (1 - t)) + (p * t)
	}
	
}

extension Vec2 where T == IntegerLiteralType {
	
	func magnitude () -> T {
		return T(sqrt(Double((x * x) + (y * y))))
	}
	
	func distance (_ to: Vec2) -> T {
		let diff = self - to
		return diff.magnitude()
	}

}

extension Vec2 where T == Float {
	
	func magnitude () -> T {
		return T(sqrt(Double((x * x) + (y * y))))
	}
	
	func distance (_ to: Vec2) -> T {
		let diff = self - to
		return diff.magnitude()
	}
	
	func trunc() -> Vec2<Int> {
		return Vec2<Int>(Int(x), Int(y))
	}
	
	init <UX: FloatingPointArithmetic, UY: FloatingPointArithmetic>(_ x: UX, _ y: UY) {
		self.x = x.toFloat
		self.y = y.toFloat
	}

}

typealias V2 = Vec2<Float>
typealias V2i = Vec2<Int>
typealias CellPos = V2i

// Spans
typealias Span = Vec2<UInt>

extension Vec2 where T == UInt {

	var w: UInt {
		get { return x }
	}
	var h: UInt {
		get { return y }
	}
	
	var width: UInt {
		get { return x }
		set { x = newValue }
	}
	
	var height: UInt {
		get { return x }
		set { x = newValue }
	}

}



// CoreGraphics Utils
func CGPointToCellPos (_ point: CGPoint) -> CellPos {
	return CellPos(Int(point.x), Int(point.y))
}

struct Box: CustomStringConvertible {
	var min, max: CellPos
	typealias PointType = Int
	
	var top: PointType { return min.x }
	var left: PointType { return min.y }
	var right: PointType { return max.x }
	var bottom: PointType { return max.y }
	
	var x: PointType { return min.x }
	var y: PointType { return min.y }
	var minX: PointType { return min.x }
	var minY: PointType { return min.y }
	var maxX: PointType { return max.x }
	var maxY: PointType { return max.y }
	var width: PointType { return max.x - min.x }
	var height: PointType { return max.y - min.y }

	var description: String { return "{\(min),\(max)}" }
	
	// init
	init(top: PointType, left: PointType, right: PointType, bottom: PointType) {
		min = CellPos(top, left)
		max = CellPos(right, bottom)
	}
	
	init(minX: PointType, minY: PointType, maxX: PointType, maxY: PointType) {
		min = CellPos(minX, minY)
		max = CellPos(maxX, maxY)
	}

	init<T: IntegerArithmetic>(_ minX: T, _ minY: T, _ maxX: T, _ maxY: T) {
		min = CellPos(PointType(minX.toSigned), PointType(minY.toSigned))
		max = CellPos(PointType(maxX.toSigned), PointType(maxY.toSigned))
	}

	init(min: CellPos, max: CellPos) {
		self.min = min
		self.max = max
	}
	
	static func infinite() -> Box {
		return Box(min: CellPos(PointType.max, PointType.max), max: CellPos(-PointType.max, -PointType.max))
	}
	
	// methods
	func isInfinite() -> Bool {
		return (min.x > max.x || min.y > max.y)
	}
	func xRange() -> ClosedRange<UInt> {
		return min.x.uint...max.x.uint
	}
	func yRange() -> ClosedRange<UInt> {
		return min.y.uint...max.y.uint
	}

	func inset(x: Int, y: Int) -> Box {
		var newBox = self
		newBox.min.x += x
		newBox.min.y += y
		newBox.max.x -= x
		newBox.max.y -= y
		return newBox
	}
	
	func clamp(_ bounds: Box) -> Box {
		var newBox = self
		if newBox.min.x < bounds.min.x { newBox.min.x = bounds.min.x }
		if newBox.min.y < bounds.min.y { newBox.min.y = bounds.min.y }
		if newBox.max.x > bounds.max.x { newBox.max.x = bounds.max.x }
		if newBox.max.y > bounds.max.y { newBox.max.y = bounds.max.y }
		return newBox
	}
	
	mutating func union(_ box: Box) {
		if box.min.x < min.x { min.x = box.min.x }
		if box.min.y < min.y { min.y = box.min.y }
		if box.max.x > max.x { max.x = box.max.x }
		if box.max.y > max.y { max.y = box.max.y }
	}
	
	mutating func union(_ point: CellPos) {
		union(point.x, point.y)
	}
	
	mutating func union(_ x: Int, _ y: Int) {
		if x < min.x { min.x = x }
		if y < min.y { min.y = y }
		if x > max.x { max.x = x }
		if y > max.y { max.y = y }
	}

	subscript (i: UInt) -> PointType {
		switch i {
		case 0:
			return min.x
		case 1:
			return min.y
		case 2:
			return max.x
		case 3:
			return max.y
		default:
			return min.x
		}
	}
	
	// operators
	static func / (left: Box, right: PointType) -> Box {
		return Box(min: left.min / right, max: left.max / right)
	}
	
	static func / (left: Box, right: CellDim) -> Box {
		return Box(top: left.top / Int(right.width), left: left.left / Int(right.height), right: left.right / Int(right.width), bottom: left.bottom / Int(right.height))
	}

}

func UnionPoints(_ points: [CellPos]) -> Box {
	var box = Box.infinite()
	points.forEach { (point) in        
		if point.x < box.min.x {
			box.min.x = point.x
		}
		if point.x > box.max.x {
			box.max.x = point.x
		}
		
		if point.y < box.min.y {
			box.min.y = point.y
		}
		if point.y > box.max.y {
			box.max.y = point.y
		}
		
	}
	return box
}

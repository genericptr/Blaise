//
//  Types.swift
//  Blaise
//
//  Created by Ryan Joseph on 4/14/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Foundation
import AppKit

struct RGBA<T> {
	typealias PixelType = T
	var r, g, b, a: PixelType
	
	static func == <T: Equatable> (left: RGBA<T>, right: RGBA<T>) -> Bool {
		return (left.r == right.g) && (left.g == right.g) && (left.b == right.b) && (left.a == right.a)
	}

	// TODO: why doesn't this
//    func compare <T: Equatable> (r: T, g: T, b: T, a: T) -> Bool {
//        return (self.r == r && self.g == g && self.b == b && self.a == a)
//    }

	init(r: T, g: T, b: T, a: T) {
		self.r = r
		self.g = g
		self.b = b
		self.a = a
	}

	init(_ r: T, _ g: T, _ b: T, _ a: T) {
		self.r = r
		self.g = g
		self.b = b
		self.a = a
	}
}
typealias RGBA8 = RGBA<UInt8>
typealias RGBAf = RGBA<Float>

extension RGBA where T == UInt8  {
	func isWhite() -> Bool {
		return (r == 255 && g == 255 && b == 255 && a == 255)
	}
	
//    static func == (left: RGBA8, right: RGBA8) -> Bool {
//        return (left.r == right.g) && (left.g == right.g) && (left.b == right.b) && (left.a == right.a)
//    }
	
	func getRGBAf() -> RGBAf {
		return RGBAf(r: Float(r) / 255.0, g: Float(g) / 255.0, b: Float(b) / 255.0, a: Float(a) / 255.0)
	}

	func getColor() -> NSColor {
		return NSColor(calibratedRed: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: CGFloat(a) / 255.0)
	}
	
	static func whiteColor() -> RGBA8 {
		return RGBA8(r: 255, g: 255, b: 255, a: 255)
	}
	static func blackColor() -> RGBA8 {
		return RGBA8(r: 0, g: 0, b: 0, a: 255)
	}
}

typealias PixelMatrix = Matrix<RGBA8>

struct CellDim {
	var width, height: UInt
	
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

struct Vec2<T: Numeric> {
	var x, y: T
	
	init(_ x: T, _ y: T) {
		self.x = x
		self.y = y
	}
	
	// operators
	static func ==(left: Vec2, right: Vec2) -> Bool {
		return (left.x == right.y) && (left.y == right.y)
	}
	
	static func !=(left: Vec2, right: Vec2) -> Bool {
		return (left.x != right.y) || (left.y != right.y)
	}
	
	static func * (left: Vec2, right: T) -> Vec2 {
		return Vec2(left.x * right, left.y * right)
	}

	
}

extension Vec2 where T: Comparable {
	func clamp(_ min: T, _ max: T) -> Vec2 {
		var newVec = self
		
		if newVec.x < min { newVec.x = max }
		if newVec.x > max { newVec.x = max }
		if newVec.y < min { newVec.y = max }
		if newVec.y > max { newVec.y = max }
		
		return newVec
	}

	func clamp(_ min: Vec2, _ max: Vec2) -> Vec2 {
		var newVec = self
		
		if newVec.x < min.x { newVec.x = min.x }
		if newVec.y < min.y { newVec.y = min.y }
		if newVec.x > max.x { newVec.x = max.x }
		if newVec.y > max.y { newVec.y = max.y }
		
		return newVec
	}

}

extension Vec2 where T: SignedInteger {
	static func / (left: Vec2, right: T) -> Vec2 {
		return Vec2(left.x / right, left.y / right)
	}
}

extension Vec2 where T: FloatingPoint {
	static func / (left: Vec2, right: T) -> Vec2 {
		return Vec2(left.x / right, left.y / right)
	}
}

typealias V2 = Vec2<Float>
typealias CellPos = Vec2<Int>

// CoreGraphics Utils
func CGPointToCellPos (_ point: CGPoint) -> CellPos {
	return CellPos(Int(point.x), Int(point.y))
}

struct Box {
	var min, max: CellPos
	typealias PointType = Int
	
	var top: PointType { return min.x }
	var left: PointType { return min.y }
	var right: PointType { return max.x }
	var bottom: PointType { return max.y }
	
	
	// init
	init(top: PointType, left: PointType, right: PointType, bottom: PointType) {
		min = CellPos(top, left)
		max = CellPos(right, bottom)
	}
	
	init(_ minX: PointType, _ minY: PointType, _ maxX: PointType, _ maxY: PointType) {
		min = CellPos(minX, minY)
		max = CellPos(maxX, maxY)
	}

	init(min: CellPos, max: CellPos) {
		self.min = min
		self.max = max
	}
	
	static func infinite() -> Box {
		return Box(min: CellPos(PointType.max, PointType.max), max: CellPos(-PointType.max, -PointType.max))
	}
	
	// methods
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

//
//  Colors.swift
//  Blaise
//
//  Created by Ryan Joseph on 4/24/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Foundation
import AppKit

struct RGBA<T: Numeric> {
	typealias PixelType = T
	var r, g, b, a: PixelType
	
	static func == (left: RGBA, right: RGBA) -> Bool {
		return (left.r == right.r) && (left.g == right.g) && (left.b == right.b) && (left.a == right.a)
	}
	
	static func != (left: RGBA, right: RGBA) -> Bool {
		return (left.r != right.r) || (left.g != right.g) || (left.b != right.b) || (left.a != right.a)
	}

	
	// values
	static func * (left: RGBA, right: RGBA) -> RGBA {
		return RGBA(left.r * right.r, left.g * right.g, left.b * right.b, left.a * right.a)
	}

	static func + (left: RGBA, right: RGBA) -> RGBA {
		return RGBA(left.r + right.r, left.g + right.g, left.b + right.b, left.a + right.a)
	}
	
	static func - (left: RGBA, right: RGBA) -> RGBA {
		return RGBA(left.r - right.r, left.g - right.g, left.b - right.b, left.a - right.a)
	}
	
	// scalars
	static func * (left: RGBA, right: T) -> RGBA {
		return RGBA(left.r * right, left.g * right, left.b * right, left.a * right)
	}
	
	static func + (left: RGBA, right: T) -> RGBA {
		return RGBA(left.r + right, left.g + right, left.b + right, left.a + right)
	}
	
	static func - (left: RGBA, right: T) -> RGBA {
		return RGBA(left.r - right, left.g - right, left.b - right, left.a - right)
	}
	
	init(white: T, alpha: T) {
		self.r = white
		self.g = white
		self.b = white
		self.a = alpha
	}
	
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

func Clamp(value: RGBAf, min: Float, max: Float) -> RGBAf {
	var newValue = value
	newValue.r = Clamp(value: newValue.r, min: min, max: max)
	newValue.g = Clamp(value: newValue.g, min: min, max: max)
	newValue.b = Clamp(value: newValue.b, min: min, max: max)
	newValue.a = Clamp(value: newValue.a, min: min, max: max)
	return newValue
}

extension RGBA where T == UInt8  {
	func isWhite() -> Bool {
		return (r == 255 && g == 255 && b == 255 && a == 255)
	}
	
	func getRGBAf() -> RGBAf {
		return RGBAf(r: Float(r) / 255.0, g: Float(g) / 255.0, b: Float(b) / 255.0, a: Float(a) / 255.0)
	}
	
	func getColor() -> NSColor {
		return NSColor(calibratedRed: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: CGFloat(a) / 255.0)
	}
		
	// common colors
	
	static let whiteColor: RGBA8 = RGBA8(r: 255, g: 255, b: 255, a: 255)
	static let blackColor: RGBA8 = RGBA8(r: 0, g: 0, b: 0, a: 255)
	static let clearColor: RGBA8 = RGBA8(r: 0, g: 0, b: 0, a: 0)
	static let redColor: RGBA8 = RGBA8(r: 255, g: 0, b: 0, a: 255)
	static let greenColor: RGBA8 = RGBA8(r: 0, g: 255, b: 0, a: 255)
	static let blueColor: RGBA8 = RGBA8(r: 0, g: 0, b: 255, a: 255)
}

extension RGBA where T == Float  {
	
	func getRGBA8() -> RGBA8 {
		return RGBA8(UInt8(r * 255), UInt8(g * 255), UInt8(b * 255), UInt8(a * 255))
	}
	
}

typealias PixelMatrix = Matrix<RGBA8>

extension NSColor {
	func RGBA8Color() -> RGBA8 {
		return RGBA8(UInt8(redComponent * 255), UInt8(greenComponent * 255), UInt8(blueComponent * 255), UInt8(alphaComponent * 255))
	}
}

//
//  Colors.swift
//  Blaise
//
//  Created by Ryan Joseph on 4/24/18.
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
	
	
	// common colors
	static func whiteColor() -> RGBA8 {
		return RGBA8(r: 255, g: 255, b: 255, a: 255)
	}
	static func blackColor() -> RGBA8 {
		return RGBA8(r: 0, g: 0, b: 0, a: 255)
	}
	static func clearColor() -> RGBA8 {
		return RGBA8(r: 0, g: 0, b: 0, a: 0)
	}
	
}

typealias PixelMatrix = Matrix<RGBA8>

extension NSColor {
	func RGBA8Color() -> RGBA8 {
		return RGBA8(UInt8(redComponent * 255), UInt8(greenComponent * 255), UInt8(blueComponent * 255), UInt8(alphaComponent * 255))
	}
}

//
//  CGUtils.swift
//  Blaise
//
//  Created by Ryan Joseph on 4/17/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Foundation

extension CGFloat {
	var int: Int {
		return Int(self)
	}
	var uint: UInt {
		return UInt(self)
	}
}

extension CGPoint {
	
	// points
	static func - (left: CGPoint, right: CGPoint) -> CGPoint {
		return CGPoint(x: left.x - right.x, y: left.y - right.y)
	}
	static func + (left: CGPoint, right: CGPoint) -> CGPoint {
		return CGPoint(x: left.x + right.x, y: left.y + right.y)
	}
	static func * (left: CGPoint, right: CGPoint) -> CGPoint {
		return CGPoint(x: left.x * right.x, y: left.y * right.y)
	}
	static func / (left: CGPoint, right: CGPoint) -> CGPoint {
		return CGPoint(x: left.x / right.x, y: left.y / right.y)
	}
	
	// assignments
	static func -= (left: inout CGPoint, right: CGPoint) {
		left = left - right
	}
	static func += (left: inout CGPoint, right: CGPoint) {
		left = left + right
	}
	static func *= (left: inout CGPoint, right: CGPoint) {
		left = left * right
	}
	static func /= (left: inout CGPoint, right: CGPoint) {
		left = left / right
	}

	// scalars
	static func * (left: CGPoint, right: CGFloat) -> CGPoint {
		return CGPoint(x: left.x * right, y: left.y * right)
	}
	
	static func / (left: CGPoint, right: CGFloat) -> CGPoint {
		return CGPoint(x: left.x / right, y: left.y / right)
	}

}


// convert implicit arrays to CGTypes
// example: [100, 100].cgSize()
extension Array where Element == Int {
	var cgSize: CGSize {
		return CGSize(width: CGFloat(self[0]), height: CGFloat(self[1]))
	}
	var cgPoint: CGPoint {
		return CGPoint(x: CGFloat(self[0]), y: CGFloat(self[1]))
	}
}

func Normalize(_ point: CGPoint) -> CGPoint {
	let length = CGFloat(Magnitude(point))
	return CGPoint(x: point.x / length, y: point.y / length)
}

func Clamp(point: CGPoint, rect: CGRect) -> CGPoint {
	var newPoint = point
	if newPoint.x < rect.minX {
		newPoint.x = rect.minX
	}
	if newPoint.y < rect.minY {
		newPoint.y = rect.minY
	}
	if newPoint.x > rect.maxX {
		newPoint.x = rect.maxX
	}
	if newPoint.y > rect.maxY {
		newPoint.y = rect.maxY
	}
	return newPoint
}

func FlipY (point: CGPoint, bounds: CGRect) -> CGPoint {
	var newPoint = point
	newPoint.y = bounds.size.height - newPoint.y
	return newPoint
}

@discardableResult func CGImageWriteToDisk(_ image: CGImage, to destinationURL: URL) -> Bool {
	guard let destination = CGImageDestinationCreateWithURL(destinationURL as CFURL, kUTTypePNG, 1, nil) else { return false }
	CGImageDestinationAddImage(destination, image, nil)
	return CGImageDestinationFinalize(destination)
}

class BitmapContext {
	var context: CGContext!
	var pixels: PixelMatrix
	var bounds: CGRect {
		return CGRect(x: 0, y: 0, width: pixels.width.int, height: pixels.height.int)
	}
	
	func makeImage() -> CGImage? {
		return context.makeImage()
	}

	init(width: UInt, height: UInt) {
		let defaultColor = RGBA8.whiteColor()
		pixels = PixelMatrix(width: width, height: height, defaultValue: defaultColor)
		let bytesPerComponent = MemoryLayout<RGBA8.PixelType>.size
		
		pixels.table.withUnsafeMutableBytes { pointer in
			context = CGContext(
				data: pointer.baseAddress,
				width: Int(width),
				height: Int(height),
				bitsPerComponent: bytesPerComponent * 8,
				bytesPerRow: (bytesPerComponent * 4) * Int(width),
				space: CGColorSpaceCreateDeviceRGB(),
				bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
				)!
		}
	}
}
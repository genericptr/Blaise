//
//  CGUtils.swift
//  Blaise
//
//  Created by Ryan Joseph on 4/17/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Foundation

// MARK: CGFloat Extensions

extension CGFloat {
	var int: Int {
		return Int(self)
	}
	var uint: UInt {
		return UInt(self)
	}
}

// MARK: CGPoint Extensions

extension CGPoint {
	
	// self
	static func + (left: CGPoint, right: CGPoint) -> CGPoint {
		return CGPoint(x: left.x + right.x, y: left.y + right.y)
	}
	static func - (left: CGPoint, right: CGPoint) -> CGPoint {
		return CGPoint(x: left.x - right.x, y: left.y - right.y)
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
	static func + (left: CGPoint, right: CGFloat) -> CGPoint {
		return CGPoint(x: left.x + right, y: left.y + right)
	}

	static func - (left: CGPoint, right: CGFloat) -> CGPoint {
		return CGPoint(x: left.x - right, y: left.y - right)
	}

	static func * (left: CGPoint, right: CGFloat) -> CGPoint {
		return CGPoint(x: left.x * right, y: left.y * right)
	}
	
	static func / (left: CGPoint, right: CGFloat) -> CGPoint {
		return CGPoint(x: left.x / right, y: left.y / right)
	}
	
	init(_ x: CGFloat, _ y: CGFloat) {
		self.x = x
		self.y = y
	}

}

// MARK: CGSize

extension CGSize {
	
		// self
		static func + (left: CGSize, right: CGSize) -> CGSize {
			return CGSize(width: left.width + right.width, height: left.height + right.height)
		}
		static func - (left: CGSize, right: CGSize) -> CGSize {
			return CGSize(width: left.width - right.width, height: left.height - right.height)
		}
		static func * (left: CGSize, right: CGSize) -> CGSize {
			return CGSize(width: left.width * right.width, height: left.height * right.height)
		}
		static func / (left: CGSize, right: CGSize) -> CGSize {
			return CGSize(width: left.width / right.width, height: left.height / right.height)
		}
	
		// assignments
		static func -= (left: inout CGSize, right: CGSize) {
			left = left - right
		}
		static func += (left: inout CGSize, right: CGSize) {
			left = left + right
		}
		static func *= (left: inout CGSize, right: CGSize) {
			left = left * right
		}
		static func /= (left: inout CGSize, right: CGSize) {
			left = left / right
		}
	
    // scalars
		static func + (left: CGSize, right: CGFloat) -> CGSize {
			return CGSize(width: left.width + right, height: left.height + right)
		}

		static func - (left: CGSize, right: CGFloat) -> CGSize {
			return CGSize(width: left.width - right, height: left.height - right)
		}

    static func * (left: CGSize, right: CGFloat) -> CGSize {
        return CGSize(width: left.width * right, height: left.height * right)
    }

    static func / (left: CGSize, right: CGFloat) -> CGSize {
        return CGSize(width: left.width / right, height: left.height / right)
    }
	
	init(_ width: CGFloat, _ height: CGFloat) {
		self.width = width
		self.height = height
	}

}

// MARK: CGRect Extensions

extension CGRect {
	
	var max: CGPoint {
		return origin + CGPoint(width, height)
	}
	
	init(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) {
		self.origin = CGPoint(x: x, y: y)
		self.size = CGSize(width: width, height: height)
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

// MARK: functions

func Normalize(_ point: CGPoint) -> CGPoint {
	let length = CGFloat(Magnitude(point))
	return CGPoint(x: point.x / length, y: point.y / length)
}

func Clamp(value: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
	return value < min ? min: value > max ? max: value
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

func Trunc (_ point: CGPoint) -> CGPoint {
	var newPoint = point
	newPoint.x = trunc(newPoint.x)
	newPoint.y = trunc(newPoint.y)
	return newPoint
}

@discardableResult func CGImageWriteToDisk(_ image: CGImage, to destinationURL: URL) -> Bool {
	guard let destination = CGImageDestinationCreateWithURL(destinationURL as CFURL, kUTTypePNG, 1, nil) else { return false }
	CGImageDestinationAddImage(destination, image, nil)
	return CGImageDestinationFinalize(destination)
}

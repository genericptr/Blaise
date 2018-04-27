//
//  BitmapContext.swift
//  Blaise
//
//  Created by Ryan Joseph on 4/26/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Foundation

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

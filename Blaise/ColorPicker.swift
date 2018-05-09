//
//  ColorPicker.swift
//  Blaise
//
//  Created by Ryan Joseph on 4/20/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Foundation
import AppKit
import CoreGraphics

protocol ColorPickerViewDelegate {
	func colorPickerChanged(_ color: RGBA8)
}

class ColorPicker {
	var bitmapContext: CGContext!
	var pixels: PixelMatrix
	
	func colorAtPoint(_ pos: CGPoint) -> RGBA8 {
		return pixels[pos.x.uint, pos.y.uint]
	}

	func reload() {
		// https://stackoverflow.com/questions/5061869/how-would-i-go-about-generating-a-color-pickers-color-rainbow-swatch
		// https://stackoverflow.com/questions/27208386/simple-swift-color-picker-popover-ios#34142316
		
		let center = CGPoint(x: CGFloat(pixels.width / 2), y: CGFloat(pixels.height / 2))
		let maxDist = Float(pixels.width / 2)//Distance(center, CGPoint(x: 0.0, y: 0.0))

		for y in 0..<pixels.height {
			for x in 0..<pixels.width {
				let point = CGPoint(x: CGFloat(x), y: CGFloat(y))
				let r = CGPoint(x: center.x - point.x, y: center.y - point.y)
				let theta = atan2(Double(r.y), Double(r.x))
				let hue = (theta + Double.pi) / (2 * Double.pi);
				let saturation = Float(Distance(center, point) * 1.0) / maxDist
				let brightness = 1.0
				let color = NSColor(calibratedHue: CGFloat(hue), saturation: CGFloat(saturation), brightness: CGFloat(brightness), alpha: 1.0)
				
				let pixel = color.RGBA8Color()
				pixels.setValue(x, y, pixel)
//				print(color)
			}
		}
		bitmapContext.synchronize()
	}
	
	init(size: UInt) {
		
		
		// !wrap this
		let width = size
		let height = size
		let color = NSColor(calibratedHue: 1.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
		
		pixels = PixelMatrix(width: width, height: height, defaultValue: color.RGBA8Color())
		let bytesPerComponent = MemoryLayout<RGBA8.PixelType>.size
		
		pixels.table.withUnsafeMutableBytes { pointer in
			bitmapContext = CGContext(
				data: pointer.baseAddress,
				width: Int(width),
				height: Int(height),
				bitsPerComponent: 8,
				bytesPerRow: (bytesPerComponent * 4) * Int(width),
				space: CGColorSpaceCreateDeviceRGB(),
				bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
				)!
			
			bitmapContext.interpolationQuality = .none
			bitmapContext.setShouldAntialias(false)
		}

	}
}

class ColorPickerView: NSView {
	var picker: ColorPicker!
	weak var delegate: AnyObject?
	var cursorLocation: CGPoint = CGPoint()
	var backgroundRect: CGRect = CGRect()

	let borderInset: CGFloat = 0
	
	func moveTo(_ pos: CGPoint) {

		// TODO: this is a mess. why are we overflowing?
//		var rect = backgroundRect
//		rect.size.width -= 1
//		rect.size.height -= 1
//		rect.origin.y += 1

		var newPos = Clamp(point: pos, rect: backgroundRect)
		let center = CGPoint(x: backgroundRect.width / 2, y: backgroundRect.height / 2)
		let distance = Float(Distance(newPos, center))
		let radius = Float(backgroundRect.width) / 2

		if distance > radius {
			// get location as unit vector from center
			// and scale by max radius
			newPos = Normalize(newPos - center)
			newPos = newPos * CGFloat(radius)
			newPos = center + newPos
			print("out of bounds")
		}
//		print(newPos)

		let ratio = CGPoint(x: backgroundRect.width / CGFloat(picker.pixels.width - 1), y: backgroundRect.height / CGFloat(picker.pixels.height - 1))
		var pickerPoint = newPos / ratio
//		pickerPoint = pickerPoint - backgroundRect.origin
		pickerPoint -= backgroundRect.origin
		pickerPoint = Clamp(point: pickerPoint, rect: CGRect(x: 0, y: 0, width: CGFloat(picker.pixels.width - 1), height: CGFloat(picker.pixels.height - 1)))

		pickerPoint = FlipY(point: pickerPoint, bounds: bounds)
		print(pickerPoint)
		let color = picker.colorAtPoint(pickerPoint)
		
		if let delegate: ColorPickerViewDelegate = delegate as? ColorPickerViewDelegate {
				delegate.colorPickerChanged(color)
		}
		cursorLocation = newPos
		setNeedsDisplay(bounds)
	}

	override var isFlipped: Bool {
		return true
	}
	
	override func mouseDown(with event: NSEvent) {
	}
	
	override func mouseDragged(with event: NSEvent) {
		let mouseLocation = convert(event.locationInWindow, from: nil)
		moveTo(mouseLocation)
	}
	
	override func draw(_ dirtyRect: NSRect) {
		if let image = picker.bitmapContext.makeImage() {
			guard let context = NSGraphicsContext.current?.cgContext else { return }
			
			// context settings
			context.setShouldAntialias(true)
			context.interpolationQuality = .none

			// draw color background
			let clipRect = backgroundRect
			context.addEllipse(in: clipRect)
			context.clip()
			context.draw(image, in: backgroundRect)
			context.resetClip()
			
			context.interpolationQuality = .default
			
			// draw selection color ring
			if borderInset > 0 {
				context.setStrokeColor(gray: 0, alpha: 1)
				context.setLineWidth(borderInset)
				context.addEllipse(in: backgroundRect.insetBy(dx: -borderInset/2, dy: -borderInset/2))
				context.strokePath()
			}
			
			// draw cursor
			context.setShouldAntialias(false)
			context.setStrokeColor(gray: 0, alpha: 1)
			context.setLineWidth(0.5)

			let radius: CGFloat = 8
			let cursorRect = CGRect(x: cursorLocation.x - radius, y: cursorLocation.y - radius, width: radius * 2, height: radius * 2)
//			context?.strokeEllipse(in: cursorLocationRect)
			
			var pointA = CGPoint(x: cursorRect.midX, y: cursorRect.minY)
			var pointB = CGPoint(x: cursorRect.midX, y: cursorRect.maxY)
			context.strokeLineSegments(between: [pointA, pointB])
			
			pointA = CGPoint(x: cursorRect.minX, y: cursorRect.midY)
			pointB = CGPoint(x: cursorRect.maxX, y: cursorRect.midY)
			context.strokeLineSegments(between: [pointA, pointB])
		}
	}
	
	func setup(_ pickerSize: UInt) {
		backgroundRect = bounds.insetBy(dx: borderInset, dy: borderInset)
		
		picker = ColorPicker(size: pickerSize)
		picker.reload()
		
		let defaultPos = CGPoint(x: CGFloat(frame.width / 2), y: CGFloat(frame.height / 2))
		moveTo(defaultPos)
	}
	
	init(frame frameRect: NSRect, pickerSize: UInt) {
		super.init(frame: frameRect)
		
		setup(pickerSize)
	}
	
	required init?(coder decoder: NSCoder) {
		super.init(coder: decoder)
		
		setup(bounds.width.uint)
	}
}

//
//  ColorGrid.swift
//  Blaise
//
//  Created by Ryan Joseph on 4/24/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Foundation
import AppKit


protocol ColorGridViewDelegate {
	func colorGridChanged(_ color: RGBA8)
}

class ColorGridView: NSView {
	let cellMargin: CGFloat = 1.0
	let cellMagnificationFactor: CGFloat = 0.15
	let invalidCell = CellPos(-1, -1)

	var gridSize: Span
	var cellSize: CGSize
	var colorMatrix: PixelMatrix
	var trackingArea: NSTrackingArea?
	var selectedCell: CellPos
	var hoverCell: CellPos
	weak var delegate: Any<ColorGridViewDelegate>
	
	func viewPointToGridPoint (_ viewPoint: CGPoint) -> CellPos {
		var point = viewPoint
		
		// offset for margins
		point.x -= floor(point.x / cellSize.width) * cellMargin
		point.y -= floor(point.y / cellSize.height) * cellMargin
		
		point.x /= cellSize.width
		point.y /= cellSize.height
		
		var cell = CellPos(point.x.int, point.y.int)
		cell = cell.clamp(CellPos(0, 0), CellPos(gridSize.w.int - 1, gridSize.h.int - 1))
		
		return cell
	}
	
	func gridPointToViewPoint(_ gridPoint: CellPos) -> CGPoint {
		var point = CGPoint(CGFloat(gridPoint.x), CGFloat(gridPoint.y))
		
		// offset for margins
		point.x += point.x * cellMargin
		point.y += point.y * cellMargin
		
		point.x *= cellSize.width
		point.y *= cellSize.height
		
		return point
	}
	
	func gridPointToViewRect(_ gridPoint: CellPos) -> CGRect {
		let viewPoint = gridPointToViewPoint(gridPoint)
		return CGRect(origin: viewPoint, size: cellSize)
	}
	
	override var acceptsFirstResponder: Bool {
		return true
	}
	
	override func updateTrackingAreas() {
		if let trackingArea = trackingArea {
			removeTrackingArea(trackingArea)
		}
		
		super.updateTrackingAreas()
		
		trackingArea = NSTrackingArea(rect: bounds, options: [.mouseMoved, .activeInKeyWindow], owner: self, userInfo: nil)
		addTrackingArea(trackingArea!)
	}
	
	override func mouseDown(with event: NSEvent) {
		let p = convert(event.locationInWindow, from: nil)
		
		selectedCell = viewPointToGridPoint(p)
		
		
	}
	
	override func mouseMoved(with event: NSEvent) {
		let p = convert(event.locationInWindow, from: nil)
		
		hoverCell = viewPointToGridPoint(p)
		
//		var gridRect = gridPointToViewRect(selectedCell)
//		print(gridRect)
//		gridRect = gridRect.insetBy(dx: -16, dy: -16)
		setNeedsDisplay(bounds)
	}
	
	override func resetCursorRects() {
		let cursor = NSCursor.crosshair
		addCursorRect(bounds, cursor: cursor)
	}
	
	override var isFlipped: Bool {
		return true
	}
	
//	func drawHilightedCell() {
//		cellRect.origin = CGPoint(CGFloat(selectedCell.x) * (cellSize.width + cellMargin), CGFloat(selectedCell.y) * (cellSize.height + cellMargin))
//		let newRect = cellRect.insetBy(dx: -cellSize.width*cellMagnificationFactor, dy: -cellSize.height*cellMagnificationFactor)
//		context.setFillColor(colorMatrix[selectedCell.x.uint, selectedCell.y.uint].getColor().cgColor)
//		context.setLineWidth(cellMargin * 4)
//		context.setStrokeColor(gray: 1, alpha: 1.0)
//		context.stroke(newRect)
//		context.fill(newRect)
//	}
	
	override func draw(_ dirtyRect: NSRect) {
		guard let context = NSGraphicsContext.current?.cgContext else { return }

		// background
		context.setFillColor(gray: 0.7, alpha: 1.0)
		context.fill(dirtyRect)
		
		context.setStrokeColor(gray: 0.3, alpha: 1.0)
		context.setLineWidth(cellMargin / 2)
		context.setAllowsAntialiasing(false)
		
		let gridRect = Box(min: viewPointToGridPoint(dirtyRect.origin), max: viewPointToGridPoint(dirtyRect.max))
		var cellRect = CGRect(bounds.minX + cellMargin, bounds.minY + cellMargin, cellSize.width, cellSize.height)
		for x in gridRect.min.x...gridRect.max.x {
			for y in gridRect.min.y...gridRect.max.y {
				cellRect.origin = CGPoint(CGFloat(x) * (cellSize.width + cellMargin), CGFloat(y) * (cellSize.height + cellMargin))
				
				context.setFillColor(colorMatrix[x.uint, y.uint].getColor().cgColor)
				context.stroke(cellRect)
				context.fill(cellRect)
			}
		}
		
		// draw selected cell
		if selectedCell != invalidCell {
			cellRect.origin = CGPoint(CGFloat(selectedCell.x) * (cellSize.width + cellMargin), CGFloat(selectedCell.y) * (cellSize.height + cellMargin))
			let newRect = cellRect.insetBy(dx: -cellSize.width*cellMagnificationFactor, dy: -cellSize.height*cellMagnificationFactor)
			context.setFillColor(colorMatrix[selectedCell.x.uint, selectedCell.y.uint].getColor().cgColor)
			context.setLineWidth(cellMargin * 4)
			context.setStrokeColor(gray: 1, alpha: 1.0)
			context.stroke(newRect)
			context.fill(newRect)
		}
		
		if hoverCell != invalidCell {
			cellRect.origin = CGPoint(CGFloat(hoverCell.x) * (cellSize.width + cellMargin), CGFloat(hoverCell.y) * (cellSize.height + cellMargin))
			let newRect = cellRect.insetBy(dx: -cellSize.width*cellMagnificationFactor, dy: -cellSize.height*cellMagnificationFactor)
			context.setFillColor(colorMatrix[hoverCell.x.uint, hoverCell.y.uint].getColor().cgColor)
			context.setLineWidth(cellMargin * 4)
			context.setStrokeColor(gray: 1, alpha: 1.0)
			context.stroke(newRect)
			context.fill(newRect)
		}

	}
	
	// TODO: scale to fit grid/cell size
	init(frame frameRect: NSRect, gridSize: Span) {
		
		selectedCell = invalidCell
		hoverCell = invalidCell
		cellSize = (frameRect.size - (cellMargin * 12)) / CGSize(CGFloat(gridSize.w), CGFloat(gridSize.h))
//		cellSize.width = floor(cellSize.width)
//		cellSize.height = floor(cellSize.height)
		
		self.gridSize = gridSize
		colorMatrix = PixelMatrix(width: gridSize.w, height: gridSize.h, defaultValue: RGBA8.clearColor())
		
		// TODO: make the view a wrapper for a color swatch matrix which we can fill with apple colors also
		
		let colorRange = gridSize.w
		
		// grays
		for x in 0..<colorRange {
			var color = RGBA8(white: UInt8((255 / colorRange) * x), alpha: 255)
			
			// force pure black & white
			if x == 0 {
				color = RGBA8.blackColor()
			} else if x == colorRange - 1 {
				color = RGBA8.whiteColor()
			}
			
			colorMatrix.setValue(x, 0, color)
		}
		
		// colors
		for y in 1..<gridSize.y {
			for x in 0..<gridSize.w {
				let brightness = 0.1 + (y.float / colorRange.float)
				let saturation = (1.0 + 0.1) - (1.0 / colorRange.float) * y.float
				let hue = x.float / colorRange.float
				let color = NSColor(calibratedHue: CGFloat(hue), saturation: CGFloat(saturation), brightness: CGFloat(brightness), alpha: 1.0)
				colorMatrix.setValue(x, y, color.RGBA8Color())
			}
		}
		

		super.init(frame: frameRect)
	}
	
	required init?(coder decoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	
}

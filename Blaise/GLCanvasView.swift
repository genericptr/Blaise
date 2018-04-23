//
//  CanvasView.swift
//  Blaise
//
//  Created by Ryan Joseph on 4/8/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Foundation
import AppKit
import CoreGraphics
import GLKit

class GLCanvasView: NSOpenGLView, ColorPickerViewDelegate {
	let renderContextCellSize = 64
	
	var mouseDownLocation: CGPoint = CGPoint(x: 0, y: 0)
	var renderContext: RenderContext!
	var tempContext: RenderContext!
	var backBuffer: PixelMatrix!
	var currentBrush: Brush!
	var changedPoints: [CellPos] = []

	var lockedAxis: Int = -1
	
	func copyRenderContextData() -> Data? {
		guard let image = renderContext.bitmapContext.makeImage() else { return nil }
		
		let outImage = NSImage.init(cgImage: image, size: renderContext.getSize())
		if let data = outImage.tiffRepresentation {
			return data
		} else {
			return nil
		}
	}
	
	override var acceptsFirstResponder: Bool {
		return true
	}
	
	override func tabletPoint(with event: NSEvent) {
		if currentBrush.pressure != event.pressure {
			print(event.pressure)
		}
		
		currentBrush.pressure = event.pressure
		updateBrush()
	}
	
	override func keyDown(with event: NSEvent) {
		if event.charactersIgnoringModifiers == "e" {
			renderContext.toggleErase()
		}
	}
	
	func pushChange() {
		if let document = window?.windowController?.document {
			document.updateChangeCount(.changeDone)
		}
	}
	
	func addLine(from: CGPoint, to: CGPoint) {
		renderContext.addLine(from: from, to: to)
		tempContext.addLine(from: from, to: to)
		
		var cellPos = CellPos(to.x.int, to.y.int)
		cellPos = cellPos.clamp(CellPos(0, 0), CellPos(tempContext.width.int - 1, tempContext.height.int - 1))
		changedPoints.append(cellPos)

//		pushChange()
	}
	
	override func mouseDown(with event: NSEvent) {
		window?.makeFirstResponder(self)
		print("mouse down")
		
		// TODO: restore tablet mode?
		if (currentBrush.pressure != 1.0) && (event.subtype != .tabletPoint) {
			currentBrush.pressure = 1.0
			updateBrush()
		}

		changedPoints.removeAll()

		mouseDownLocation = convert(event.locationInWindow, from: nil)
		addLine(from: mouseDownLocation, to: mouseDownLocation)
		let region = renderContext.flushLastAction()
		displayCellsInRegion(region)
		
		lockedAxis = 0
	}
	
	override func mouseDragged(with event: NSEvent) {
		
//        if lockedAxis == 0 {
//            if event.modifierFlags.contains(.shift) {
//        }
		
		var currentLocation = convert(event.locationInWindow, from: nil)

		// TODO: if accumulate is on then allow duplicate dragged events

		let distance = Distance(mouseDownLocation, currentLocation)
		if distance > 0.4 {
			addLine(from: mouseDownLocation, to: currentLocation)

			let region = renderContext.flushLastAction()
			displayCellsInRegion(region)
			print(currentLocation)

			mouseDownLocation = currentLocation
		}
	}
	
	override func mouseUp(with event: NSEvent) {
		finalizeAction()
		lockedAxis = -1
		print("mouse up")
	}
	
	func undo() {
		if let action = UndoManager.shared.pop() {
			print("undo last action")
			
			var changedPoints: [CellPos] = []
			
			for p in action.pixels {
				renderContext.pixels.setValue(x: p.x, y: p.y, value: p.oldColor)
				backBuffer.setValue(x: p.x, y: p.y, value: p.oldColor)
				
				changedPoints.append(p.getPoint())
			}
			
			let region = renderContext.flushPoints(changedPoints)
			displayCellsInRegion(region)
		}
	}
	
	func finalizeAction() {
		let action = UndoableAction(name: "Stroke")
		var region = UnionPoints(changedPoints)

		for x in region.min.x.uint...region.max.x.uint {
			for y in region.min.y.uint...region.max.y.uint {
				let changedColor = tempContext.pixels[x, y]
				
				// TODO: don't assume white background. introduce background color and == operator for RGBA
				// if !changedColor.isWhite() {
				if changedColor.a != 0 {
					let oldColor = backBuffer[x, y]
					let newColor = renderContext.pixels[x, y]

					action.addPixel(x: x, y: y, newColor: newColor, oldColor: oldColor)
					
					backBuffer.setValue(x: x, y: y, value: newColor)
				}
			}
		}
		
		UndoManager.shared.addAction(action)

		tempContext.clearAll()
//        display()
	}
	
	func flush() {
		// NOTE: for single buffered context use glFlush!
//        self.context().flushBuffer()
		glFlush()
	}
	
	func context() -> NSOpenGLContext {
		return self.openGLContext!;
	}
	
	func makeContextCurrent() {
		let context = self.context()
		context.makeCurrentContext()
		
		if (renderContext == nil) {
			createRenderContext()
		}
	}

	func displayCellsInRegion(_ region: Box) {
		makeContextCurrent()

		renderContext.draw(region: region)
		flush()
	}
	
	override func display() {
		makeContextCurrent()
		
		glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
		renderContext.draw(region: Box(top: 0, left: 0, right: Box.PointType(bounds.width), bottom: Box.PointType(bounds.height)))
		flush()
	}

	override func reshape() {
		print("reshape \(self.visibleRect)")
		makeContextCurrent()

		// Update the viewport
		let width = frame.width
		let height = frame.height
		let x = 0
		let y = 0
		glViewport(GLint(x), GLint(y), GLsizei(width), GLsizei(height))
		glMatrixMode(GLenum(GL_PROJECTION))
		glLoadIdentity()
		glOrtho(0.0, GLdouble(width), GLdouble(height), 0.0, 1.0, -1.0)
		glMatrixMode(GLenum(GL_MODELVIEW))
		glLoadIdentity()

		display()
	}
	
	override var isFlipped: Bool {
		return false
	}

	func updateBrush() {
		tempContext.applyBrush(currentBrush)
		renderContext.applyBrush(currentBrush)
	}

	func colorPickerChanged(_ color: RGBA8) {

		currentBrush.color = color
		updateBrush()
	}

	override func viewDidMoveToWindow() {

		// TODO: scale up bitmap to view size and select bit map size at int
		let pickerSize = 64
		//bounds.height.int - pickerSize
		let colorPickerView = ColorPickerView(frame: CGRect(x: 0, y: 0, width: pickerSize, height: pickerSize), pickerSize: pickerSize.uint)
		colorPickerView.delegate = self
		addSubview(colorPickerView)

		let dropShadow = NSShadow()
		dropShadow.shadowColor = NSColor.init(white: 0, alpha: 0.8)
		dropShadow.shadowOffset = NSMakeSize(0, -4.0)
		dropShadow.shadowBlurRadius = 4.0
		
		wantsLayer = true
		shadow = dropShadow

		
		let context = BitmapContext(width: 32, height: 32)
		context.context.setStrokeColor(red: 1, green: 0, blue: 0, alpha: 0.5)
		context.context.fill(context.bounds)
		if let image = context.makeImage() {
			let myCursor: NSCursor = NSCursor(image: NSImage.init(cgImage: image, size: context.bounds.size), hotSpot: NSPoint(x: 0.5, y: 0.5))
			print(myCursor)
			addCursorRect(bounds, cursor: myCursor)
		}

	}
	
	override func resize(withOldSuperviewSize oldSize: NSSize) {
	}
	
	func createOpenGLContext() {
		
		let attr = [
			NSOpenGLPixelFormatAttribute(NSOpenGLPFAOpenGLProfile),
			NSOpenGLPixelFormatAttribute(NSOpenGLProfileVersionLegacy),
			NSOpenGLPixelFormatAttribute(NSOpenGLPFAColorSize), 32,
			NSOpenGLPixelFormatAttribute(NSOpenGLPFAAlphaSize), 8,
			0
		]
		
		let format = NSOpenGLPixelFormat(attributes: attr)
		let context = NSOpenGLContext(format: format!, share: nil)
		
		self.openGLContext = context
		self.openGLContext?.makeCurrentContext()
		print("createOpenGLContext")

		PrintOpenGLInfo()
	}

	
	func createRenderContext() {
		currentBrush = PaintBrush()
		
		renderContext = RenderContext(bounds: self.bounds)
		renderContext.loadTexture(UInt(renderContextCellSize))
		renderContext.prepare()
		renderContext.applyBrush(currentBrush)
		renderContext.clearAll()
		
		tempContext = RenderContext(bounds: self.bounds)
		tempContext.applyBrush(currentBrush)
		tempContext.fill(RGBA8.whiteColor())
		
		// NOTE: testing to flush first cell by default
		// renderContext.flushPoints([CellPos(0, 0)])

		print("load pixel mat \(bounds)")
		backBuffer = PixelMatrix(width: renderContext.width, height: renderContext.height, defaultValue: RGBA8.whiteColor())

		//let colorPicker = ColorPicker(width: 64, height: 64)
		//colorPicker.reload()
		//exit(1)
	}
	
	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		
		createOpenGLContext()
	}
	
	required init?(coder decoder: NSCoder) {
		super.init(coder: decoder)
		
		createOpenGLContext()
	}

}

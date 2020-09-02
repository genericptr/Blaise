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
import OpenGL

// NOTE: we need GLUT for deprecated non-core functions
import GLUT

struct CanvasViewCursor {
    var dragScrolling: Bool = false
    var brushCursor: NSCursor?
}

struct MemoryBuffer {
	var data: Data
	
	mutating func append(value: UnsafeMutableRawPointer, count: Int) {
		var input = value
		let buffer = UnsafeBufferPointer(start: &input, count: count)
		self.data.append(buffer)
	}
	
	mutating func append(record: MemorySizeof) {
		var input = record
		append(value: &input, count: Int(record.sizeof()))
	}

	init(capacity: Int) {
		data = Data(capacity: capacity)
	}
}

class CanvasView: GLCanvasView {
	let renderContextCellSize = 64
	
	weak var overlayView: CanvasOverlayView?
	var renderContext: RenderContext!
	var currentBrush: Brush!
	var cursor: CanvasViewCursor = CanvasViewCursor()
	var style: CanvasStyle = CanvasStyle()
	var viewPort: CGRect = CGRect()
	var mouseDownLocation: CGPoint = CGPoint(-1, -1)

	var lockedAxis: Int = -1
	var debugTracePoint = CGPoint(0, 0)
	var lastDebugTracePoint = CGPoint(0, 0)
	
	var sourceImage: NSImage?
	
	func pushChange() {
			if let document = window?.windowController?.document {
					document.updateChangeCount(.changeDone)
			}
	}
		
	func undo() {
		if let action = UndoManager.shared.pop() {
			print("undo last action")
			var region = Box.infinite()
			
			for p in action.pixels {
				renderContext.setPixel(p.x, p.y, color: p.oldColor)
				region.union(p.x.int, p.y.int)
			}
			
			renderContext.flushRegion(region)
		}
	}
	
	func finalizeAction() {
		let action = UndoableAction(name: "Stroke")
		
		for p in renderContext.lastAction.changedPixels {
			let x = p.x.uint
			let y = p.y.uint
			let pixel = renderContext.lastAction.buffer[x, y]
			action.addPixel(x: x, y: y, newColor: pixel.newColor, oldColor: pixel.oldColor)
		}
		
		UndoManager.shared.addAction(action)
		renderContext.finishAction()
	}
		
	func updateBrush() {
		currentBrush.context = renderContext
		updateBrushCursor()
	}
	
	func updateBrushCursor() {
		
		// NOTE: disabling the brush cursor
//		return
		
		// get scale factor from scroll view
		var scaleFactor: CGFloat = 1.0
		if let scrollView = enclosingScrollView {
				scaleFactor = scrollView.magnification
		}

		let cornerInset: CGFloat = 3
		let minSize: UInt = 5
		let lineWidth: CGFloat = 1.0
		let centerPointRadius: CGFloat = 1.0

		// force a non-even size to center on point
		var width: UInt = UInt((4 + cornerInset) * scaleFactor)
		if width % 2 == 0 { width += 1}
		if width < minSize { width = minSize }

		var height: UInt = UInt((4 + cornerInset) * scaleFactor)
		if height % 2 == 0 { height += 1 }
		if height < minSize { height = minSize }
		
		let cursorContext = BitmapContext(width: width, height: height)
		if let context = cursorContext.context {
					
			let borderInset: CGFloat = 0.0
			let contentRect = cursorContext.bounds.insetBy(dx: borderInset, dy: borderInset)

			context.setShouldAntialias(true)
			context.interpolationQuality = .none
			context.clear(cursorContext.bounds)

			// TODO: do like PS and make 2 cursors which changed based on pixel brightness
			// context.setStrokeColor(gray: 1, alpha: 1)
			// context.setFillColor(gray: 1, alpha: 1)
			// context.fill(CGRect(x: contentRect.width / 2, y: contentRect.height / 2, width: centerPointRadius, height: centerPointRadius))
			// context.setLineWidth(lineWidth*3)
			// context.strokeEllipse(in: contentRect)

			context.setStrokeColor(gray: 0, alpha: 1)
			context.setFillColor(gray: 0, alpha: 1)
			context.fill(CGRect(x: contentRect.width / 2, y: contentRect.height / 2, width: centerPointRadius, height: centerPointRadius))
			context.setLineWidth(lineWidth)
			context.strokeEllipse(in: contentRect)

			if let image = cursorContext.makeImage() {

				// TODO: retina cursors don't work
				// https://stackoverflow.com/questions/19245387/nscursor-using-high-resolution-cursors-with-cursor-zoom-or-retina/28246196#28246196
				// TODO: only update is brush size changed
				
					let cursorImage = NSImage.init(cgImage: image, size: cursorContext.bounds.size)
					cursor.brushCursor = NSCursor(image: cursorImage, hotSpot: NSPoint(x: CGFloat(width / 2), y: CGFloat(height / 2)))
//                print("update brush cursor")
					cursor.brushCursor?.set()
			}
		}
	}

	@objc func fireDebugTracer() {
//		addLine(from: lastDebugTracePoint, to: debugTracePoint)
//		let startPoint = V2i(Int(lastDebugTracePoint.x), Int(lastDebugTracePoint.y))
//		let endPoint = V2i(Int(debugTracePoint.x), Int(debugTracePoint.y))
		
//		renderContext.addLine(from: startPoint, to: endPoint)
		
		currentBrush.begin()
//		currentBrush.apply(from: startPoint, to: endPoint)
		currentBrush.end()
		
		renderContext.flushOperation()

		lastDebugTracePoint = debugTracePoint
		
		debugTracePoint.x += 4
		if debugTracePoint.x > CGFloat(renderContext.width) {
			debugTracePoint.x = 0
			debugTracePoint.y += 4
			lastDebugTracePoint = debugTracePoint
		}
		if debugTracePoint.y > CGFloat(renderContext.height) {
			debugTracePoint.y = 0
			lastDebugTracePoint = debugTracePoint
		}
	}
	
	func renderContextBounds() -> CGRect {
		return self.bounds
//		return CGRect(x: 0, y: 0, width: 64*2, height: 64*2)
	}
	
	func createRenderContext() {
		let contextInfo = RenderContextInfo(backgroundColor: RGBA8.whiteColor, textureCellSize: UInt(renderContextCellSize))

		renderContext = RenderContext(bounds: renderContextBounds(), info: contextInfo)
		renderContext.prepare()
		
		if let sourceImage = sourceImage {
			renderContext.loadImage(sourceImage)
			renderContext.flush()
		} else {
			renderContext.fillWithBackground()
		}
		
//		Timer.scheduledTimer(timeInterval: 0.005, target: self, selector: #selector(fireDebugTracer), userInfo: nil, repeats: true)
		
		PrintOpenGLInfo()
	}
	
	@objc func boundsDidChange() {
		let origin = visibleRect.origin
		var zoomFactor: CGFloat = 1
		
		if let scrollView = enclosingScrollView {
			zoomFactor = scrollView.magnification
		}
		
		if let overlayView = overlayView {
			overlayView.scrollTo(origin: origin, zoom: zoomFactor)
		}
	}
	
	override func viewDidMoveToSuperview() {
		super.viewDidMoveToSuperview()
		
		if let scrollView = enclosingScrollView {
			let contentView = scrollView.contentView
			contentView.postsBoundsChangedNotifications = true
			NotificationCenter.default.addObserver(self, selector: #selector(boundsDidChange), name: NSView.boundsDidChangeNotification, object: contentView)
		}

	}
	
	override func setup() {
		super.setup()
		
		// TODO: where do we load brushes from?
		
		currentBrush = PaintBrush()
		currentBrush.size = 16
		currentBrush.color = RGBA8(0, 40, 150, 255)
		currentBrush.hardness = 0.15
		currentBrush.flow = 0.015
		currentBrush.opacity = 0.5
		currentBrush.pressureEnabled = true
		
//		currentBrush = PaintBrush()
//		currentBrush.size = 16
//		currentBrush.antialias = false
//		currentBrush.color = RGBA8.redColor
//		currentBrush.hardness = 10.0
//		currentBrush.pressureEnabled = true

		updateBrush()
	}
	
	// MARK: NSOpenGLView

	override func makeContextCurrent() {
		super.makeContextCurrent()
		
		if (renderContext == nil) {
				createRenderContext()
		}
	}

	override func draw() {
		glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
		renderContext.draw(region: Box(top: 0, left: 0, right: Box.PointType(bounds.width), bottom: Box.PointType(bounds.height)))
	}

	override func reshape() {
		makeContextCurrent()

		// Update the viewport
		if viewPort != bounds {
			print("reshape \(self.frame)")

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
			viewPort = bounds
			
			setNeedsDisplay(bounds)
		}
	}
	
}

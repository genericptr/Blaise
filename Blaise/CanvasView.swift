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

// TODO: render context coregraphics/image utils

extension RenderContext {
	
	func getBounds() -> CGRect {
		return CGRect(0, 0, CGFloat(width), CGFloat(height))
	}
	
	func makeBitmapContext() -> CGContext? {
		let bytesPerPixel = MemoryLayout<RGBA8>.stride
		
		let bitmapContext = CGContext(
			data: &pixels.table,
			width: Int(width),
			height: Int(height),
			bitsPerComponent: 8,
			bytesPerRow: bytesPerPixel * Int(width),
			space: CGColorSpaceCreateDeviceRGB(),
			bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
			)
		
		return bitmapContext
	}
	
	func saveImageToDisk(_ filePath: String) {
		guard let bitmapContext = makeBitmapContext() else { return }
		guard let image = bitmapContext.makeImage() else { return }
		CGImageWriteToDisk(image, to: URL(fileURLWithPath: filePath))
		print("saved image to \(filePath)")
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
	
	func loadImage(_ image: NSImage) {
		if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
			if let bitmapContext = renderContext.makeBitmapContext() {
				bitmapContext.draw(cgImage, in: renderContext.getBounds())
				bitmapContext.flush()
			} else {
					// bitmap context couldn't be created
			}
		} else {
			// cgimage couldn't be created
		}
	}
	
	func copyImageData(typeName: String) -> Data? {
		guard let bitmapContext = renderContext.makeBitmapContext() else { return nil }
		guard let image = bitmapContext.makeImage() else { return nil }

		let outImage = NSImage.init(cgImage: image, size: renderContext.getSize())
		let data = outImage.tiffRepresentation
		
		let tempRep = NSBitmapImageRep(data: data!)
		var fileType: NSBitmapImageRep.FileType = .tiff
		
		if typeName == kUTTypePNG as String {
			fileType = .png
		} else if typeName == kUTTypeJPEG as String {
			fileType = .jpeg
		} else if typeName == kUTTypeBMP as String {
			fileType = .bmp
		} else if typeName == kUTTypeGIF as String {
			fileType = .gif
		} else if typeName == kUTTypeTIFF as String {
			fileType = .tiff
		}
		
		return tempRep?.representation(using: fileType, properties: [:])
	}
	
	func pushChange() {
			if let document = window?.windowController?.document {
					document.updateChangeCount(.changeDone)
			}
	}
		
	func undo() {
		if let action = UndoManager.shared.pop() {
			print("undo last action")
			
			var changedPoints: [CellPos] = []
			
			for p in action.pixels {
				renderContext.pixels.setValue(x: p.x, y: p.y, value: p.oldColor)
				changedPoints.append(p.getPoint())
			}
			
			renderContext.flushPoints(changedPoints)
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
	
	func displayCellsInRegion(_ region: Box) {
		// NOTE: phasing out for merged flush/draw operation
//		makeContextCurrent()
//		if !region.isInfinite() {
//			renderContext.draw(region: region)
//			flush()
//		}
	}
	
	func updateBrush() {
		currentBrush.context = renderContext
		updateBrushCursor()
	}
	
	func updateBrushCursor() {
		
		return
		
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
		let startPoint = V2i(Int(lastDebugTracePoint.x), Int(lastDebugTracePoint.y))
		let endPoint = V2i(Int(debugTracePoint.x), Int(debugTracePoint.y))
		
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
	
	func createRenderContext() {
		let contextInfo = RenderContextInfo(backgroundColor: RGBA8.whiteColor())

		renderContext = RenderContext(bounds: self.bounds, info: contextInfo)
		renderContext.loadTexture(UInt(renderContextCellSize))
		renderContext.prepare()
		
		if let sourceImage = sourceImage {
			loadImage(sourceImage)
			renderContext.flush()
		} else {
			renderContext.fillWithBackground()
		}
		
		updateBrush()
//		Timer.scheduledTimer(timeInterval: 0.005, target: self, selector: #selector(fireDebugTracer), userInfo: nil, repeats: true)
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
		currentBrush.color = RGBA8(255, 0, 0, 255)
		currentBrush.hardness = 0.15
		currentBrush.flow = 1.0
		currentBrush.opacity = 1.0
		currentBrush.pressureEnabled = true
		
		// NOTE: pencil - make subclass?
//		currentBrush = PaintBrush()
//		currentBrush.size = 1
//		currentBrush.antialias = false
//		currentBrush.color = RGBA8(255, 0, 0, 255)
//		currentBrush.hardness = 1.0
//		currentBrush.pressureEnabled = false

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
			
			display()
		}
	}
	
}

//
//  CanvasOverlayView.swift
//  Blaise
//
//  Created by Ryan Joseph on 4/30/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Cocoa
import OpenGL
import GLUT

class CanvasOverlayView: GLCanvasView {
	
	// TODO: use a blend mode that removes some alpha or something
	let gridColor = RGBA<GLfloat>(white: 0.4, alpha: 0.9)
	let gridLineWidth: GLfloat = 1
	
	var viewOrigin = CGPoint()
	var viewZoom: CGFloat = 1
	
	var gridBuffer: GLuint = 0
	var viewPort: CGRect = CGRect()
	weak var targetView: NSView?
	
	override var isFlipped: Bool { return true }
	
	override var acceptsFirstResponder: Bool { return false }
	
	func scrollTo(origin: CGPoint, zoom: CGFloat) {
		viewOrigin = origin
		viewZoom = zoom
		display()
	}
	
	func resizeToFit(scrollView: NSScrollView) {
		
		// clamp to clip view and flip y
		var newFrame = scrollView.contentView.frame
		if let superview = superview {
			if !superview.isFlipped {
				newFrame.origin.y += scrollView.frame.height - newFrame.height
			}
		}
		
		print(newFrame)
		frame = newFrame
		display()
	}
	
	func pointToLocal(_ point: CGPoint) -> CGPoint {
		var newPoint = point
		if let targetView = targetView {
			if !isFlipped {
				newPoint.y = targetView.bounds.height - newPoint.y
			}
			newPoint = targetView.convert(newPoint, to: self)
		}
		return newPoint
	}
	
	func rectToLocal(_ rect: CGRect) -> CGRect {
		var newRect = rect
		if let targetView = targetView {
			if !isFlipped {
				newRect.origin.y = targetView.bounds.height - newRect.origin.y
			}
			newRect = targetView.convert(newRect, to: self)
		}
		return newRect
	}
	
	func drawCellGrid (x: CGFloat, y: CGFloat) {
		
		glMatrixMode(GLenum(GL_MODELVIEW))
		glLoadIdentity()
		let scale = Float(viewZoom)
		glTranslatef(GLfloat(x), GLfloat(y), 0)
		glTranslatef(0, 0, 0)
		glScalef(scale, scale, 1)

		glBindBuffer(GLenum(GL_ARRAY_BUFFER), gridBuffer)
		glEnableClientState(GLenum(GL_VERTEX_ARRAY))
		glColor4f(gridColor.r, gridColor.g, gridColor.b, gridColor.a)
		glLineWidth(gridLineWidth)
		glVertexPointer(2, GLenum(GL_FLOAT), GLsizei(GLVertex2f.size), nil)
		glDrawArrays(GLenum(GL_LINES), 0, 64*2*2)
		glDisableClientState(GLenum(GL_VERTEX_ARRAY))
		glBindBuffer(GLenum(GL_ARRAY_BUFFER), 0)
	}

	func reloadGridBuffer(_ divisions: Int) {

		var verticies: [GLVertex2f] = []
		let width = divisions
		let height = divisions
		
		// horizontal
		for y in 0..<height {
			let start = GLVertex2f(GLfloat(0), GLfloat(y))
			let end = GLVertex2f(start.x + GLfloat(width), start.y)
			verticies.append(start)
			verticies.append(end)
		}
		
		// vertical
		for x in 0..<width {
			let start = GLVertex2f(GLfloat(x), GLfloat(0))
			let end = GLVertex2f(start.x, start.y + GLfloat(height))
			verticies.append(start)
			verticies.append(end)
		}
		print("verticies \(verticies.count)")
		
		glGenBuffers(1, &gridBuffer)
		glBindBuffer(GLenum(GL_ARRAY_BUFFER), gridBuffer)
		glBufferData(GLenum(GL_ARRAY_BUFFER), verticies.count * GLVertex2f.size, &verticies, GLenum(GL_STATIC_DRAW))
		glBindBuffer(GLenum(GL_ARRAY_BUFFER), 0)
	}

	func testQuad() {
		let bgColor = RGBAf(1, 0, 0, 1)
		let rect = rectToLocal(CGRect(64, 64, 64, 64))
		
		glMatrixMode(GLenum(GL_MODELVIEW))
		glLoadIdentity()
		glTranslatef(GLfloat(rect.minX), GLfloat(rect.minY), 0)

		glBegin(GLenum(GL_QUADS))
			glColor4f(bgColor.r, bgColor.g, bgColor.b, bgColor.a)
			glVertex2f(0.0, 0.0)

			glColor4f(bgColor.r, bgColor.g, bgColor.b, bgColor.a)
			glVertex2f(GLfloat(rect.width), 0.0)

			glColor4f(bgColor.r, bgColor.g, bgColor.b, bgColor.a)
			glVertex2f(GLfloat(rect.width), GLfloat(rect.height))

			glColor4f(bgColor.r, bgColor.g, bgColor.b, bgColor.a)
			glVertex2f(0.0, GLfloat(rect.height))
		glEnd()

	}
	
	override func draw() {
		glClearColor(0, 0.8, 0.3, 1)
		glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
		
//		testQuad()
		print(viewZoom)
		
		if viewZoom >= CGFloat(Prefs.getFloat(.minGridZoom)) {
			
			let cellOrigin = Floor(viewOrigin / 64)
			let cellSize = CGSize(64, 64)
			let gridRect = rectToLocal(CGRect(origin: cellOrigin, size: cellSize))
			print(gridRect)
			
			var x: CGFloat = 0
			var y: CGFloat = gridRect.minY
			while y < frame.height {
				x = gridRect.minX
				while x < frame.width {
//					print("\(x),\(y)")
					drawCellGrid(x: x, y: y)
					x += gridRect.width
				}
				y += gridRect.height
			}
			
			
		}
	}
	
	override func reshape() {
		makeContextCurrent()
		
		// TODO: put this in GLCanvasView for a standard ortho view
		if viewPort != bounds {
			print("reshape overlay")

			let width = bounds.width
			let height = bounds.height
			let x = bounds.minX
			let y = bounds.minY
			glViewport(GLint(x), GLint(y), GLsizei(width), GLsizei(height))
			glMatrixMode(GLenum(GL_PROJECTION))
			glLoadIdentity()
			glOrtho(0.0, GLdouble(width), GLdouble(height), 0.0, 1.0, -1.0)
			glMatrixMode(GLenum(GL_MODELVIEW))
			glLoadIdentity()
			viewPort = bounds
			
		}
		
		setNeedsDisplay(bounds)
	}
	
	override func setup() {
		super.setup()
		
		glEnable(GLenum(GL_BLEND))
		glBlendFunc(GLenum(GL_SRC_ALPHA), GLenum(GL_ONE_MINUS_SRC_ALPHA));
		
		reloadGridBuffer(64)

		var param: GLint = 0
		context().setValues(&param, for: .surfaceOpacity)
	}
	
}

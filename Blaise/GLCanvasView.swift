//
//  GLCanvasView.swift
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

class GLCanvasView: NSOpenGLView {
	
	override func resize(withOldSuperviewSize oldSize: NSSize) {
		// override to prevent flickering inside NSScrollView
	}
	
	private func createOpenGLContext() {
		
		// TODO: to support high-res contexts set this to true
		wantsBestResolutionOpenGLSurface = false
		
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
		
		print("created openGL context")
	}
	
	func flush() {
		glFlush()
	}
	
	func context() -> NSOpenGLContext {
		return self.openGLContext!;
	}
	
	func makeContextCurrent() {
		let context = self.context()
		context.makeCurrentContext()
	}
	
	func draw() {
	}

	func setup() {
		createOpenGLContext()
	}
	
	override func draw(_ dirtyRect: NSRect) {
		makeContextCurrent()
		draw()
		flush()
	}
	
	override init?(frame frameRect: NSRect, pixelFormat format: NSOpenGLPixelFormat?) {
		super.init(frame: frameRect, pixelFormat: format)
	}
	
	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		
//		setup()
	}
	
	required init?(coder decoder: NSCoder) {
		super.init(coder: decoder)
		
//		setup()
	}
	
}

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

class TestView: NSView {
	var mouseDownLocation: CGPoint = CGPoint(x: 0, y: 0)
	
	
	override var acceptsFirstResponder: Bool {
		return true
	}
	
	func addLine(from pointA: CGPoint, to pointB: CGPoint) {
		if let context = NSGraphicsContext.current?.cgContext {
			lockFocus()
			print("draw line")
			context.move(to: pointA)
			context.addLine(to: pointB)
			context.strokePath()
			unlockFocus()
		}
	}

	override func mouseDown(with event: NSEvent) {
		window?.makeFirstResponder(self)
		
		// TODO: we need to make a buffer context for each line
		// then extract the CGImage and draw it into the main context
		// in drawRect: on next pass
		mouseDownLocation = event.locationInWindow
		print(mouseDownLocation)
		addLine(from: mouseDownLocation, to: mouseDownLocation)
		setNeedsDisplay(bounds)
	}
	
	override func mouseUp(with event: NSEvent) {
	}
	
	override func mouseDragged(with event: NSEvent) {
		
		addLine(from: mouseDownLocation, to: event.locationInWindow)
		setNeedsDisplay(bounds)
		
		mouseDownLocation = event.locationInWindow
	}
		
	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)
	}
}

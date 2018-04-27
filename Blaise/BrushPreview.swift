//
//  BrushPreviewView.swift
//  Blaise
//
//  Created by Ryan Joseph on 4/25/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Foundation
import AppKit

// TODO: BrushPreviewView is wrong. refactor to BrushStateView

protocol BrushPreviewViewDelegate {
	func brushStateChanged(_ state: BrushState)
}

class BrushPreviewView: NSView {

	var delegate: AnyObject?
	
	var brushSize: CGFloat = 0 {
		didSet {
			setNeedsDisplay(bounds)
		}
	}
	
	func getState() -> BrushState {
		return BrushState(states: [.size], size: Float(brushSize), antialias: false)
	}
	
	func stateChanged() {
		if let delegate: BrushPreviewViewDelegate = delegate as? BrushPreviewViewDelegate {
			let state = getState()
			delegate.brushStateChanged(state)
		}
	}
	
	override var isFlipped: Bool {
		return true
	}
	
	override func mouseDown(with event: NSEvent) {
	}
	
	override func mouseDragged(with event: NSEvent) {
//		let mouseLocation = convert(event.locationInWindow, from: nil)
	}
	
	override func scrollWheel(with event: NSEvent) {
		brushSize += event.deltaY
		brushSize = floor(brushSize)
		if brushSize < 1 {
			brushSize = 1
		}
		
		stateChanged()
	}
	
	override func draw(_ dirtyRect: NSRect) {
		guard let context = NSGraphicsContext.current?.cgContext else { return }
		
		context.setFillColor(gray: 1, alpha: 1)
		context.fillEllipse(in: bounds)
		context.clip(to: bounds)
		
		context.setFillColor(red: 1, green: 0, blue: 0, alpha: 1)
		
		var radius = brushSize / 2
		if radius < 2 {
			radius = 1
		}
		let brushRect = CGRect(bounds.midX - radius, bounds.midY - radius, radius * 2, radius * 2)
		context.fillEllipse(in: brushRect)
	}

	
}

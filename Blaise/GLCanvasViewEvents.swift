//
//  GLCanvasViewEvents.swift
//  Blaise
//
//  Created by Ryan Joseph on 4/23/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Foundation
import AppKit

extension GLCanvasView {
	override var acceptsFirstResponder: Bool {
		return true
	}
	
	override var isFlipped: Bool {
		return false
	}
	
	override func tabletPoint(with event: NSEvent) {
		
//		if currentBrush.pressure != event.pressure {
//			print(event.pressure)
//		}
		let currentLocation = convert(event.locationInWindow, from: nil)

		var distance: Float = MAXFLOAT
		if !currentBrush.accumulate {
			distance = Distance(mouseDownLocation, currentLocation)
		}
		if distance > 0.4 {
			currentBrush.pressure = event.pressure
			updateBrush()
		}
		
	}

	override func resetCursorRects() {
		updateBrushCursor()
		
		if let brushCursor = cursor.brushCursor {
			addCursorRect(visibleRect, cursor: brushCursor)
		}
	}
	
	override func resize(withOldSuperviewSize oldSize: NSSize) {
		// override to prevent flickering inside NSScrollView
	}

	override func mouseEntered(with event: NSEvent) {
		print("entered")
	}
	
	override func mouseExited(with event: NSEvent) {
		print("mouse exited")
	}
	
	override func scrollWheel(with event: NSEvent) {
		if event.modifierFlags.contains(.option) {
			if let scrollView = enclosingScrollView {
				let point = convert(event.locationInWindow, from: nil)
				let factor = scrollView.magnification
				let amount = event.deltaY / 10
				scrollView.setMagnification(factor + amount, centeredAt: point)
				scrollView.window?.invalidateCursorRects(for: scrollView)
			}
		} else {
			super.scrollWheel(with: event)
		}
	}
	
	override func keyDown(with event: NSEvent) {
		if event.charactersIgnoringModifiers == "e" {
			// TOOD: eraser is part brush subclass now
		}
		
		if event.charactersIgnoringModifiers == " " && !event.isARepeat {
//            let image = NSImage.init(named: NSImage.Name.advanced)
//            let cursor = NSCursor(image: image!, hotSpot: NSPoint(x: 3, y: 3))
			let cursor = NSCursor.openHand
			cursor.push()
			
			self.cursor.dragScrolling = true
		}
	}
	
	override func keyUp(with event: NSEvent) {
		if event.charactersIgnoringModifiers == " " && cursor.dragScrolling {
			cursor.dragScrolling = false
			NSCursor.pop()
		}
	}
	
	override func mouseDown(with event: NSEvent) {
		window?.makeFirstResponder(self)
		print("canvas mouse down")
		mouseDownLocation = convert(event.locationInWindow, from: nil)

		if !cursor.dragScrolling {
			// TODO: restore tablet mode?
			if (currentBrush.pressure != 1.0) && (event.subtype != .tabletPoint) {
				currentBrush.pressure = 1.0
				updateBrush()
			}
			
			renderContext.startAction()
			addLine(from: mouseDownLocation, to: mouseDownLocation)
			let region = renderContext.flushOperation()
			displayCellsInRegion(region)
		}

		lockedAxis = 0
	}
	
	override func mouseDragged(with event: NSEvent) {
		
		// invalid mouse location
		if mouseDownLocation == CGPoint(-1, -1) {
				print("invalid mouse drag")
				super.mouseDragged(with: event)
				return
		}
				
		//        if lockedAxis == 0 {
		//            if event.modifierFlags.contains(.shift) {
		//        }
		
		let currentLocation = convert(event.locationInWindow, from: nil)
		
		// TODO: if accumulate is on then allow duplicate dragged events
		
		if cursor.dragScrolling {
			let delta = mouseDownLocation - currentLocation

			if let scrollView = enclosingScrollView {
				let oldRect = scrollView.documentVisibleRect
				
				var scrollableBounds = scrollView.documentView!.bounds
				scrollableBounds.size.height = scrollableBounds.height - oldRect.height
				scrollableBounds.size.width = scrollableBounds.width - oldRect.width
				
				var newPoint = Clamp(point: oldRect.origin + delta, rect: scrollableBounds)
				 
				// if  scrollable bounds is negative we can't scroll
				if scrollableBounds.size.width < 0 {
					newPoint.x = oldRect.origin.x
				}
				if scrollableBounds.size.height < 0 {
					newPoint.y = oldRect.origin.y
				}

				
				print("scroll to \(newPoint)")
				scrollView.contentView.scroll(to: newPoint)
				scrollView.reflectScrolledClipView(scrollView.contentView)
			}
		} else {
			if (Trunc(mouseDownLocation) != Trunc(currentLocation)) || currentBrush.accumulate {
				addLine(from: mouseDownLocation, to: currentLocation)
				
				let region = renderContext.flushOperation()
				displayCellsInRegion(region)
				
				mouseDownLocation = currentLocation
			}
		}

	}
	
	override func mouseUp(with event: NSEvent) {
		
		// TODO: make renderContext.isLastActionSet()
		if renderContext.lastAction.changedPixels.count > 0 {
			finalizeAction()
			print("canvas mouse up")
		}
		lockedAxis = -1
		mouseDownLocation = CGPoint(-1, -1)
	}
	
	override func viewDidMoveToWindow() {
				
		let dropShadow = NSShadow()
		dropShadow.shadowColor = NSColor.init(white: 0, alpha: 0.8)
		dropShadow.shadowOffset = NSMakeSize(0, -4.0)
		dropShadow.shadowBlurRadius = 4.0
		
		wantsLayer = true
		shadow = dropShadow
		
		layer?.minificationFilter = kCAFilterNearest
		layer?.magnificationFilter = kCAFilterNearest
	}

	
}

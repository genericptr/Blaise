//
//  CanvasViewEvents.swift
//  Blaise
//
//  Created by Ryan Joseph on 4/23/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Foundation
import AppKit

extension CanvasView {
	override var acceptsFirstResponder: Bool {
		return true
	}
	
	override var isFlipped: Bool {
		return true
	}
	
	func mouseLocationInView(event: NSEvent) -> CGPoint {
		return convert(event.locationInWindow, from: nil)
	}
	
	func viewPointToCanvas(_ point: CGPoint) -> V2 {
		var newPoint = V2(Float(point.x), Float(point.y))
//		newPoint.y = renderContext.height.int - newPoint.y
		newPoint = newPoint.clamp(0, 0, renderContext.width.float, renderContext.height.float)
		return newPoint
	}

	override func tabletPoint(with event: NSEvent) {
		
//		if currentBrush.pressure != event.pressure {
//			print(event.pressure)
//		}
//		let currentLocation = mouseLocationInView(event: event)
//
//		var distance: CGFloat = CGFloat(MAXFLOAT)
//		if !currentBrush.accumulate {
//			distance = mouseDownLocation.distance(currentLocation)
//		}
//		if distance > 0.4 {
//			currentBrush.pressure = event.pressure
//			updateBrush()
//		}
		
	}

	override func resetCursorRects() {
		updateBrushCursor()
		
		if let brushCursor = cursor.brushCursor {
			addCursorRect(visibleRect, cursor: brushCursor)
		}
	}
	
	override func scrollWheel(with event: NSEvent) {
		makeContextCurrent()
		
		if event.modifierFlags.contains(.option) {
			if let scrollView = enclosingScrollView {
				let point = mouseLocationInView(event: event)
				let factor = scrollView.magnification
				let amount = event.deltaY / 10
				scrollView.setMagnification(factor + amount, centeredAt: point)
				scrollView.window?.invalidateCursorRects(for: scrollView)
				if let overlayView = overlayView {
					overlayView.display()
				}
			}
		} else if event.modifierFlags.contains(.control) && event.modifierFlags.contains(.command) {
			let v = Float(event.scrollingDeltaY * 0.25)
			currentBrush.size = Clamp(value: currentBrush.size + v, min: 1, max: 64)
			
			
			print("size: \(currentBrush.size)")

		} else if event.modifierFlags.contains(.control) {
			
			let v = Float(event.scrollingDeltaY * 0.005)
			currentBrush.hardness = Clamp(value: currentBrush.hardness + v, min: 0, max: 1)

			print("hardness: \(currentBrush.hardness)")
			
		} else {
			super.scrollWheel(with: event)
		}
	}
	
	override func keyDown(with event: NSEvent) {
		makeContextCurrent()
		
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
		makeContextCurrent()
		
		window?.makeFirstResponder(self)
//		print("canvas mouse down")
		mouseDownLocation = mouseLocationInView(event: event)

		
		if !cursor.dragScrolling {
			
			// TODO: restore tablet mode?
//			if (currentBrush.pressure != 1.0) && (event.subtype != .tabletPoint) {
//				currentBrush.pressure = 1.0
//				updateBrush()
//			}

			currentBrush.pressure = event.pressure
			updateBrush()
			
//			addLine(from: mouseDownLocation, to: mouseDownLocation)
			currentBrush.begin()
			currentBrush.apply(location: viewPointToCanvas(mouseDownLocation))
			renderContext.flushOperation()
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
		
		let currentLocation = mouseLocationInView(event: event)

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

				
				scrollView.contentView.scroll(to: newPoint)
				scrollView.reflectScrolledClipView(scrollView.contentView)
			}
		} else {
			let dragDelta = Float(mouseDownLocation.distance(currentLocation))
			if ((Trunc(mouseDownLocation) != Trunc(currentLocation)) && (dragDelta > currentBrush.minStrokeLength())) || currentBrush.accumulate {
				
				currentBrush.pressure = event.pressure
				updateBrush()
				
				currentBrush.apply(location: viewPointToCanvas(currentLocation))
//				addLine(from: mouseDownLocation, to: currentLocation)
				
				// TODO: merge drawing into flushOperation
				// so we can flush changes when textures run out
				renderContext.flushOperation()
				
				mouseDownLocation = currentLocation
			}
		}

	}
	
	override func mouseUp(with event: NSEvent) {
		
		if renderContext.isLastActionSet() {
			finalizeAction()
//			print("canvas mouse up")
		}
		
		currentBrush.end()
		lockedAxis = -1
		mouseDownLocation = CGPoint(-1, -1)
	}
	
	override func viewDidMoveToWindow() {
				
		let dropShadow = NSShadow()
		let shadowSize: CGFloat = 4.0
		dropShadow.shadowColor = NSColor.init(white: 0, alpha: 0.8)
		if isFlipped {
			dropShadow.shadowOffset = NSMakeSize(0, shadowSize)
		} else {
			dropShadow.shadowOffset = NSMakeSize(0, -shadowSize)
		}
		dropShadow.shadowBlurRadius = shadowSize
		
		wantsLayer = true
		shadow = dropShadow
		
		layer?.minificationFilter = kCAFilterNearest
		layer?.magnificationFilter = kCAFilterNearest
	}

	
}

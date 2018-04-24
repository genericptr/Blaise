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
		if currentBrush.pressure != event.pressure {
			print(event.pressure)
		}
		
		currentBrush.pressure = event.pressure
		updateBrush()
	}

	override func resetCursorRects() {
		updateBrushCursor()
		
		if let brushCursor = cursor.brushCursor {
			addCursorRect(visibleRect, cursor: brushCursor)
		}
	}
	
	override func viewDidMoveToWindow() {
		
		// TODO: scale up bitmap to view size and select bit map size at int
		// let pickerSize = 64
		// let colorPickerView = ColorPickerView(frame: CGRect(x: 0, y: 0, width: pickerSize, height: pickerSize), pickerSize: pickerSize.uint)
		// colorPickerView.delegate = self
		// addSubview(colorPickerView)
		
		let colorGridView = ColorGridView(frame: CGRect(x: 0, y: bounds.height - 150, width: 120, height: 120), gridSize: Span(12, 12 + 1))
//		 colorGridView.delegate = self
		 addSubview(colorGridView)

		let dropShadow = NSShadow()
		dropShadow.shadowColor = NSColor.init(white: 0, alpha: 0.8)
		dropShadow.shadowOffset = NSMakeSize(0, -4.0)
		dropShadow.shadowBlurRadius = 4.0
		
		wantsLayer = true
		shadow = dropShadow
		
		layer?.minificationFilter = kCAFilterNearest
		layer?.magnificationFilter = kCAFilterNearest
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
		print("mouse down")
		mouseDownLocation = convert(event.locationInWindow, from: nil)

		if !cursor.dragScrolling {
			// TODO: restore tablet mode?
			if (currentBrush.pressure != 1.0) && (event.subtype != .tabletPoint) {
				currentBrush.pressure = 1.0
				updateBrush()
			}
			
			changedPoints.removeAll()
			
			addLine(from: mouseDownLocation, to: mouseDownLocation)
			let region = renderContext.flushLastAction()
			displayCellsInRegion(region)
		}

		lockedAxis = 0
	}
	
	override func mouseDragged(with event: NSEvent) {
		
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
			let distance = Distance(mouseDownLocation, currentLocation)
			if distance > 0.4 {
				addLine(from: mouseDownLocation, to: currentLocation)
				
				let region = renderContext.flushLastAction()
				displayCellsInRegion(region)
				
				mouseDownLocation = currentLocation
			}
		}

	}
	
	override func mouseUp(with event: NSEvent) {
		
		if changedPoints.count > 0 {
			finalizeAction()
		}
		lockedAxis = -1
		print("mouse up")
	}
}
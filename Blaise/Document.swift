//
//  Document.swift
//  Blaise
//
//  Created by Ryan Joseph on 4/8/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Cocoa

class DocumentWindowConroller: NSWindowController, NSWindowDelegate {
	
	func windowDidBecomeKey(_ notification: Notification) {
		if let canvasView: GLCanvasView = document?.canvasView {
			canvasView.makeContextCurrent()
            window?.invalidateCursorRects(for: canvasView)
		}
		
	}
	
	override func windowDidLoad() {
		window?.delegate = self
	}
}

class CenteredClipView: NSClipView {
	override func constrainBoundsRect(_ proposedBounds: NSRect) -> NSRect {
		
		var rect = super.constrainBoundsRect(proposedBounds)
		if let containerView = self.documentView {
			
			if (rect.size.width > containerView.frame.size.width) {
				rect.origin.x = (containerView.frame.width - rect.width) / 2
			}
			
			if(rect.size.height > containerView.frame.size.height) {
				rect.origin.y = (containerView.frame.height - rect.height) / 2
			}
		}
		
		return rect
	}
}

class DocumentBackgroundView: NSView {
	
	override func draw(_ dirtyRect: NSRect) {
		if let context = NSGraphicsContext.current?.cgContext {
			let color = NSColor.lightGray
			context.setFillColor(color.cgColor)
			context.fill(dirtyRect)
		}
	}
	
	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
	}
	
	required init?(coder decoder: NSCoder) {
		super.init(coder: decoder)
		// wantsLayer = true
	}
	
}

class Document: NSDocument {

	@IBOutlet weak var canvasView: GLCanvasView!
	
	@IBOutlet weak var scrollView: NSScrollView!
	
	override init() {
		super.init()
		// Add your subclass-specific initialization here.
	}

	@IBAction func undoAction(_ sender: Any) {
		canvasView.undo()
	}
	
	@IBAction func changeTool(_ sender: Any) {
		Swift.print("change from document")
	}
	
	@IBAction func zoomIn(_ sender: Any) {
		Swift.print("zoom in")
        var mousePoint = scrollView.window!.mouseLocationOutsideOfEventStream
        mousePoint = canvasView.convert(mousePoint, from: nil)
        
		let factor = scrollView.magnification
		scrollView.setMagnification(factor + 0.25, centeredAt: mousePoint)
	}

	@IBAction func zoomOut(_ sender: Any) {
		Swift.print("zoom out")
        var mousePoint = scrollView.window!.mouseLocationOutsideOfEventStream
        mousePoint = canvasView.convert(mousePoint, from: nil)

		let factor = scrollView.magnification
		scrollView.setMagnification(factor - 0.25, centeredAt: mousePoint)
	}

	@IBAction func zoomToActualSize(_ sender: Any) {
		Swift.print("zoom actual size")
        var mousePoint = scrollView.window!.mouseLocationOutsideOfEventStream
        mousePoint = canvasView.convert(mousePoint, from: nil)

		scrollView.setMagnification(1.0, centeredAt: mousePoint)
	}
    
	override class var autosavesInPlace: Bool {
		return false
	}

	override func makeWindowControllers() {
		let controller = DocumentWindowConroller.init(windowNibName: NSNib.Name(rawValue: "Document"), owner: self)
		addWindowController(controller)
	}
	
	override func windowControllerDidLoadNib(_ windowController: NSWindowController) {
		guard let window = windowController.window else { return }
			
		Swift.print(window)
		
		// TOOD: set this based on new document window
		canvasView.setFrameSize([1200, 800].cgSize)
		
		scrollView.verticalScrollElasticity = .none
		scrollView.horizontalScrollElasticity = .none
	}
	
	override func data(ofType typeName: String) throws -> Data {
		if let data = canvasView.copyRenderContextData() {
			return data
		} else {
			throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
		}
	}

	override func read(from data: Data, ofType typeName: String) throws {
		// Insert code here to read your document from the given data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning false.
		// You can also choose to override readFromFileWrapper:ofType:error: or readFromURL:ofType:error: instead.
		// If you override either of these, you should also override -isEntireFileLoaded to return false if the contents are lazily loaded.
		throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
	}


}


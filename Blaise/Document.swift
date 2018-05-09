//
//  Document.swift
//  Blaise
//
//  Created by Ryan Joseph on 4/8/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Cocoa

// MARK: DocumentWindowConroller

class DocumentWindowConroller: NSWindowController, NSWindowDelegate {
	
	func windowDidBecomeKey(_ notification: Notification) {
		if let canvasView: CanvasView = document?.canvasView {
			canvasView.makeContextCurrent()
            window?.invalidateCursorRects(for: canvasView)
		}
		
	}
	
	override func windowDidLoad() {
		window?.delegate = self
	}
}

// MARK: CenteredClipView

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

// MARK: DocumentBackgroundView

class DocumentBackgroundView: NSView {
	weak var document: Document?
	
	override func resizeSubviews(withOldSize oldSize: NSSize) {
		super.resizeSubviews(withOldSize: oldSize)
		
		if let document = document {
			document.backgroundViewBoundsChanged()
		}
	}
	
	override func draw(_ dirtyRect: NSRect) {
		if let context = NSGraphicsContext.current?.cgContext {
			let color = NSColor.lightGray
			context.setFillColor(color.cgColor)
			context.fill(dirtyRect)
		}
	}
	
}

protocol MemoryUsage {
	func calculateTotalMemoryUsage(bytes: inout UInt64)
}

// MARK: Document

class Document: NSDocument, MemoryUsage {

	@IBOutlet weak var canvasView: CanvasView!
	@IBOutlet weak var scrollView: NSScrollView!
	@IBOutlet weak var backgroundView: DocumentBackgroundView!
	
	var brushPalette: BrushPaletteView?
	var openedImage: NSImage?
	var overlayView: CanvasOverlayView?

	@IBAction func undoAction(_ sender: Any) {
		canvasView.undo()
	}
	
	@IBAction func redoAction(_ sender: Any) {
		// TODO: we forgot redo!
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
	
	func backgroundViewBoundsChanged() {
		overlayView?.resizeToFit(scrollView: scrollView)
	}
	
	func calculateTotalMemoryUsage(bytes: inout UInt64) {
		
		
		canvasView.renderContext.calculateTotalMemoryUsage(bytes: &bytes)
		UndoManager.shared.calculateTotalMemoryUsage(bytes: &bytes)
		
	}
	
	override class var autosavesInPlace: Bool { return false }
	
	override func makeWindowControllers() {
		let controller = DocumentWindowConroller.init(windowNibName: NSNib.Name(rawValue: "Document"), owner: self)
		addWindowController(controller)
	}
	
	override func windowControllerDidLoadNib(_ windowController: NSWindowController) {
//		guard let window = windowController.window else { return }
		
		Prefs.set(.minGridZoom, 16)
		
		// TOOD: set this based on new document window
		
		if let openedImage = openedImage {
			canvasView.sourceImage = openedImage
			canvasView.setFrameSize(openedImage.size)
		} else {
			canvasView.setFrameSize([300, 300].cgSize)
		}
		
		openedImage = nil

		scrollView.verticalScrollElasticity = .none
		scrollView.horizontalScrollElasticity = .none
		scrollView.minMagnification = 0.25
		scrollView.maxMagnification = 32.0
		
		// overlay view
		overlayView = CanvasOverlayView(frame: scrollView.frame)
		backgroundView.addSubview(overlayView!)
		overlayView?.targetView = canvasView
		canvasView.overlayView = overlayView
		
		backgroundView.document = self
		
		scrollView.contentView.scroll(to: CGPoint(0, 0))
		scrollView.reflectScrolledClipView(scrollView.contentView)
		//CGFloat(Prefs.getFloat(.minGridZoom))
		scrollView.setMagnification(1, centeredAt: CGPoint())

		backgroundViewBoundsChanged()

//		brushPalette = BrushPaletteView.init(nibName: NSNib.Name(rawValue: "BrushPaletteView"), bundle: nil)
//		if let brushPalette = brushPalette  {
//			scrollView.addSubview(brushPalette.view)
//			brushPalette.canvas = canvasView
//		}
	}
	
	override func writableTypes(for saveOperation: NSDocument.SaveOperationType) -> [String] {
		let types = [kUTTypePNG,
								 kUTTypeJPEG,
								 kUTTypeBMP,
								 kUTTypeGIF,
								 kUTTypeTIFF
								 ]
		return types as [String]//NSImage.imageTypes
	}
		
	override func data(ofType typeName: String) throws -> Data {
		if let data = canvasView.copyImageData(typeName: typeName) {
			return data
		} else {
			throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
		}
	}

	override func read(from url: URL, ofType typeName: String) throws {
		
		if let tempRep = NSImageRep(contentsOf: url) {
			Swift.print("\(tempRep.pixelsWide)x\(tempRep.pixelsHigh)")
			openedImage = NSImage(size: NSMakeSize(CGFloat(tempRep.pixelsWide), CGFloat(tempRep.pixelsHigh)))
			openedImage?.addRepresentation(tempRep)
		} else {
			throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
		}

	}
	

}


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
import GLKit

struct CanvasViewCursor {
    var dragScrolling: Bool = false
    var brushCursor: NSCursor?
}

class GLCanvasView: NSOpenGLView, ColorPickerViewDelegate {
	let renderContextCellSize = 64
	
	var mouseDownLocation: CGPoint = CGPoint(x: 0, y: 0)
	var renderContext: RenderContext!
	var tempContext: RenderContext!
	var backBuffer: PixelMatrix!
	var currentBrush: Brush!
	var changedPoints: [CellPos] = []
	var cursor: CanvasViewCursor = CanvasViewCursor()
	var style: CanvasStyle = CanvasStyle()
    
	var lockedAxis: Int = -1
	
	func copyRenderContextData() -> Data? {
		guard let image = renderContext.bitmapContext.makeImage() else { return nil }
		
		let outImage = NSImage.init(cgImage: image, size: renderContext.getSize())
		if let data = outImage.tiffRepresentation {
			return data
		} else {
			return nil
		}
	}
	
    func pushChange() {
        if let document = window?.windowController?.document {
            document.updateChangeCount(.changeDone)
        }
    }
    
    func addLine(from: CGPoint, to: CGPoint) {
        renderContext.addLine(from: from, to: to)
        tempContext.addLine(from: from, to: to)
        
        var cellPos = CellPos(to.x.int, to.y.int)
        cellPos = cellPos.clamp(CellPos(0, 0), CellPos(tempContext.width.int - 1, tempContext.height.int - 1))
        changedPoints.append(cellPos)
        
        //        pushChange()
    }
    		
	func undo() {
		if let action = UndoManager.shared.pop() {
			print("undo last action")
			
			var changedPoints: [CellPos] = []
			
			for p in action.pixels {
				renderContext.pixels.setValue(x: p.x, y: p.y, value: p.oldColor)
				backBuffer.setValue(x: p.x, y: p.y, value: p.oldColor)
				
				changedPoints.append(p.getPoint())
			}
			
			let region = renderContext.flushPoints(changedPoints)
			displayCellsInRegion(region)
		}
	}
	
	func finalizeAction() {
		let action = UndoableAction(name: "Stroke")
		let region = UnionPoints(changedPoints)

		for x in region.min.x.uint...region.max.x.uint {
			for y in region.min.y.uint...region.max.y.uint {
				let changedColor = tempContext.pixels[x, y]
				
				if changedColor.a > 0 {
					let oldColor = backBuffer[x, y]
					let newColor = renderContext.pixels[x, y]

					action.addPixel(x: x, y: y, newColor: newColor, oldColor: oldColor)
					
					backBuffer.setValue(x: x, y: y, value: newColor)
				}
			}
		}
		
		UndoManager.shared.addAction(action)

		tempContext.clear()
//        display()
	}
	
	func displayCellsInRegion(_ region: Box) {
		makeContextCurrent()

		renderContext.draw(region: region)
		flush()
	}
	
	func updateBrush() {
		tempContext.applyBrush(currentBrush)
		renderContext.applyBrush(currentBrush)
		
        updateBrushCursor()
	}
	
	func updateBrushCursor() {
        
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

	func colorPickerChanged(_ color: RGBA8) {

		currentBrush.color = color
		updateBrush()
	}
    
  func createRenderContext() {
      currentBrush = PaintBrush()
		
			let contextInfo = RenderContextInfo(backgroundColor: RGBA8.clearColor())
		
			renderContext = RenderContext(bounds: self.bounds, info: contextInfo)
      renderContext.loadTexture(UInt(renderContextCellSize))
      renderContext.prepare()
      renderContext.applyBrush(currentBrush)
      renderContext.fillWithBackground()
      
			tempContext = RenderContext(bounds: self.bounds, info: contextInfo)
      tempContext.applyBrush(currentBrush)
      tempContext.clear()
      
      // NOTE: testing to flush first cell by default
      // renderContext.flushPoints([CellPos(0, 0)])
      
      print("load pixel mat \(bounds)")
      backBuffer = PixelMatrix(width: renderContext.width, height: renderContext.height, defaultValue: RGBA8.whiteColor())
      
      //let colorPicker = ColorPicker(width: 64, height: 64)
      //colorPicker.reload()
      //exit(1)
  }

  // MARK: NSOpenGLView
  func flush() {
      // NOTE: for single buffered context use glFlush!
      //        self.context().flushBuffer()
      glFlush()
  }
  
  func context() -> NSOpenGLContext {
      return self.openGLContext!;
  }
  
  func makeContextCurrent() {
      let context = self.context()
      context.makeCurrentContext()
      
      if (renderContext == nil) {
          createRenderContext()
      }
  }

  override func display() {
      makeContextCurrent()
      
      glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
      renderContext.draw(region: Box(top: 0, left: 0, right: Box.PointType(bounds.width), bottom: Box.PointType(bounds.height)))
      flush()
  }
  
  override func reshape() {
      // print("reshape \(self.visibleRect)")
      makeContextCurrent()
      
      // Update the viewport
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
      
      display()
  }
    
	func createOpenGLContext() {
		
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

		PrintOpenGLInfo()
	}

	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		
		createOpenGLContext()
	}
	
	required init?(coder decoder: NSCoder) {
		super.init(coder: decoder)
		
		createOpenGLContext()
	}

}

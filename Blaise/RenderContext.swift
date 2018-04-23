//
//  Bitmap.swift
//  Blaise
//
//  Created by Ryan Joseph on 4/8/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Foundation
import CoreGraphics
import AppKit
import OpenGL
import GLUT

struct RenderContextBrushState {
	var lineWidth: Float = 0
	var antialias: Bool = false
}

class RenderContext {
	var bitmapContext: CGContext!
	var pixels: PixelMatrix!
	var texture: RenderTexture!
	var bounds: CGRect
	var eraser: Bool = false
	// var brushLineWidth: Float = 0
	var brushState: RenderContextBrushState

	var width: UInt = 0
	var height: UInt = 0
	
	var dirtyPoints: [CellPos] = []
	
	func getDimensions() -> CellDim {
		return CellDim(width, height)
	}
	
	func getSize() -> CGSize {
		return CGSize(width: CGFloat(width), height: CGFloat(height))
	}
	
	func clearAll() {
		// TODO: use background color
		bitmapContext.clear(CGRect(x: 0, y: 0, width: width.int, height: height.int))
		// bitmapContext.setFillColor(red: 0, green: 1, blue: 0, alpha: 1)
		// bitmapContext.fill(CGRect(x: 0, y: 0, width: Int(width), height: Int(height)))
		bitmapContext.synchronize()
	}
	
	func fill(_ color: RGBA8) {
		// TODO: use background color
		bitmapContext.saveGState()
		bitmapContext.setFillColor(color.getColor().cgColor)
		bitmapContext.fill(CGRect(x: 0, y: 0, width: Int(width), height: Int(height)))
		bitmapContext.restoreGState()
		bitmapContext.synchronize()
	}

	// TODO: temporary, not sure how to handle different brushes
	func toggleErase() {
		if eraser {
			bitmapContext.setBlendMode(.normal)
			bitmapContext.setShouldAntialias(true)
			eraser = false
			print("eraser off")
		} else {
			bitmapContext.setBlendMode(.clear)
			// bitmapContext.setStrokeColor(red: 1, green: 1, blue: 1, alpha: 1)
			bitmapContext.setShouldAntialias(false)
			eraser = true
			print("eraser on")
		}
	}
	
	func applyBrush(_ brush: Brush) {
		brush.apply(bitmapContext)
		brushState.lineWidth = brush.brushSize()
		brushState.antialias = brush.antialias
	}
	
	func addLine(from pointA: CGPoint, to pointB: CGPoint) {
		bitmapContext.move(to: pointA)
		bitmapContext.addLine(to: pointB)
		bitmapContext.strokePath()
		
		if texture != nil {
			// flip back to matrix coordiantes from context coordiantes
			var matrixPoint = FlipY(point: pointA, bounds: pixels.bounds)
			var cellPos = CGPointToCellPos(matrixPoint)
			cellPos = cellPos.clamp(CellPos(0, 0), CellPos(width.int - 1, height.int - 1))
			dirtyPoints.append(cellPos)
			
			matrixPoint = FlipY(point: pointB, bounds: pixels.bounds)
			cellPos = CGPointToCellPos(matrixPoint)
			cellPos = cellPos.clamp(CellPos(0, 0), CellPos(width.int - 1, height.int - 1))
			dirtyPoints.append(cellPos)
		}
	}

	func flushPoints(_ points: [CellPos]) -> Box {
		var box = UnionPoints(points)
		
		// inset for brush size
		box = box.inset(x: -Int(brushState.lineWidth * 2), y: -Int(brushState.lineWidth * 2))
		box = box.clamp(Box(0, 0, width.int - 1, height.int - 1))
		
		bitmapContext.flush()
		texture.reloadRegion(box, source: pixels)
		
		dirtyPoints.removeAll()
		return box
	}

	func flushLastAction() -> Box {
		return flushPoints(dirtyPoints)
	}
	
	func draw(region: Box) {
		let cellRegion = region / texture.cellSize
		for x in cellRegion.min.x...cellRegion.max.x {
			for y in cellRegion.min.y...cellRegion.max.y {
				texture.drawCell(x: UInt(x), y: UInt(y), textureUnit: 0)
			}
		}
	}

	func drawPixels() {
		glDrawPixels(GLsizei(width), GLsizei(height), GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), &pixels.table)
	}

	func saveImageToDisk(_ filePath: String) {
		guard let image = bitmapContext.makeImage() else { return }
		CGImageWriteToDisk(image, to: URL(fileURLWithPath: filePath))
		print("saved image to \(filePath)")
	}

	func prepare() {
		print("prepare opengl context")
		glClearColor(1.0, 1.0, 1.0, 1.0)
		
		glEnable(GLenum(GL_TEXTURE_2D))
		glEnable(GLenum(GL_BLEND))
		glBlendFunc(GLenum(GL_SRC_ALPHA), GLenum(GL_ONE_MINUS_SRC_ALPHA));
		
		// TODO: this needs to be the visible rect
		// glViewport(0, 0, GLsizei(width), GLsizei(height))
		// glMatrixMode(GLenum(GL_PROJECTION))
		// glLoadIdentity()
		// glOrtho(0.0, GLdouble(width), GLdouble(height), 0.0, 1.0, -1.0)
		// glMatrixMode(GLenum(GL_MODELVIEW))
		// glLoadIdentity()
	}
	
	init(bounds contextBounds: CGRect) {
		self.bounds = contextBounds
		
		let resolution = CGFloat(1.0)//                                                                                                                                                       NSScreen.main!.backingScaleFactor

		width = UInt(self.bounds.width * resolution)
		height = UInt(self.bounds.height * resolution)
		brushState = RenderContextBrushState()

		loadBitmap()
	}
	
	func loadTexture(_ cellSize: UInt) {
		texture = RenderTexture(width: width, height: height, cellDim: CellDim(cellSize, cellSize))
	}

	func loadBitmap() {
		
		let defaultColor = RGBA8.whiteColor()
		pixels = PixelMatrix(width: width, height: height, defaultValue: defaultColor)
		let bytesPerComponent = MemoryLayout<RGBA8.PixelType>.size
		
		pixels.table.withUnsafeMutableBytes { pointer in
			bitmapContext = CGContext(
				data: pointer.baseAddress,
				width: Int(width),
				height: Int(height),
				bitsPerComponent: bytesPerComponent * 8,
				bytesPerRow: (bytesPerComponent * 4) * Int(width),
				space: CGColorSpaceCreateDeviceRGB(),
				bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
				)!

			bitmapContext.interpolationQuality = .none
			bitmapContext.setShouldAntialias(true)
			
//			bitmapContext.setFillColor(red: 1, green: 0, blue: 0, alpha: 1)
//			bitmapContext.fill(CGRect(x: 0, y: Int(height) - 32, width: 32, height: 32))
//			bitmapContext.synchronize()
		}
		
		//        for i in 0..<10 {
		//            print(pixels.table[i])
		//        }
	}

}


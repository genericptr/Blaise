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

struct RenderContextInfo {
	var backgroundColor: RGBA8
}

// TODO: refactor this and move to it's own unit. the name doesnt really make sense

struct ActionPixel {
	var oldColor: RGBA8
	var newColor: RGBA8
	var empty: Bool
	
	init(newColor: RGBA8, oldColor: RGBA8, empty: Bool) {
		self.newColor = newColor
		self.oldColor = oldColor
		self.empty = empty
	}
	
	init() {
		empty = true
		newColor = RGBA8(0, 0, 0, 0)
		oldColor = RGBA8(0, 0, 0, 0)
	}
}

class RenderLastAction {
	var buffer: Matrix<ActionPixel>
	var changedPixels: [CellPos]
	var region: Box
		
	func clear() {
		for p in changedPixels {
			buffer[p.x.uint, p.y.uint] = ActionPixel()
		}
		changedPixels.removeAll(keepingCapacity: true)
		region = Box.infinite()
	}
	
	func setPixel(_ x: UInt, _ y: UInt, newColor: RGBA8, oldColor: RGBA8) {
		if buffer[x, y].empty {
			buffer[x, y] = ActionPixel(newColor: newColor, oldColor: oldColor, empty: false)
			changedPixels.append(CellPos(x.int, y.int))
		} else {
			buffer[x, y].newColor = newColor
		}
	}
	
	init(width: UInt, height: UInt) {
		region = Box.infinite()
		changedPixels = []
		buffer = Matrix<ActionPixel>(width: width, height: height, defaultValue: ActionPixel())
	}
}

class RenderContext {
	var bitmapContext: CGContext!
	var pixels: PixelMatrix!
	var texture: RenderTexture!
	var bounds: CGRect
	var eraser: Bool = false
	var brushState: RenderContextBrushState
	var contextInfo: RenderContextInfo
	var width: UInt = 0
	var height: UInt = 0
	var lastAction: RenderLastAction!
	var lastOperationRegion: Box

	func getDimensions() -> CellDim {
		return CellDim(width, height)
	}
	
	func getSize() -> CGSize {
		return CGSize(width: CGFloat(width), height: CGFloat(height))
	}
	
	func startAction() {
		print("start action")
	}
	
	func finishAction() {
		lastAction.clear()
		print("end action")
	}
	
	func clear() {
		pixels.fill(RGBA8.clearColor())
	}
	
	func fill(_ color: RGBA8) {
		pixels.fill(color)
	}
	
	func fillWithBackground() {
		fill(contextInfo.backgroundColor)
	}
	
	func applyBrush(_ brush: Brush) {
		brush.apply(bitmapContext)
		brushState.lineWidth = brush.brushSize()
		brushState.antialias = brush.antialias
	}
	
	func blendColors (src: RGBA8, dest: RGBA8) -> RGBA8 {
		let a = Float(src.a) / 255
		let premulSrc = RGBAf((Float(src.r) / 255) * a, (Float(src.g) / 255) * a, (Float(src.b) / 255) * a, a)
		let blend = Clamp(value: premulSrc + (dest.getRGBAf() * (1 - a)), min: 0, max: 1)
		return blend.getRGBA8()
	}
	
	func plotPixel(_ x: UInt, _ y: UInt, _ color: RGBA8) {
		
		lastAction.setPixel(x, y, newColor: color, oldColor: pixels[x, y])
		lastOperationRegion.union(x.int, y.int)

		pixels.setValue(x, y, color)
		
		// TODO: write directly to texture buffer and mark texture as dirty
		// so we don't overdraw
		// in fact we can ommit the entire region loop if we keep a dict
		// of changed textures
		texture.setPixel(x: x, y: y, source: pixels)

	}
	
	func drawPoint(_ point: V2i) {
		var origin = point
		
		let px = origin.x.uint
		let py = origin.y.uint
		
		let color = RGBA8(255, 0, 0, 255/1)//RGBA8(white: 0, alpha: 100)
		let dest = pixels[px, py]
		let blend = blendColors(src: color, dest: dest)
		
		plotPixel(px, py, blend)
		
		lastAction.region.union(origin)
	}
	
	func drawLine(from startPoint: V2i, to endPoint: V2i) {
		if startPoint != endPoint {
			PlotLine(x0: startPoint.x, y0: startPoint.y, x1: endPoint.x, y1: endPoint.y, plot: {
				drawPoint(V2i($0, $1))
			})
		} else {
			drawPoint(startPoint)
		}
	}

	func drawCircle(_ point: V2i) {

		
		// https://stackoverflow.com/questions/1201200/fast-algorithm-for-drawing-filled-circles
		// https://stackoverflow.com/questions/10878209/midpoint-circle-algorithm-for-filled-circle
		
		var origin = point
//		origin.y = height.int - origin.y

		let r: Int = 8 / 2//brushState.lineWidth.int / 2

		let rr = r * r
		let range = Int(rr.float + r.float * 0.8)
		
		let color = RGBA8(255, 0, 0, 255/2)//RGBA8(white: 0, alpha: 100)

		for y in -r...r {
			let yy = y * y
			for x in -r...r {
				if (x*x + yy <= range ) {
					var p = V2i(origin.x + x, origin.y + y)
					p = p.clamp(V2i(0, 0), V2i(width.int - 1, height.int - 1))
					let px = p.x.uint
					let py = p.y.uint

					let dest = pixels[px, py]
					let blend = blendColors(src: color, dest: dest)
					plotPixel(px, py, blend)
				}
			}
		}
		
		lastAction.region.union(Box(minX: origin.x - r, minY: origin.y - r, maxX: origin.x + r, maxY: origin.y + r))
		
	}
	
	func strokeLine(from startPoint: V2i, to endPoint: V2i) {
		if startPoint != endPoint {
			PlotLine(x0: startPoint.x, y0: startPoint.y, x1: endPoint.x, y1: endPoint.y, plot: {
				drawCircle(V2i($0, $1))
			})
		} else {
			drawCircle(startPoint)
		}
	}

	
	func addLine(from pointA: CGPoint, to pointB: CGPoint) {
		// TODO: once we're finished move this to canvas view
		// so we only take integral numbers in matrix coords
		// to the render context
		var startPoint = V2i(Int(pointA.x), Int(pointA.y))
		startPoint.y = height.int - startPoint.y
		
		var endPoint = V2i(Int(pointB.x), Int(pointB.y))
		endPoint.y = height.int - endPoint.y

		strokeLine(from: startPoint, to: endPoint)
//		drawCircle(pointA)
	}
	
	func flushOperation() -> Box {
		let box = lastOperationRegion
		// TODO: we can now write directly to the texture buffer instead of
		// copying from the render buffer
		texture.reloadRegion(box, source: pixels)
		lastOperationRegion = Box.infinite()
		return box
	}
	
	func flushPoints(_ points: [CellPos]) -> Box {
		var box = UnionPoints(points)
		texture.reloadRegion(box, source: pixels)
		return box
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
//    let bgColor = contextInfo.backgroundColor.getRGBAf()
//		glClearColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a)
		glClearColor(1.0, 1.0, 1.0, 1.0)
		

		// TODO: this blending is wrong for transparent backgrounds
		glEnable(GLenum(GL_TEXTURE_2D))
		glEnable(GLenum(GL_BLEND))
		glBlendFunc(GLenum(GL_SRC_ALPHA), GLenum(GL_ONE_MINUS_SRC_ALPHA));
	}
	
	init(bounds: CGRect, info: RenderContextInfo) {
		self.bounds = bounds
		contextInfo = info
		lastOperationRegion = Box.infinite()
		
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
		
		lastAction = RenderLastAction(width: width, height: height)
		pixels = PixelMatrix(width: width, height: height, defaultValue: contextInfo.backgroundColor)
		let bytesPerPixel = MemoryLayout<RGBA8>.stride
		let totalBytes = bytesPerPixel * width.int * height.int
		print("total bytes: \(totalBytes) @ \(width)x\(height)")
		
		pixels.table.withUnsafeMutableBytes { pointer in
			bitmapContext = CGContext(
				data: pointer.baseAddress,
				width: Int(width),
				height: Int(height),
				bitsPerComponent: 8,
				bytesPerRow: bytesPerPixel * Int(width),
				space: CGColorSpaceCreateDeviceRGB(),
				bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
				)!

			bitmapContext.interpolationQuality = .none
			
//			bitmapContext.setFillColor(red: 1, green: 0, blue: 0, alpha: 1)
//			bitmapContext.fill(CGRect(x: 0, y: Int(height) - 32, width: 32, height: 32))
//			bitmapContext.synchronize()
		}
	}

}


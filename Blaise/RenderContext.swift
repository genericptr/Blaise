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

func PlotLine2(pt0: V2, pt1: V2, plot: (_ x: Int, _ y: Int) -> Void) {
	let dx = abs(pt1.x - pt0.x)
	let dy = abs(pt1.y - pt0.y)
	
	var x: Int = Int(pt0.x)
	var y: Int = Int(pt0.y)
	
	let dt_dx: Float = 1.0 / dx
	let dt_dy: Float = 1.0 / dy
	
	var n: Int = 1
	var x_inc, y_inc: Int
	var t_next_y, t_next_x: Float

	
	if (dx == 0) {
		x_inc = 0
		t_next_x = dt_dx // infinity
	} else if (pt1.x > pt0.x) {
		x_inc = 1
		n += Int(pt1.x) - x
		t_next_x = Float(pt0.x + 1 - pt0.x) * dt_dx
	} else {
		x_inc = -1
		n += x - Int(pt1.x)
		t_next_x = Float(pt0.x - pt0.x) * dt_dx
	}
	
	
	if (dy == 0) {
		y_inc = 0
		t_next_y = dt_dy // infinity
	} else if (pt1.y > pt0.y) {
		y_inc = 1;
		n += Int(pt1.y) - y;
		t_next_y = Float(pt0.y + 1 - pt0.y) * dt_dy;
	} else {
		y_inc = -1
		n += y - Int(pt1.y)
		t_next_y = Float(pt0.y - pt0.y) * dt_dy
	}
	
	while n > 0 {
		
		plot(x, y)
		
		if (t_next_x <= t_next_y) { // t_next_x is smallest
			x += x_inc
			t_next_x += dt_dx
		} else if (t_next_y <= t_next_x) { // t_next_y is smallest
			y += y_inc
			t_next_y += dt_dy
		}
		n -= 1
	}

}

func PlotLine(x0: Int, y0: Int, x1: Int, y1: Int, plot: (_ x: Int, _ y: Int) -> Void) {
	
	let dx: Int = abs(x1-x0)
	let sx = x0<x1 ? 1 : -1
	let dy: Int = abs(y1-y0)
	let sy = y0<y1 ? 1 : -1
	var err: Int = (dx>dy ? dx : -dy)/2
	var e2: Int
	var x: Int = x0
	var y: Int = y0
	
	while true {
		plot(x,y)
		if (x==x1 && y==y1) {
			break
		}
		e2 = err
		if (e2 > -dx) {
			err -= dy
			x += sx
		}
		if (e2 < dy) {
			err += dx
			y += sy
		}
	}
}

struct RenderContextBrushState {
	var lineWidth: Float = 0
	var antialias: Bool = false
}

// TODO: how do we control pixel depth/size?
struct RenderContextInfo {
	var backgroundColor: RGBA8
	
}

class RenderContext {
	var bitmapContext: CGContext!
	var pixels: PixelMatrix!
	var texture: RenderTexture!
	var bounds: CGRect
	var eraser: Bool = false
	var brushState: RenderContextBrushState
	var contextInfo: RenderContextInfo
	var lastActionPoints: [CellPos]
	
	var width: UInt = 0
	var height: UInt = 0
	
	var dirtyPoints: [CellPos] = []
	
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
		print("end action")
	}
	
	func clear() {
		bitmapContext.clear(CGRect(x: 0, y: 0, width: width.int, height: height.int))
		bitmapContext.synchronize()
	}
	
	func fill(_ color: RGBA8) {
		bitmapContext.saveGState()
		bitmapContext.setFillColor(color.getColor().cgColor)
		bitmapContext.fill(CGRect(x: 0, y: 0, width: Int(width), height: Int(height)))
		bitmapContext.restoreGState()
		bitmapContext.synchronize()
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
	
	func addPixel(_ x: UInt, _ y: UInt, _ color: RGBA8) {
		pixels.setValue(x, y, color)
		lastActionPoints.append(CellPos(x, y))
	}
	
	func drawPoint(_ point: V2i) {
		
		// TODO: if we move to bitmap based make all the render context functions
		// taked origin 0,0 matrix coords
		var origin = point
//		origin.y = height.int - origin.y
		
		let px = origin.x.uint
		let py = origin.y.uint
		
		let color = RGBA8(255, 0, 0, 255/1)//RGBA8(white: 0, alpha: 100)
		let dest = pixels[px, py]
		let blend = blendColors(src: color, dest: dest)
		
		pixels.setValue(px, py, blend)
	}
	
	func drawLine(from pointA: CGPoint, to pointB: CGPoint) {
		
		var startPoint = V2i(Int(pointA.x), Int(pointA.y))
		startPoint.y = height.int - startPoint.y
		
		var endPoint = V2i(Int(pointB.x), Int(pointB.y))
		endPoint.y = height.int - endPoint.y
		
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
					pixels.setValue(px, py, blend)
				}
			}
		}
		
	}
	
	func strokeLine(from pointA: CGPoint, to pointB: CGPoint) {
		
		var startPoint = V2i(Int(pointA.x), Int(pointA.y))
		startPoint.y = height.int - startPoint.y
		
		var endPoint = V2i(Int(pointB.x), Int(pointB.y))
		endPoint.y = height.int - endPoint.y
		
		if startPoint != endPoint {
			PlotLine(x0: startPoint.x, y0: startPoint.y, x1: endPoint.x, y1: endPoint.y, plot: {
				drawCircle(V2i($0, $1))
			})
		} else {
			drawCircle(startPoint)
		}
	}

	
	func addLine(from pointA: CGPoint, to pointB: CGPoint) {
		
//		bitmapContext.move(to: pointA)
//		bitmapContext.addLine(to: pointB)
//		bitmapContext.strokePath()
		
		// TOOD: we don't need to scan the canvas for undo changes
		// since we ploted the points ourself!
		
		strokeLine(from: pointA, to: pointB)
//		drawCircle(pointA)
		
		
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
	
	func flushLastAction_2() -> Box {
		var box = UnionPoints(lastActionPoints)
		
		texture.reloadRegion(box, source: pixels)
		
		lastActionPoints.removeAll(keepingCapacity: true)
		return box
	}

	func flushPoints(_ points: [CellPos]) -> Box {
		var box = UnionPoints(points)
		
		// inset for brush size
		box = box.inset(x: -Int(brushState.lineWidth * 2), y: -Int(brushState.lineWidth * 2))
		box = box.clamp(Box(0, 0, width.int - 1, height.int - 1))
		
//		bitmapContext.flush()
		texture.reloadRegion(box, source: pixels)
		
		dirtyPoints.removeAll(keepingCapacity: true)
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


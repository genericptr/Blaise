//
//  RenderDrawing.swift
//  Blaise
//
//  Created by Ryan Joseph on 5/1/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Foundation
import Darwin

typealias BrushStampMatrix = Matrix<UInt8>
typealias BrushStampDictionary = Dictionary<String, BrushStampMatrix>

var BrushStamps = BrushStampDictionary()

extension RenderContext {
	
	private func unionPixelChanges(_ box: Box) {
		lastOperationRegion.union(box)
		lastAction.region.union(box)
	}

	private func unionPixelChanges<T: BinaryInteger>(x: T, y: T) {
		lastOperationRegion.union(Int(x), Int(y))
		lastAction.region.union(Int(x), Int(y))
	}
	
	public func clear() {
		texture.fill(RGBA8.clearColor)
	}
	
	public func fill(_ color: RGBA8) {
		texture.fill(color)
	}
	
	public func fillWithBackground() {
		fill(contextInfo.backgroundColor)
	}
	
	public func getPixel<T: BinaryInteger> (_ x: T, _ y: T) -> RGBA8 {
		return texture.getPixel(UInt(x), UInt(y))
	}
	
	public func setPixel<T: BinaryInteger> (_ x: T, _ y: T, color: RGBA8) {
		return texture.setPixel(UInt(x), UInt(y), color: color)
	}

	private func plotPixel(_ x: UInt, _ y: UInt, _ color: RGBA8, _ alpha: UInt8) {
		lastAction.setPixel(x, y, newColor: color, oldColor: getPixel(x, y), alpha: alpha)
		texture.setPixel(x, y, color: color)
	}
	
	private func drawPoint_aa(_ point: V2, alpha: Float = 1.0) {
		
		let px = point.x.uint
		let py = point.y.uint
		let ox = point.x - Float(px)
		let oy = point.y - Float(py)

		let c = (1 - (fabs(0.5 + (ox - 1)) + fabs(0.5 + (oy - 1)))) * alpha

		// TODO: replace this with a sampling kernel like in drawCircle_aa
		
		let xl = ((0.5 - ox) / 2) * alpha
		let xr = ((ox - 0.5) / 2) * alpha
		let yl = ((0.5 - oy) / 2) * alpha
		let yr = ((oy - 0.5) / 2) * alpha
		
		drawPoint(px, py, c)
		
		if xl > 0 { drawPoint(px - 1, py, xl) }
		if xr > 0 { drawPoint(px + 1, py, xr) }
		if yl > 0 { drawPoint(px, py - 1, yl) }
		if yr > 0 { drawPoint(px, py + 1, yr) }

		if xl > 0 && yl > 0 { drawPoint(px - 1, py - 1, (xl / 2) + (yl / 2)) } // top left
		if xr > 0 && yl > 0 { drawPoint(px + 1, py - 1, (xr / 2) + (yl / 2)) } // top right

		if xl > 0 && yr > 0 { drawPoint(px - 1, py + 1, (xl / 2) + (yr / 2)) } // bottom left
		if xr > 0 && yr > 0 { drawPoint(px + 1, py + 1, (xr / 2) + (yr / 2)) } // bottom right

		// TODO: union box that covers entire 2x2 region
//		lastAction.region.union(V2i(Int(px), Int(py)))
		unionPixelChanges(x: px, y: py)
	}
	
	private func drawPoint(_ point: V2, alpha: Float = 1.0) {
		let px = point.x.uint
		let py = point.y.uint
		
		let color = RGBA8(255, 0, 0, UInt8(255 * alpha))
		let dest = getPixel(px, py)
		let blend = BlendColors(src: color, dest: dest)
		
		plotPixel(px, py, blend, color.a)
		
//		lastAction.region.union(V2i(Int(px), Int(py)))
		unionPixelChanges(x: px, y: py)
	}

	private func drawPoint(_ px: UInt, _ py: UInt, _ alpha: Float) {
		let a = UInt8(Clamp(value: Float(255) * alpha, min: 0, max: 255))
		let color = RGBA8(255, 0, 0, a)
		let dest = getPixel(px, py)
		let blend = BlendColors(src: color, dest: dest)
		
		plotPixel(px, py, blend, color.a)
		
//		lastAction.region.union(V2i(Int(px), Int(py)))
		unionPixelChanges(x: px, y: py)
	}
	
	private func drawPoint(_ point: V2i) {
		let px = point.x.uint
		let py = point.y.uint
		
		let color = RGBA8(255, 0, 0, 255)
		let dest = getPixel(px, py)
		let blend = BlendColors(src: color, dest: dest)
		
		plotPixel(px, py, blend, color.a)
		
//		lastAction.region.union(point)
		unionPixelChanges(x: px, y: py)
	}
	
	private func drawLine(from startPoint: V2i, to endPoint: V2i) {
		if startPoint != endPoint {
			PlotLine(x0: startPoint.x, y0: startPoint.y, x1: endPoint.x, y1: endPoint.y, plot: {
				drawPoint(V2i($0, $1))
			})
		} else {
			drawPoint(startPoint)
		}
	}
	
	private func loadBrushStamp(hardness: Float, radius r: Int) -> BrushStampMatrix {
		
		let key = "\(hardness)\(r)"
		var stamp: BrushStampMatrix
		
		let rr = r * r
		let range = Int(rr.float + r.float * 1.5)
		
		// cache brush
		if !BrushStamps.keys.contains(key) {
			stamp = BrushStampMatrix(width: UInt((r * 2) + 1), height: UInt((r * 2) + 1), defaultValue: 0)
			
			for y in -r...r {
				let yy = y * y
				for x in -r...r {
					if (x*x + yy <= range) {
						
						// TODO: this needs to be a quadaric curve with a better falloff
						// instead of lerping.
						var dist = 1 - Magnitude(Float(x), Float(y)) / Float(r)
						dist = Lerp(t: dist, a: -0.2, b: hardness)
						
						let newAlpha = Clamp(value: Int(dist * Float(255)), min: 0, max: 255)
						let finalAlpha = UInt8(Clamp(value: newAlpha, min: 1, max: 255))
						let pos = CellPos(x + r, y + r)
						
						// TODO: keep min/max position because cells can be empty
						
						stamp[pos.x, pos.y] = finalAlpha
					}
				}
			}
			
			print("cached brush \(key)")
			BrushStamps[key] = stamp
		} else {
			stamp = BrushStamps[key]!
		}
		
		return stamp
	}
	
	private func drawCircle_aa(_ origin: V2) {
		guard let brush = brush else { return }
		
		let ox = origin.x - trunc(origin.x) - 0.5
		let oy = origin.y - trunc(origin.y) - 0.5
		let dx = 0.5 - ox < 0.5 ? 1 : -1
		let dy = 0.5 - oy < 0.5 ? 1 : -1

		
		// TODO: take this a param to drawCircle so
		// we can load it once when the line is drawn
		// instead of for each pass
		var r: Int = Int(brush.brushSize() / 2)
		if r < 2 { r = 2 }
		
		var color = brush.color
		let opacity: Float = 1.0
		let flow: Float = 1.0
		let hardness = Map(percent: brush.hardness, min: 1, max: 5)
		
		let stamp = loadBrushStamp(hardness: hardness, radius: r)
		
		// stamp cached brush
		var box = Box(0, 0, stamp.width, stamp.height)
		
		// inset to allow oversampling
		if dx < 0 {
			box.min.x -= 1
		} else if dx > 0 {
			box.max.x += 1
		}

		if dy < 0 {
			box.min.y -= 1
		} else if dy > 0 {
			box.max.y += 1
		}

		for x in box.x..<box.maxX {
			for y in box.y..<box.maxY {
				
				if stamp.isValid(x, y) {
					color.a = stamp[x, y]
					color.a = UInt8(color.a * flow * opacity)
				} else {
					color.a = 0
				}
				
				if color.a > 0 {
					var p = V2(origin.x + (x - r), origin.y + (y - r))
					p = p.clamp(V2(0, 0), V2(width - 1, height - 1))
					
					let px = p.x.int
					let py = p.y.int
					let dest = getPixel(px, py)

					
					// offset to sample alpha
					let sx = x - dx
					let sy = y - dy
					var ax: Float = 0
 					var ay: Float = 0

					// sample offset alpha
					if stamp.getValueOrDefault(sx, y, default: 1) == 1 {
						ax = -255 * fabsf(ox)
					} else {
						ax = stamp[sx, y] * fabsf(ox)
					}
					
					if stamp.getValueOrDefault(x, sy, default: 1) == 1 {
						ay = -255 * fabsf(oy)
					} else {
						ay = stamp[x, sy] * fabsf(oy)
					}
					
					// combine source alpha for sampled alpha
					color.a = UInt8(Clamp(value: color.a + ax + ay, min: 0, max: 255))
					
					let blend = BlendColors(src: color, dest: dest)
					plotPixel(px.uint, py.uint, blend, color.a)
				}
			}
		}
		
//		lastAction.region.union(Box(minX: origin.x.int - r, minY: origin.y.int - r, maxX: origin.x.int + r, maxY: origin.y.int + r))
		unionPixelChanges(Box(minX: origin.x.int - r, minY: origin.y.int - r, maxX: origin.x.int + r, maxY: origin.y.int + r))
	}
	
	// https://stackoverflow.com/questions/1201200/fast-algorithm-for-drawing-filled-circles
	// https://stackoverflow.com/questions/10878209/midpoint-circle-algorithm-for-filled-circle
	
	private func drawCircle(_ origin: V2i) {
		guard let brush = brush else { return }
		
		var r: Int = Int(brush.brushSize() / 2)
		if r < 2 {
			r = 2
		}
		
		var color = brush.color
		let opacity: Float = 1.0
		let flow: Float = 1.0
		let hardness = Map(percent: brush.hardness, min: 1, max: 5)
		
		let stamp = loadBrushStamp(hardness: hardness, radius: r)
		
		// stamp cached brush
		for x in 0..<stamp.width {
			for y in 0..<stamp.height {
				color.a = stamp[x, y]
				if color.a > 0 {
					var p = V2i(origin.x + (x.int - r), origin.y + (y.int - r))
					p = p.clamp(V2i(0, 0), V2i(width.int - 1, height.int - 1))

					let px = p.x.uint
					let py = p.y.uint
					let dest = getPixel(px, py)

					color.a = UInt8(Float(color.a) * flow)
					color.a = UInt8(Float(color.a) * opacity)

//					if opacity < 1 {
//						var destAlpha: UInt8 = 0
//						if lastAction.isPixelSet(px, py, alpha: &destAlpha) {
//							let newAlpha = (Int(color.a) + Int(destAlpha)) - Int(255 * opacity)
//							color.a = UInt8(Clamp(value: newAlpha, min: 0, max: 255))
//						}
//					}
					
					let blend = BlendColors(src: color, dest: dest)
					plotPixel(px, py, blend, color.a)
				}
			}
		}
		
//		lastAction.region.union(Box(minX: origin.x - r, minY: origin.y - r, maxX: origin.x + r, maxY: origin.y + r))
		unionPixelChanges(Box(minX: origin.x - r, minY: origin.y - r, maxX: origin.x + r, maxY: origin.y + r))
	}
	
	public func strokeLine_aa(from startPoint: V2, to endPoint: V2) {
		
		guard let brush = brush else { return }
		var lastPoint = V2(-1000, -1000)
		
		if startPoint != endPoint {
			PlotLine(p0: startPoint, p1: endPoint, plot: {
				let point = V2($0, $1)
//				if point.trunc() == overlapPoint {
//					return
//				}
//				let delta = Float(point.distance(lastPoint))
//				if delta >= brush.minStrokeLength() - 1 {
//					drawCircle_aa(point)
//					lastPoint = point
//				}
				drawCircle_aa(point)
			})
		} else {
			drawCircle_aa(startPoint)
		}
	}
	
	public func strokeLine(from startPoint: V2i, to endPoint: V2i) {
		
		guard let brush = brush else { return }
		var lastPoint = V2i(-1000, -1000)
		
		if startPoint != endPoint {
			PlotLine(x0: startPoint.x, y0: startPoint.y, x1: endPoint.x, y1: endPoint.y, plot: {
				let point = V2i($0, $1)
				if point == overlapPoint {
					return
				}
				let delta = Float(point.distance(lastPoint))
				if delta >= brush.minStrokeLength() - 1 {
					drawCircle(point)
					lastPoint = point
				}
//				drawCircle(V2i($0, $1))
			})
		} else {
			drawCircle(startPoint)
		}
	}
	
	public func strokePoints_aa(from startPoint: V2, to endPoint: V2) {
		
		if startPoint != endPoint {
			PlotLine_AA(Vec2<Double>(Double(startPoint.x), Double(startPoint.y)), Vec2<Double>(Double(endPoint.x), Double(endPoint.y)), plot: {
				let alpha = Float($0)
				let point = V2(Float($1), Float($2))
				drawPoint(point, alpha: alpha)
			})
		} else {
			drawPoint_aa(startPoint)
		}
	}
	
	public func strokePoints(from startPoint: V2i, to endPoint: V2i) {
		if startPoint != endPoint {
			PlotLine(x0: startPoint.x, y0: startPoint.y, x1: endPoint.x, y1: endPoint.y, plot: {
				
				let point = V2i($0, $1)
				if point == overlapPoint {
					return
				}

				drawPoint(point)
			})
		} else {
			drawPoint(startPoint)
		}
	}
		
}

// MARK: Utils

fileprivate func BlendColors (src: RGBA8, dest: RGBA8) -> RGBA8 {
	let a = Float(src.a) / 255
	let preMulSrc = RGBAf((Float(src.r) / 255) * a, (Float(src.g) / 255) * a, (Float(src.b) / 255) * a, a)
	var blend = preMulSrc + (dest.getRGBAf() * (1 - a))
	blend = Clamp(value: blend, min: 0, max: 1)
	return blend.getRGBA8()
}


//
//  Bitmap.swift
//  Blaise
//
//  Created by Ryan Joseph on 4/8/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Foundation
import AppKit
import OpenGL

// TODO: DEPRECATED, remove CoreGraphics
import CoreGraphics

struct RenderContextBrushState {
	var lineWidth: Float = 0
	var antialias: Bool = false
}

struct RenderContextInfo {
	var backgroundColor: RGBA8
}

class RenderContext: MemoryUsage {
	var pixels: PixelMatrix!
	var texture: RenderTexture!
	var bounds: CGRect
	var eraser: Bool = false
	var contextInfo: RenderContextInfo
	var width: UInt = 0
	var height: UInt = 0
	var lastAction: RenderLastAction!
	var lastOperationRegion: Box
	var brush: Brush?
	
	
	// NOTE: TESTING
	var overlapPoint: V2i = V2i(-1, -1)
	
	func calculateTotalMemoryUsage(bytes: inout UInt64) {
		
		bytes += UInt64(pixels.elementStride * pixels.count)

		for cache in BrushStamps.values {
			bytes += UInt64(cache.elementStride * cache.count)
		}
		
		if (texture != nil) {
			texture.calculateTotalMemoryUsage(bytes: &bytes)
		}
	}
	
	func getDimensions() -> CellDim {
		return CellDim(width, height)
	}
	
	func getSize() -> CGSize {
		return CGSize(width: CGFloat(width), height: CGFloat(height))
	}
	
	func isLastActionSet() -> Bool {
		return lastAction.changedPixels.count > 0
	}
	
	func finishAction() {
		lastAction.clear()
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
	
	private func flushContext() {
		glFlush()
	}
	
	func flushOperation() {
		let box = lastOperationRegion
		if !box.isInfinite() {
			texture.reloadDirtyCells(box)
			flushContext()
		}
		lastOperationRegion = Box.infinite()
	}
	
	func flushPoints(_ points: [CellPos]) {
		let box = UnionPoints(points)
		texture.reloadRegion(box, source: pixels)
		flushContext()
	}
	
	func flush() {
		let box = Box(0, 0, width.int, height.int)
		texture.reloadRegion(box, source: pixels)
		flushContext()
	}
	
	func draw(region: Box) {
		print("[")
		let cellRegion = region / texture.cellSize
		for x in cellRegion.min.x...cellRegion.max.x {
			for y in cellRegion.min.y...cellRegion.max.y {
				texture.drawCell(x: UInt(x), y: UInt(y), textureUnit: 0)
			}
		}
		print("]")
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
		
		loadBitmap()
	}
	
	func loadTexture(_ cellSize: UInt) {
		texture = RenderTexture(width: width, height: height, cellDim: CellDim(cellSize, cellSize))
	}
		
	func loadBitmap() {
		lastAction = RenderLastAction(width: width, height: height)
		pixels = PixelMatrix(width: width, height: height, defaultValue: contextInfo.backgroundColor)
	}

}


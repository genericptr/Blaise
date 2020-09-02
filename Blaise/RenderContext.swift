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
import CoreGraphics

struct RenderContextBrushState {
	var lineWidth: Float = 0
	var antialias: Bool = false
}

struct RenderContextInfo {
	var backgroundColor: RGBA8
	var textureCellSize: UInt
}

class RenderContext: MemoryUsage {
	
	var contextInfo: RenderContextInfo
	var layers: RenderLayers
	var currentLayer: RenderLayer
	var texture: RenderTexture { return currentLayer.texture }

	var bounds: CGRect
	var width: UInt = 0
	var height: UInt = 0
	var lastAction: RenderLastAction!
	var lastOperationRegion: Box
	var brush: Brush?
	var clipRects: [Box] = []
	
	// NOTE: TESTING
	var overlapPoint: V2i = V2i(-1, -1)
	
	func calculateTotalMemoryUsage(bytes: inout UInt64) {
		for cache in BrushStamps.values {
			bytes += UInt64(cache.elementStride * cache.count)
		}
		texture.calculateTotalMemoryUsage(bytes: &bytes)
	}
	
	public func isLastActionSet() -> Bool {
		return lastAction.changedPixels.count > 0
	}
	
	public func finishAction() {
		lastAction.clear()
	}
			
	public func getLastOperationCellRegion() -> Box {
		return texture.convertRectToCells(lastOperationRegion)
	}
		
	private func pushClipRect(_ region: Box) {
		glScissor(GLint(region.minX), GLint(height - (region.minY + region.height)), GLsizei(region.width), GLsizei(region.height))
		glEnable(GLenum(GL_SCISSOR_TEST))
		clipRects.append(region)
	}
	
	private func popClipRect() {
		if clipRects.count > 0 {
			if let clipRect = clipRects.popLast() {
				glScissor(GLint(clipRect.minX), GLint(height - (clipRect.minY + clipRect.height)), GLsizei(clipRect.width), GLsizei(clipRect.height))
			} else {
				glDisable(GLenum(GL_SCISSOR_TEST))
			}
		} else {
			fatalError("unbalanced clip rects")
		}
	}
	
	private func clearContext() {
		glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
	}
	
	private func flushContext() {
		glFlush()
	}
	
	public func flushOperation() {
		let box = lastOperationRegion
		if !box.isInfinite() {
			pushClipRect(box)
			clearContext()
			
			for layer in layers.layers {
				if layer === currentLayer {
					layer.reloadDirtyCells(box)
				} else {
					layer.draw(box)
				}
			}
			
			flushContext()
			popClipRect()
		}
		lastOperationRegion = Box.infinite()
	}
	
	public func flushRegion(_ region: Box) {
		pushClipRect(region)
		clearContext()
		for layer in layers.layers {
			if layer === currentLayer {
				layer.reloadRegion(region)
			} else {
				layer.draw(region)
			}
		}
		flushContext()
		popClipRect()
	}

	public func flush() {
		// TODO: does this mean reload all layers or just reload current layer
		// and redraw the rest?
		flushRegion(Box(0, 0, width.int, height.int))
	}
	
	public func draw(region: Box) {
		for layer in layers.layers {
			layer.draw(region)
		}
		flushContext()
	}

	public func prepare() {
		print("prepare opengl context")
		glClearColor(1, 1, 1, 1)
		glEnable(GLenum(GL_TEXTURE_2D))
		glEnable(GLenum(GL_BLEND))
		glBlendFunc(GLenum(GL_SRC_ALPHA), GLenum(GL_ONE_MINUS_SRC_ALPHA));
		glDisable(GLenum(GL_DEPTH_TEST))
	}
	
	init(bounds: CGRect, info: RenderContextInfo) {
		self.bounds = bounds
		contextInfo = info
		lastOperationRegion = Box.infinite()
		
		let resolution = CGFloat(1.0)//                                                                                                                                                       NSScreen.main!.backingScaleFactor

		width = UInt(self.bounds.width * resolution)
		height = UInt(self.bounds.height * resolution)
		
		lastAction = RenderLastAction(width: width, height: height)
		
		layers = RenderLayers(width: width, height: height, contextInfo: info)
		
		// TODO: RenderLayers class should keep the current
		currentLayer = layers.addLayer()
		
		// NOTE: can't load images now because we don't have a unified pixel buffer
		// to read into
		/*
		let pictLayer = layers.addLayer()
		if let image = NSImage(contentsOfFile: "/Users/ryanjoseph/Downloads/if_brush_87006.png") {
			pictLayer.clear()
			pictLayer.loadImage(image)
		} else {
			fatalError("failed to load image")
		}
		*/
	}

}


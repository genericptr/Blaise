//
//  RenderLayers.swift
//  Blaise
//
//  Created by Ryan Joseph on 5/9/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Foundation
import AppKit

enum LayerBlendMode {
	case normal
}

//struct RenderLayerInfo {
//	var width: UInt = 0
//	var height: UInt = 0
//	var hidden: Bool = false
//	var locked: Bool = false
//	var blendMode: LayerBlendMode = .normal
//	var translate: V2 = V2(0, 0)
//	var name: String = "untitled"
//}

class RenderLayer: MemoryUsage {
	var texture: RenderTexture
	
	var width: UInt = 0
	var height: UInt = 0
	var hidden: Bool = false
	var locked: Bool = false
	var blendMode: LayerBlendMode = .normal
	var translate: V2 = V2(0, 0)
	var name: String = "untitled"
	
	func calculateTotalMemoryUsage(bytes: inout UInt64) {
		for cache in BrushStamps.values {
			bytes += UInt64(cache.elementStride * cache.count)
		}
		texture.calculateTotalMemoryUsage(bytes: &bytes)
	}
	
	public func reload()  {
		reloadRegion(Box(0, 0, width, height))
	}

	public func reloadRegion(_ region: Box)  {
		texture.reloadDirtyCells(region)
	}
	
	public func reloadDirtyCells(_ region: Box)  {
		texture.reloadDirtyCells(region)
	}
	
	public func draw(_ region: Box) {
		let cellRegion = texture.convertRectToCells(region)
		for x in cellRegion.min.x...cellRegion.max.x {
			for y in cellRegion.min.y...cellRegion.max.y {
				texture.drawCell(x: UInt(x), y: UInt(y), textureUnit: 0)
			}
		}
	}
	
	// image loading
	
	private func mapToBitmapContext() -> CGContext? {
		let bytesPerPixel = MemoryLayout<RGBA8>.stride
		
		#if DEBUG_PIXELS
		let bitmapContext = CGContext(
			data: &pixels.table,
			width: Int(width),
			height: Int(height),
			bitsPerComponent: 8,
			bytesPerRow: bytesPerPixel * Int(width),
			space: CGColorSpaceCreateDeviceRGB(),
			bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
		)
		return BitmapContext
		#else
		fatalError("layer mapToBitmapContext needs pixel buffer")
		#endif
	}
	
	public func loadImage(_ image: NSImage) {
		if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
			if let bitmapContext = mapToBitmapContext() {
				// TODO: place at point, scale etc..?
				let bounds = CGRect(0, CGFloat(height-image.size.width), image.size.width, image.size.height)
				bitmapContext.draw(cgImage, in: bounds)
				bitmapContext.flush()
				// TODO: we need to reload but not draw
				reloadRegion(Box(0, 0, image.size.width-1, image.size.height-1))
			} else {
				fatalError("bitmap context couldn't be created")
			}
		} else {
			fatalError("cgimage couldn't be created")
		}
	}

	public func clear() {
		texture.fill(RGBA8.clearColor)
	}

	// initializers
	
	init(width: UInt, height: UInt, contextInfo: RenderContextInfo) {
		self.width = width
		self.height = height
		texture = RenderTexture(width: width, height: height, cellDim: CellDim(contextInfo.textureCellSize, contextInfo.textureCellSize), defaultColor: contextInfo.backgroundColor)
	}
		
}

class RenderLayers {
	var width: UInt
	var height: UInt
	var contextInfo: RenderContextInfo
	
	var layers: [RenderLayer] = []
	
	func addLayer() -> RenderLayer {
		let layer = RenderLayer(width: width, height: height, contextInfo: contextInfo)
		layers.append(layer)
		return layer
	}
	
	init(width: UInt, height: UInt, contextInfo: RenderContextInfo) {
		self.width = width
		self.height = height
		self.contextInfo = contextInfo
	}
}

//
//  RenderTextureCell.swift
//  Blaise
//
//  Created by Ryan Joseph on 5/9/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Foundation
import OpenGL

class RenderTextureCell: MemoryUsage {
	private var pixels: PixelMatrix!
	
	var texture: GLTexture
	var dirty: Bool = false
	var textureID: GLuint { return texture.texture }
	var lastTextureID: GLuint = 0
	var defaultColor: RGBA8
	var gridPos: CellPos
	
	// pixel access
	
	public func getPixel<T: BinaryInteger> (_ x: T, _ y: T) -> RGBA8 {
		if pixels == nil {
			allocatePixelStore()
		}
		
		return pixels[UInt(x), UInt(y)]
	}
	
	public func setPixel<T: BinaryInteger> (_ x: T, _ y: T, color: RGBA8) {
		if pixels == nil {
			allocatePixelStore()
		}
		
		dirty = true
		pixels[UInt(x), UInt(y)] = color
	}
	
	public func fill (_ color: RGBA8, allocateIfNeeded: Bool) {
		if allocateIfNeeded && pixels == nil {
			allocatePixelStore()
		}
		if pixels != nil {
			pixels.fill(color)
			dirty = true
		} else {
			defaultColor = color
		}
	}
	
	// methods
	
	public func isLoaded() -> Bool {
		return textureID > 0
	}
	
	private func allocatePixelStore() {
		pixels = PixelMatrix(width: texture.width, height: texture.height, defaultValue: defaultColor)
//		print("allocate pixels at cell: \(pixels.count) @ \(texture.width)x\(texture.height)")
	}
	
	func calculateTotalMemoryUsage(bytes: inout UInt64) {
		if let pixels = pixels {
			bytes += UInt64(pixels.elementStride * pixels.count)
		}
	}
		
	@discardableResult func reload() -> Bool {
		if pixels == nil {
			allocatePixelStore()
		}
		
		// NOTE: we have to assign to var or get crashing in OpenGL
		// why is this??
		var data = pixels.table
		if texture.reload(&data) {
			lastTextureID = textureID
			return true
		} else {
			return false
		}
	}
	
	init(width: UInt, height: UInt, defaultColor: RGBA8) {
		self.defaultColor = defaultColor
		texture = GLTexture(width: width, height: height)
		gridPos = CellPos(-1, -1)
	}
	
}

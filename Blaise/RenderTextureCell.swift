//
//  RenderTextureCell.swift
//  Blaise
//
//  Created by Ryan Joseph on 5/9/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Foundation

class RenderTextureCell: MemoryUsage {
	var pixels: PixelMatrix
	var texture: GLTexture
	var dirty: Bool = false
	var textureID: GLuint { return texture.texture }
	var lastTextureID: GLuint = 0
	var pos: CellPos
	
	func isLoaded() -> Bool {
		return textureID > 0
	}
	
	func calculateTotalMemoryUsage(bytes: inout UInt64) {
		bytes += UInt64(pixels.elementStride * pixels.count)
	}
	
	func reload() {
		texture.reload(&pixels.table)
		lastTextureID = textureID
	}
	
	init(width: UInt, height: UInt, defaultColor: RGBA8) {
		pixels = PixelMatrix(width: width, height: height, defaultValue: defaultColor)
		texture = GLTexture(width: width, height: height)
		pos = CellPos(-1, -1)
	}
	
}

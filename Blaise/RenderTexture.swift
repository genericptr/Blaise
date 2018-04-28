//
//  Bitmap.swift
//  Blaise
//
//  Created by Ryan Joseph on 4/8/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Foundation
import OpenGL

typealias TextureCellMatrix = Matrix<GLuint>
var ActiveBoundTextures: [GLuint] = Array(repeating: 0, count: 8)

struct RenderTextureBuffer {
	var pixels: PixelMatrix!
	var dirty: Bool = false
	var textureID: GLuint = 0
}

class RenderTexture {
	
	// TODO: we have a matrix and an array of buffers?
//	var textures: TextureCellMatrix!
//	var buffers: [PixelMatrix] = []
	var textures: Matrix<RenderTextureBuffer>
	var cellSize: CellDim
	var gridSize: CellDim

	let imageFormat = GL_RGBA
	let imageType = GL_UNSIGNED_BYTE
	
	private var defaultColor: RGBA8 {
		return RGBA8.clearColor()
	}
	
	private func bufferAt(x: UInt, y: UInt) -> PixelMatrix {
		let cellIndex = x + (y * gridSize.w)
		return buffers[cellIndex.int]
	}
	
	func setPixel(x: UInt, y: UInt, source: PixelMatrix) {
		
		let cell = V2i(x.int, y.int) / V2i(cellSize.w.int, cellSize.h.int)
		let buffer = bufferAt(x: cell.x.uint, y: cell.y.uint)
		let bufferRel = V2i(x.int - (cell.x * cellSize.w.int), y.int - (cell.y * cellSize.h.int))
		
		buffer[bufferRel.x.uint, bufferRel.y.uint] = source[x, y]
	}
	
	func reloadCell(x: UInt, y: UInt, source: PixelMatrix)  {
		
		var cell = CellPos(x.int, y.int)
		
		let cellIndex: Int = cell.x + (cell.y * gridSize.w.int)
		let start = CellPos(cell.x * cellSize.w.int, cell.y * cellSize.h.int)
		let end = CellPos(Clamp(value: start.x + cellSize.w.int, min: 0, max: source.width.int),
						  Clamp(value: start.y + cellSize.h.int, min: 0, max: source.height.int))
		
		let buffer = buffers[cellIndex]
		let elemSize = source.elementStride
		let cellRows = Int(cellSize.w)

//		 for y in start.y..<end.y {
//		 	for x in start.x..<end.x {
//		 		let pixel = source[x.uint, y.uint]
//		 		if pixel.a > 0 {
//		 			print(pixel)
//		 		}
//		 	}
//		 }

		for y in start.y..<end.y {
			let bufferRel = CellPos(0, y - (cell.y * cellSize.h.int))
			let bufferRelIndex = buffer.indexOf(x: bufferRel.x.uint, y: bufferRel.y.uint)

			let sourceIndex = source.indexOf(x: start.x.uint, y: y.uint)

			let destOffset = Int32(elemSize * Int(bufferRelIndex))
			let srcOffset = Int32(elemSize * Int(sourceIndex))
			let byteCount = Int32(elemSize * cellRows)
			BlockMove(&buffer.table, destOffset, &source.table, srcOffset, byteCount)
		}
		
		reloadTexture(x: cell.x.uint, y: cell.y.uint, data: &buffer.table)

	}
	
	func reloadRegion(_ region: Box, source: PixelMatrix)  {
		var cellRegion = region / cellSize
		cellRegion = cellRegion.clamp(Box(0, 0, gridSize.width.int, gridSize.height.int))
		
		for x in cellRegion.min.x...cellRegion.max.x {
			for y in cellRegion.min.y...cellRegion.max.y {
				reloadCell(x: UInt(x), y: UInt(y), source: source)
			}
		}
	}
	
	
	func bindTexture(_ textureID: GLuint, _ textureUnit: Int) {
		if ActiveBoundTextures[textureUnit] != textureID {
			glActiveTexture(GLenum(GL_TEXTURE0));
			glBindTexture(GLenum(GL_TEXTURE_2D), textureID);
			ActiveBoundTextures[textureUnit] = textureID
		}
	}
	
	func reloadTexture(x: UInt, y: UInt, data: UnsafeRawPointer!) {
				
    // https://developer.apple.com/library/content/documentation/GraphicsImaging/Conceptual/OpenGL-MacProgGuide/opengl_texturedata/opengl_texturedata.html
    // The best format and data type combinations to use for texture data are:

    // GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV
    // GL_BGRA, GL_UNSIGNED_SHORT_1_5_5_5_REV)
    // GL_YCBCR_422_APPLE, GL_UNSIGNED_SHORT_8_8_REV_APPLE
    // The combination GL_RGBA and GL_UNSIGNED_BYTE needs to be swizzled by many cards when the data is loaded, so it's not recommended.
        
        
		var texture = textures[x, y]
		if texture == 0 {
			texture = loadTexture(width: cellSize.width, height: cellSize.height, data: data)
			textures.setValue(x: x, y: y, value: texture)
		} else {
			bindTexture(texture, 0)
			
			glTexSubImage2D(GLenum(GL_TEXTURE_2D), 0, 0, 0, GLsizei(cellSize.width), GLsizei(cellSize.height), GLenum(imageFormat), GLenum(imageType), data)
		}
	}

	func loadTexture(width: UInt, height: UInt, data: UnsafeRawPointer!) -> GLuint {
		var texture: GLuint = 0
		
		glGenTextures(1, &texture)
		if texture < 1 {
			print("render texture failed to allocate")
			exit(-1)
		} else {
			print("loaded texture \(texture)")
		}
		
		// TODO: we can use PBO is map the table buffer and when glTexSubImage2D is called
		// we pass null for last pointer and use the data from currently bound PBO instead
    // https://developer.apple.com/library/content/documentation/GraphicsImaging/Conceptual/OpenGL-MacProgGuide/opengl_texturedata/opengl_texturedata.html

		bindTexture(texture, 0)
		glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GLint(imageFormat), GLsizei(width), GLsizei(height), 0, GLenum(imageFormat), GLenum(imageType), data)
		
		glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_NEAREST)
		glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_NEAREST)
		glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
		glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
		
		
		return texture
	}
	
	init(width: UInt, height: UInt, cellDim: CellDim) {        
		cellSize = cellDim
        
		// round up grid size
		var gridW = width / cellSize.w
		if width % cellSize.w > 0 {
			gridW += 1
		}
		var gridH = height / cellSize.h
		if height % cellSize.h > 0 {
			gridH += 1
		}

		gridSize = CellDim(gridW, gridH)
		textures = TextureCellMatrix(width: gridSize.width, height: gridSize.height, defaultValue: 0)
		let cellCount = gridSize.width * gridSize.height
		
		for _ in 0..<cellCount {
			let buffer = PixelMatrix(width: cellSize.width, height: cellSize.height, defaultValue: defaultColor)
			buffers.append(buffer)
		}
	}
}

extension RenderTexture {
	
	func drawCell(x: UInt, y: UInt, textureUnit: Int, fillBackground: Bool = false) {
		
		if !textures.isValid(x, y) {
			return
		}
		
		let texture = textures[x, y]
		
		// ignore empty textures
		if texture == 0 {
			return
		}
		bindTexture(texture, textureUnit)
		
		glMatrixMode(GLenum(GL_MODELVIEW))
		glLoadIdentity()
		let scale: Float = 1.0
		let width: Float = cellSize.width.float * scale
		let height: Float = cellSize.height.float * scale
		glTranslatef(GLfloat(x.float * width), GLfloat(y.float * height), 0)
		
		// TODO: we need to fill background for eraser mode or alpha mode
		// glDisable(GLenum(GL_TEXTURE_2D))
		// let bgColor = RGBAf(1, 1, 1, 1)
		// glBegin(GLenum(GL_QUADS))
		// 		glColor4f(bgColor.r, bgColor.g, bgColor.b, bgColor.a)
		// 		glVertex2f(0.0, 0.0)

		// 		glColor4f(bgColor.r, bgColor.g, bgColor.b, bgColor.a)
		// 		glVertex2f(GLfloat(width), 0.0)

		// 		glColor4f(bgColor.r, bgColor.g, bgColor.b, bgColor.a)
		// 		glVertex2f(GLfloat(width), GLfloat(height))

		// 		glColor4f(bgColor.r, bgColor.g, bgColor.b, bgColor.a)
		// 		glVertex2f(0.0, GLfloat(height))
		// glEnd()
		
		glEnable(GLenum(GL_TEXTURE_2D))
		glBegin(GLenum(GL_QUADS))
			glTexCoord2f(0.0, 0.0)
			glVertex2f(0.0, 0.0)
		
			glTexCoord2f(1.0, 0.0)
			glVertex2f(GLfloat(width), 0.0)
		
			glTexCoord2f(1.0, 1.0)
			glVertex2f(GLfloat(width), GLfloat(height))
		
			glTexCoord2f(0.0, 1.0)
			glVertex2f(0.0, GLfloat(height))
		glEnd()
	}
	
}


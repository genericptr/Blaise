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

class RenderTexture {
	var textures: TextureCellMatrix!
	var cellSize: CellDim
	var gridSize: CellDim
	var buffers: [PixelMatrix] = []

	let imageFormat = GL_RGBA
	let imageType = GL_UNSIGNED_BYTE
	
	var defaultColor: RGBA8 {
		// return RGBA8.whiteColor()
		return RGBA8(0, 0, 0, 0)
	}
	
	func reloadRegion(_ region: Box, source: PixelMatrix)  {
		var cellRegion = region / cellSize
		cellRegion = cellRegion.clamp(Box(0, 0, gridSize.width.int, gridSize.height.int))
		
		for x in cellRegion.min.x...cellRegion.max.x {
			for y in cellRegion.min.y...cellRegion.max.y {
				reloadCell(x: UInt(x), y: UInt(y), translateToCellCoords: false, source: source)
			}
		}
	}
	
	// reload cell is matrix coords with source matrix which matches the size
	// of the texture
	func reloadCell(x: UInt, y: UInt, translateToCellCoords: Bool, source: PixelMatrix)  {
		
		var cell = CellPos(0, 0)
		
		if translateToCellCoords {
			cell.x = x.int / cellSize.w.int
			cell.y = y.int / cellSize.h.int
		} else {
			cell.x = x.int
			cell.y = y.int
		}
		let cellIndex: Int = cell.x + (cell.y * gridSize.w.int)
//        print("reload \(cellX),\(cellY)")
		
		let start = CellPos(cell.x * cellSize.w.int, cell.y * cellSize.h.int)
		
		let end = CellPos(Clamp(value: start.x + cellSize.w.int, min: 0, max: source.width.int),
						  Clamp(value: start.y + cellSize.h.int, min: 0, max: source.height.int))
		
		let buffer = buffers[cellIndex]
		let elemSize = source.elementStride
		let cellRows = Int(cellSize.w)

		// for y in start.y..<end.y {
		// 	for x in start.x..<end.x {
		// 		let pixel = source[x.uint, y.uint]
		// 		if pixel.a < 1 {
		// 			source.setValue(x: x.uint, y: y.uint, value: RGBA8(255, 0, 0, 255))
		// 		}
		// 	}
		// }

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
		
//        for y in startY..<endY {
//            for x in startX..<endX {
//                let pixel = source.getValue(x: x, y: y)
//                let bufferRelX = x - (cellX * cellSize.w)
//                let bufferRelY = y - (cellY * cellSize.h)
//                buffer.setValue(x: bufferRelX, y: bufferRelY, value: pixel)
//            }
//        }
//        reloadTexture(x: cellX, y: cellY, data: &buffer.table)

	}
	
	func bindTexture(_ textureID: GLuint, _ textureUnit: Int) {
		if ActiveBoundTextures[textureUnit] != textureID {
			glActiveTexture(GLenum(GL_TEXTURE0));
			glBindTexture(GLenum(GL_TEXTURE_2D), textureID);
			ActiveBoundTextures[textureUnit] = textureID
		}
	}
	
	func reloadTexture(x: UInt, y: UInt, data: UnsafeRawPointer!) {
		
		// Consider using format GL_BGRA and type GL_UNSIGNED_INT_8_8_8_8_REV for a
		// faster transfer; yes, it's more data but it will more closely match the
		// driver's internal representation and the driver will be more likely to do
		// a direct transfer to the GPU rather than having to do any internal format
		// conversions of it's own
		
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
		glDisable(GLenum(GL_TEXTURE_2D))
		let bgColor = RGBA<GLfloat>(1.0, 1.0, 1.0, 1.0)
		glBegin(GLenum(GL_QUADS))
			glColor4f(bgColor.r, bgColor.g, bgColor.b, bgColor.a)
			glVertex2f(0.0, 0.0)
		
			glColor4f(bgColor.r, bgColor.g, bgColor.b, bgColor.a)
			glVertex2f(GLfloat(width), 0.0)
		
			glColor4f(bgColor.r, bgColor.g, bgColor.b, bgColor.a)
			glVertex2f(GLfloat(width), GLfloat(height))
		
			glColor4f(bgColor.r, bgColor.g, bgColor.b, bgColor.a)
			glVertex2f(0.0, GLfloat(height))
		glEnd()
		
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


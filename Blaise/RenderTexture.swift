//
//  Bitmap.swift
//  Blaise
//
//  Created by Ryan Joseph on 4/8/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Foundation
import OpenGL

struct RenderTextureCellPoint {
	var pos: CellPos
	var cell: RenderTextureCell
}

class RenderTexture: MemoryUsage {
	
	// TODO: replace with JaggedArray (rows, variable columns)
	// when we access a column which is out of range either grow the entire column
	// to fit or use some other scheme to find it (hash table is the only way I guess)
	private var cells: Matrix<RenderTextureCell>
	var cellSize: CellDim
	var gridSize: CellDim

	
	func calculateTotalMemoryUsage(bytes: inout UInt64) {
		for cell in cells.table {
			cell.calculateTotalMemoryUsage(bytes: &bytes)
		}
	}
	
	private func getTextureCellAtCanvasPoint(_ x: UInt, _ y: UInt) -> RenderTextureCellPoint {
		let cell = CellPos(x.int, y.int) / CellPos(cellSize.w.int, cellSize.h.int)
		let textureCell = cells[cell.x.uint, cell.y.uint]
		let bufferRel = CellPos(x.int - (cell.x * cellSize.w.int), y.int - (cell.y * cellSize.h.int))
		
		return RenderTextureCellPoint(pos: bufferRel, cell: textureCell)
	}
	
	func getCellCount() -> Int {
		return cells.count
	}
	
	public func getPixel (_ x: UInt, _ y: UInt) -> RGBA8 {
		let pt = getTextureCellAtCanvasPoint(x, y)
		return pt.cell.getPixel(pt.pos.x, pt.pos.y)
	}
	
	public func setPixel(_ x: UInt, _ y: UInt, color: RGBA8) {
		let pt = getTextureCellAtCanvasPoint(x, y)
		pt.cell.setPixel(pt.pos.x, pt.pos.y, color: color)
	}
	
	public func fill (_ color: RGBA8) {
		for cell in cells.table {
			cell.fill(color, allocateIfNeeded: false)
		}
	}
	
	/*
	private func copyCellPixels(x: UInt, y: UInt, source: PixelMatrix)  {
		
		let cell = CellPos(x.int, y.int)
		let start = CellPos(cell.x * cellSize.w.int, cell.y * cellSize.h.int)
		let end = CellPos(Clamp(value: start.x + cellSize.w.int, min: 0, max: source.width.int),
						  Clamp(value: start.y + cellSize.h.int, min: 0, max: source.height.int))
		
		let textureCell = cells[cell.x.uint, cell.y.uint]
		let buffer = textureCell.pixels
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
			let bufferRelIndex = buffer.indexOf(bufferRel.x, bufferRel.y)

			let sourceIndex = source.indexOf(start.x, y)

			let destOffset = Int32(elemSize * Int(bufferRelIndex))
			let srcOffset = Int32(elemSize * Int(sourceIndex))
			let byteCount = Int32(elemSize * cellRows)
			BlockMove(&buffer.table, destOffset, &source.table, srcOffset, byteCount)
		}
		
		textureCell.dirty = true
//		reloadTexture(textureCell)
	}
	*/
	
	public func convertRectToCells(_ from: Box) -> Box {
		let toBox = from / cellSize
		return toBox.clamp(Box(0, 0, gridSize.width - 1, gridSize.height - 1))
	}
	
	public func reloadDirtyCells(_ region: Box)  {
		let cellRegion = convertRectToCells(region)
		
//		print("[")
//		print("reload dirty cells \(cellRegion)")

		var dirtyCells = [RenderTextureCell]()
		for x in cellRegion.min.x...cellRegion.max.x {
			for y in cellRegion.min.y...cellRegion.max.y {
				let cell = cells[x, y]
				
				cell.gridPos = CellPos(x, y)
				
				// always lock the cell because it will
				// be drawn next pass
				TextureManager.lockTexture(cell.textureID)

				// if the cell is not dirty but unloaded
				// then we need to reload again now
				if cell.dirty || !cell.isLoaded() {
					dirtyCells.append(cell)
				}
			}
		}
		
		// TODO: we are drawing/reloading split into 2 parts?
		// if we don't have enough textures per reload until next
		// draw then we need to flush the remaining textures
		// draw then reload more
		
		for cell in dirtyCells {
			let savedTexID = cell.textureID
			
			
			// TODO: if cell returns false we failed to allocate a texture
			// so force flush what we have now
			// next question is what textures do we unlock and unload?
			// 1) always unlock the last texture. if we do this then
			// all the preceeding textures will be unloaded and need
			// to be restored next pass
			// 2) as it is now we don't really need more than 1 texture
			// because we never redraw a cell unless it's been modified
			// by a brush. this changes if we do layers because it's possible
			// a top layer will reload pixels and then need to redraw cells under it
			// which could still keep their previous texture
			if !cell.reload() {
				TextureManager.forceUnloadTexture(for: cell.texture.info)
				cell.reload()
			}
			
			drawCell(x: UInt(cell.gridPos.x), y: UInt(cell.gridPos.y), textureUnit: 0)
			if cell.textureID != savedTexID {
				TextureManager.lockTexture(cell.textureID)
			}
			cell.dirty = false
		}
		
		TextureManager.unlockAllTextures()
//		print("]")
	}

	static func gridSizeForPixels(_ width: UInt, _ height: UInt, _ cellWidth: UInt, _ cellHeight: UInt) -> CellDim {
		var gridW = width / cellWidth
		if width % cellWidth > 0 {
			gridW += 1
		}
		var gridH = height / cellHeight
		if height % cellHeight > 0 {
			gridH += 1
		}
		
		return CellDim(gridW, gridH)
	}
	
	init(width: UInt, height: UInt, cellDim: CellDim, defaultColor: RGBA8) {
		cellSize = cellDim
    gridSize = RenderTexture.gridSizeForPixels(width, height, cellSize.w, cellSize.h)
		
		print("render texture cellSize: \(cellSize)")
		print("render texture gridSize: \(gridSize)")

		cells = Matrix<RenderTextureCell>(width: gridSize.width, height: gridSize.height)
		
		// TODO: testing resizeing Matrix
//		cells.resize(x: 3, y: 3) { () -> RenderTextureCell in
//			return RenderTextureCell(width: cellSize.width, height: cellSize.height, defaultColor: defaultColor)
//		}x

		// populate the cells matrix with render texture cells
		for _ in 0..<cells.count {
			let cell =  RenderTextureCell(width: cellSize.width, height: cellSize.height, defaultColor: defaultColor)
			cells.table.append(cell)
		}
		
	}
}

// MARK: - OpenGL RenderTexture extensions

extension RenderTexture {
	
	func clearCell(_ x: UInt, _ y: UInt) {
		
		glMatrixMode(GLenum(GL_MODELVIEW))
		glLoadIdentity()
		
		glTranslatef(GLfloat(x * cellSize.width), GLfloat(y * cellSize.height), 0)
		
		 glDisable(GLenum(GL_TEXTURE_2D))
		 let color = RGBAf(1, 1, 1, 1)
		 glBegin(GLenum(GL_QUADS))
		 		glColor4f(color.r, color.g, color.b, color.a)
		 		glVertex2f(0.0, 0.0)
		
		 		glColor4f(color.r, color.g, color.b, color.a)
		 		glVertex2f(GLfloat(cellSize.width), 0.0)
		
		 		glColor4f(color.r, color.g, color.b, color.a)
		 		glVertex2f(GLfloat(cellSize.width), GLfloat(cellSize.height))
		
		 		glColor4f(color.r, color.g, color.b, color.a)
		 		glVertex2f(0.0, GLfloat(cellSize.height))
		 glEnd()
	}
	
	func drawCell(x: UInt, y: UInt, textureUnit: Int, fillBackground: Bool = false) {
		
		guard cells.isValid(x, y) else { return }
		
		let cell = cells[x, y]
		let texture = cell.texture
		
		// ignore unloaded textures
		if !cell.isLoaded() {
			if cell.lastTextureID > 0 {
				print("**** cell \(cell.lastTextureID) is unloaded \(V2(x, y))")
				clearCell(x, y)
			}
			return
		}
		
//		print("draw cell \(V2(x, y))")
		texture.bind(textureUnit)
		
		glMatrixMode(GLenum(GL_MODELVIEW))
		glLoadIdentity()
		
		let width: Float = cellSize.width.float
		let height: Float = cellSize.height.float
		glTranslatef(GLfloat(x.float * width), GLfloat(y.float * height), 0)
		
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


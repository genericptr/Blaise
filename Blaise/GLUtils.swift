//
//  GLUtils.swift
//  Blaise
//
//  Created by Ryan Joseph on 4/16/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Foundation
import OpenGL

var ActiveBoundTextures: [GLuint] = Array(repeating: 0, count: 8)

let INVALID_TEXTURE_ID: GLuint = 0

struct GLVertex2f {
	static let size = MemoryLayout<GLfloat>.stride * 2
	var x, y: GLfloat
	
	init(_ x: GLfloat, _ y: GLfloat) {
		self.x = x
		self.y = y
	}
}

struct GLTextureInfo {
	var id: GLuint
	var width: UInt
	var height: UInt
	var imageFormat: GLenum
	var imageType: GLenum
	var textureSizeInBytes: UInt {
		var pixelBytes = 0
		if imageFormat == GL_RGBA && imageType == GL_UNSIGNED_BYTE {
			pixelBytes = 1 * 4
		} else {
			fatalError("image format/type can't calculate byte count")
		}
		return UInt(width * height * pixelBytes)
	}

	func isReusable(_ source: GLTextureInfo) -> Bool {
		return (source.width == self.width) && (source.height == self.height) && (source.imageFormat == self.imageFormat) && (source.imageType == self.imageType)
	}
	
}

class GLTextureManager {
	
	var maximumTextureMemory: UInt64
	var usedTextureMemory: UInt64 = 0
	var allocatedTextureMemory: UInt64 = 0

	var slots: [GLTexture] = []
	var freedSlots: [GLTextureInfo] = []
	var lockedTextures = Set<GLuint>()
		
	public func lockTexture(_ id: GLuint) {
		if id > INVALID_TEXTURE_ID {
//			print("lock texture \(id)")
			lockedTextures.insert(id)
		}
	}
	
	public func unlockTexture(_ id: GLuint) {
		lockedTextures.remove(id)
	}

	public func unlockAllTextures() {
//		print("unlock all textures \(lockedTextures)")
		lockedTextures.removeAll(keepingCapacity: true)
	}

	public func forceUnloadTexture(for source: GLTextureInfo) {
		lockedTextures.removeFirst()
		purgeTexture(for: source)
	}
	
	private func unloadTexture(_ texture: GLTexture) -> Bool {
		if !lockedTextures.contains(texture.texture) {
			freedSlots.append(texture.info)
			texture.unload()
			usedTextureMemory -= UInt64(texture.info.textureSizeInBytes)
			return true
		} else {
			return false
		}
	}
	
	@discardableResult private func purgeTexture(for source: GLTextureInfo) -> Bool {
		print("purge texture")
		var index = slots.count - 1
		while index >= 0 {
			let texture = slots[index]
			if texture.info.isReusable(source) && unloadTexture(texture) {
				slots.remove(at: index)
				return true
			}
			index -= 1
		}
		return false
	}
	
	private func findFreeTexture(_ source: GLTextureInfo) -> GLuint {
		if freedSlots.count > 0 {
			
			var index = freedSlots.count - 1
			while index >= 0 {
				let info = freedSlots[index]
				if info.isReusable(source) {
					freedSlots.remove(at: index)
					print("reuse texture \(info.id)")
					return info.id
				}
				index -= 1
			}
			
			// none of the free blocks fit
			// delete a block to make room for glGenTextures
			if var info = freedSlots.popLast() {
				print("delete texture \(info.id)")
				glDeleteTextures(1, &info.id)
				glFatal("glDeleteTextures error")
				allocatedTextureMemory -= UInt64(info.textureSizeInBytes)
				print("allocatedTextureMemory: \(allocatedTextureMemory / 1024)k")
			}

			return 0
		} else {
			return 0
		}
	}
	
	public func getTexture(_ source: GLTexture) -> GLuint {
		
		if usedTextureMemory > maximumTextureMemory {
			if !purgeTexture(for: source.info) {
				print("failed to unload enough textures")
				return INVALID_TEXTURE_ID
			}
		}
		
		var texture: GLuint = findFreeTexture(source.info)
		
		// nothing found, generate new texture
		if texture == INVALID_TEXTURE_ID {
			glGenTextures(1, &texture)
			glFatal("glGenTextures error")
			print("loaded texture #\(texture)")
			allocatedTextureMemory += UInt64(source.info.textureSizeInBytes)
			print("allocatedTextureMemory: \(allocatedTextureMemory / 1024)k")
		}
		
		if texture > INVALID_TEXTURE_ID {
			source.texture = texture
			usedTextureMemory += UInt64(source.info.textureSizeInBytes)
			slots.append(source)
		} else {
			// TODO: what happened here?
		}

		return texture
	}
	
	init(_ maximumTextureMemory: UInt64) {
		self.maximumTextureMemory = maximumTextureMemory
	}
	
}

var TextureManager = GLTextureManager(4 * 1024 * 1024)

class GLTexture {
	var texture: GLuint {
		didSet {
			info.id = texture
		}
	}
	var width: UInt = 0
	var height: UInt = 0
	var info: GLTextureInfo
	
	func unload() {
		
		// TODO: bound texture units is broken now
		// but we if we fix that we need to keep
		// the currently bound texture unit
		// and clear it if the texture is unloaded
		
		print("unloaded texture #\(texture)")
		texture = INVALID_TEXTURE_ID
	}
	
	public func reload(_ data: UnsafeRawPointer!) -> Bool {
		
		// https://developer.apple.com/library/content/documentation/GraphicsImaging/Conceptual/OpenGL-MacProgGuide/opengl_texturedata/opengl_texturedata.html
		// The best format and data type combinations to use for texture data are:
		
		// GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV
		// GL_BGRA, GL_UNSIGNED_SHORT_1_5_5_5_REV)
		// GL_YCBCR_422_APPLE, GL_UNSIGNED_SHORT_8_8_REV_APPLE
		// The combination GL_RGBA and GL_UNSIGNED_BYTE needs to be swizzled by many cards when the data is loaded, so it's not recommended.

		if texture == INVALID_TEXTURE_ID {
			return load(data)
		} else {
			bind(0)
			glTexSubImage2D(GLenum(GL_TEXTURE_2D), 0, 0, 0, GLsizei(width), GLsizei(height), info.imageFormat, info.imageType, data)
			return true
		}
		
	}
	
	private func load(_ data: UnsafeRawPointer!) -> Bool {
		
		texture = TextureManager.getTexture(self)
		
		if texture < 1 {
			return false
		}
		
		// TODO: we can use PBO is map the table buffer and when glTexSubImage2D is called
		// we pass null for last pointer and use the data from currently bound PBO instead
		// https://developer.apple.com/library/content/documentation/GraphicsImaging/Conceptual/OpenGL-MacProgGuide/opengl_texturedata/opengl_texturedata.html
				
		bind(0)
		glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GLint(info.imageFormat), GLsizei(width), GLsizei(height), 0, info.imageFormat, info.imageType, data)
				
		return true
	}
	
	// TODO: broken for now, always use texture unit 0 (GL_TEXTURE0)
	func bind(_ textureUnit: Int) {
		if ActiveBoundTextures[textureUnit] != texture {
			glActiveTexture(GLenum(GL_TEXTURE0));
			
			glBindTexture(GLenum(GL_TEXTURE_2D), texture);
			glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_NEAREST)
			glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_NEAREST)
			glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
			glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)

			glFatal("glBindTexture")
			ActiveBoundTextures[textureUnit] = texture
		}
	}

	init(width: UInt, height: UInt) {
		self.width = width
		self.height = height

		texture = INVALID_TEXTURE_ID
		info = GLTextureInfo(id: texture, width: width, height: height, imageFormat: GLenum(GL_RGBA), imageType: GLenum(GL_UNSIGNED_BYTE))
	}
	
}

func PrintOpenGLInfo() {
	let versionString = glGetString(GL_VERSION)
	print("OpenGL Version: \(versionString)")
	
	var maximumTexureSize: GLint = 0
	var maximumTextureUnits: GLint = 0
	glGetIntegerv(GLenum(GL_MAX_TEXTURE_SIZE), &maximumTexureSize)
	glGetIntegerv(GLenum(GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS), &maximumTextureUnits)
	
	print("GL_MAX_TEXTURE_SIZE: \(maximumTexureSize)")
	print("GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS: \(maximumTextureUnits)")
}

func glFatal(_ message: String = "") {
	let error = glGetError()
	if error != GL_NO_ERROR {
		if message == "" {
			fatalError("glGetError: \(error)")
		} else {
			fatalError("message: \(error)")
		}
	}
}

func glGetString(_ name: Int32) -> String {
	let GL_cstring = glGetString(GLenum(name))!
	return String(cString: GL_cstring)
}

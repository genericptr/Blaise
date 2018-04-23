//
//  GLUtils.swift
//  Blaise
//
//  Created by Ryan Joseph on 4/16/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Foundation
import OpenGL

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

func glGetString(_ name: Int32) -> String {
	let GL_cstring = glGetString(GLenum(name)) as UnsafePointer<UInt8>
	return String(cString: GL_cstring)
}

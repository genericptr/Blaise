//
//  AppDelegate.swift
//  Blaise
//
//  Created by Ryan Joseph on 4/8/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

/*
	notes about architecture:

	CanvasView -> GLCanvasView -> NSView

	- CanvasView manages RenderContext
	- RenderContext manages RenderLayers
	- RenderLayers manages RenderTexture
	- RenderTextures manages RenderTextureCell
	- RenderTextureCell manages PixelMatrix and GLTexture
		
*/


import Cocoa

struct DEBUG_INFO {
	var loadedTextureCells: Int
	
	init() {
		loadedTextureCells = 0
	}
}

var GLOBAL_DEBUG = DEBUG_INFO()

fileprivate struct MyData {
	var x: Int
	var y: Int
}

func sizeof<T>(_ type: T.Type) -> Int {
	return MemoryLayout<T.Type>.size
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	func applicationWillFinishLaunching(_ notification: Notification) {
	}
	
}


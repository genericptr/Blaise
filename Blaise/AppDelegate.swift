//
//  AppDelegate.swift
//  Blaise
//
//  Created by Ryan Joseph on 4/8/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Cocoa

/*

- Document
	- OpenGLView
		- RenderContext
		- RenderTexture
	- Brushes

*/

func DoThis<T:Numeric>(_ i: T) {
	
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	func applicationWillFinishLaunching(_ notification: Notification) {
		
//		let a: UInt8 = 200
//		let b: UInt8 = 200
//		let c = a * 0.5
//		let r: Float = 8.0
//		let a: UInt = 200
//		let b: Int = 200
//		let c = a + b
//		let d = a * 0.5
//		let e = (r * 2) + 1
//		let f = Float(8) + b
//		let g = UInt8(255) + 0.5

//		DoThis(10);
//		exit(1)
		
		let i: UInt = 10
		DoThis(i)
	}
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}
}


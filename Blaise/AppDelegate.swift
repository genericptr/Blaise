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

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application

		/*
			TODO:

			- color picker
			- brush size
			- anti alias
			- tablet pressure
			- save/restore in native format (store brush in prefs or make global?)
			- resize window/scrolling
			- limit undo stack to byte size

			- new document window (choose size)

		*/

		//        TestMemmove()
		//        exit(1)

		//        TestStructCopy()
		//        exit(1)
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}
}


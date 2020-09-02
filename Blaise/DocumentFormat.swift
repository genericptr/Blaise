//
//  DocumentFormat.swift
//  Blaise
//
//  Created by Ryan Joseph on 5/25/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Foundation

protocol MemorySizeof {
	func sizeof() -> UInt32
}

struct DocumentHeader: MemorySizeof {
	var width: UInt32
	var height: UInt32
	var layerCount: UInt32
	var cellSize: UInt16
	
	func sizeof() -> UInt32 {
		return UInt32(MemoryLayout<DocumentHeader>.size)
	}
	
}

struct RenderLayerHeader: MemorySizeof {
	var hidden: UInt8
	var locked: UInt8
	var nameLength: UInt16
//	var nameString: [UInt8](255)
	
	func sizeof() -> UInt32 {
		return UInt32(MemoryLayout<RenderLayerHeader>.size) + UInt32(nameLength * 1)
	}
}

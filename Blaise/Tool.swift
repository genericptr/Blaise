//
//  Tool.swift
//  Blaise
//
//  Created by Ryan Joseph on 9/2/20.
//  Copyright © 2020 The Alchemist Guild. All rights reserved.
//

import Foundation

class Tool {
	weak var context: RenderContext!
	
	func begin() {}
	func end() {}
	func apply(location: V2) { Fatal("Tool does nothing") }
	func apply(from: V2, to: V2) { Fatal("Tool does nothing") }
}

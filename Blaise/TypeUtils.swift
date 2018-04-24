//
//  TypeUtils.swift
//  Blaise
//
//  Created by Ryan Joseph on 4/19/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Foundation

extension Float {
	var int: Int {
		return Int(self)
	}
	var uint: UInt {
		return UInt(self)
	}
	var string: String {
		return String(self)
	}
}

extension UInt {
	var int: Int {
		return Int(self)
	}
	var float: Float {
		return Float(self)
	}
	var double: Double {
		return Double(self)
	}

	var string: String {
		return String(self)
	}
}

extension Int {
	var uint: UInt {
		return UInt(self)
	}
	var float: Float {
		return Float(self)
	}
	var string: String {
		return String(self)
	}
}

extension NSObject {
    func show() {
        Swift.print(self)
    }
}

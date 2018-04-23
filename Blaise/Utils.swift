//
//  Utils.swift
//  Blaise
//
//  Created by Ryan Joseph on 4/12/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Foundation

func Clamp(value: Int, min: Int, max: Int) -> Int {
	return value < min ? min: value > max ? max: value
}

func Magnitude (_ p: CGPoint) -> Float {
	return Float(sqrt(pow(p.x, 2) + pow(p.y, 2)))
}

func Distance (_ fromPoint: CGPoint, _ toPoint: CGPoint) -> Float {
	return Magnitude(CGPoint(x: fromPoint.x - toPoint.x, y: fromPoint.y - toPoint.y))
}

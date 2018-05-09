//
//  Utils.swift
//  Blaise
//
//  Created by Ryan Joseph on 4/12/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Foundation

func Clamp<T:Comparable>(value: T, min: T, max: T) -> T {
	return value < min ? min: value > max ? max: value
}

/*
func Clamp(value: UInt8, min: UInt8, max: UInt8) -> UInt8 {
	return value < min ? min: value > max ? max: value
}

func Clamp(value: Int, min: Int, max: Int) -> Int {
	return value < min ? min: value > max ? max: value
}

func Clamp(value: Float, min: Float, max: Float) -> Float {
	return value < min ? min: value > max ? max: value
}

func Clamp(value: Double, min: Double, max: Double) -> Double {
	return value < min ? min: value > max ? max: value
}
*/

func Lerp (t: Float, a: Float, b: Float) -> Float {
	return (a * (1 - t)) + (b * t)
}

func Map(percent: Float, min: Float, max: Float) -> Float {
	return min + ((max - min) * percent)
}

func Map(value: Float, min: Float, max: Float) -> Float {
	return (max - min) / value
}

func Magnitude (_ x: Float, _ y: Float) -> Float {
	return Float(sqrt(pow(x, 2) + pow(y, 2)))
}

func Fatal(_ message: String = "Fatal") {
	print(message)
	exit(-1)
}

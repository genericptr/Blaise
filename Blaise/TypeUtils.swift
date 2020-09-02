//
//  TypeUtils.swift
//  Blaise
//
//  Created by Ryan Joseph on 4/19/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Foundation

/*

Arithmetic on integers (signed or unsigned) & floats casts up to Float
Arithmetic on signed integers & unsigned integers (of any size) casts up to Int
Arithmetic on unsigned integers & unsigned integers (of any size) casts up to UInt

Float + Int = Float
Float + UInt = Float

UInt + Int = Int
UInt + UInt = UInt
UInt8 + UInt = UInt
UInt8 + Int = Int

*/

protocol FloatingPointArithmetic {
	var toFloat: Float { get }
}

protocol IntegerArithmetic: FloatingPointArithmetic {
	var toSigned: Int { get }
	var toUnsigned: UInt { get }
}

protocol SignedIntegerArithmetic: IntegerArithmetic {}
protocol UnsignedIntegerArithmetic: IntegerArithmetic {}

func + <T: SignedIntegerArithmetic, U: UnsignedIntegerArithmetic> (lhs: T, rhs: U) -> Int { return lhs.toSigned + rhs.toSigned }
func + <T: UnsignedIntegerArithmetic, U: UnsignedIntegerArithmetic> (lhs: T, rhs: U) -> UInt { return lhs.toUnsigned + rhs.toUnsigned }
func + <T: UnsignedIntegerArithmetic, U: SignedIntegerArithmetic> (lhs: T, rhs: U) -> Int { return lhs.toSigned + rhs.toSigned }

func - <T: SignedIntegerArithmetic, U: UnsignedIntegerArithmetic> (lhs: T, rhs: U) -> Int { return lhs.toSigned - rhs.toSigned }
func - <T: UnsignedIntegerArithmetic, U: UnsignedIntegerArithmetic> (lhs: T, rhs: U) -> UInt { return lhs.toUnsigned - rhs.toUnsigned }
func - <T: UnsignedIntegerArithmetic, U: SignedIntegerArithmetic> (lhs: T, rhs: U) -> Int { return lhs.toSigned - rhs.toSigned }

func * <T: SignedIntegerArithmetic, U: UnsignedIntegerArithmetic> (lhs: T, rhs: U) -> Int { return lhs.toSigned * rhs.toSigned }
func * <T: UnsignedIntegerArithmetic, U: UnsignedIntegerArithmetic> (lhs: T, rhs: U) -> UInt { return lhs.toUnsigned * rhs.toUnsigned }
func * <T: UnsignedIntegerArithmetic, U: SignedIntegerArithmetic> (lhs: T, rhs: U) -> Int { return lhs.toSigned * rhs.toSigned }

func / <T: SignedIntegerArithmetic, U: UnsignedIntegerArithmetic> (lhs: T, rhs: U) -> Int { return lhs.toSigned / rhs.toSigned }
func / <T: UnsignedIntegerArithmetic, U: UnsignedIntegerArithmetic> (lhs: T, rhs: U) -> UInt { return lhs.toUnsigned / rhs.toUnsigned }
func / <T: UnsignedIntegerArithmetic, U: SignedIntegerArithmetic> (lhs: T, rhs: U) -> Int { return lhs.toSigned / rhs.toSigned }

func + <T: FloatingPointArithmetic, U: IntegerArithmetic> (lhs: T, rhs: U) -> Float { return lhs.toFloat + rhs.toFloat }
func - <T: FloatingPointArithmetic, U: IntegerArithmetic> (lhs: T, rhs: U) -> Float { return lhs.toFloat - rhs.toFloat }
func * <T: FloatingPointArithmetic, U: IntegerArithmetic> (lhs: T, rhs: U) -> Float { return lhs.toFloat * rhs.toFloat }
func / <T: FloatingPointArithmetic, U: IntegerArithmetic> (lhs: T, rhs: U) -> Float { return lhs.toFloat / rhs.toFloat }

func + <T: FloatingPointArithmetic> (lhs: T, rhs: Float) -> Float { return lhs.toFloat + rhs }
func - <T: FloatingPointArithmetic> (lhs: T, rhs: Float) -> Float { return lhs.toFloat - rhs }
func * <T: FloatingPointArithmetic> (lhs: T, rhs: Float) -> Float { return lhs.toFloat * rhs }
func / <T: FloatingPointArithmetic> (lhs: T, rhs: Float) -> Float { return lhs.toFloat / rhs }

// TOOD: cast up to 64 bit integers
//func += <T: UnsignedIntegerArithmetic> (left: inout UInt64, right: T) { left = left + right.toUnsigned64 }

// MARK: Supported Types

extension Float: FloatingPointArithmetic {
	var toFloat: Float { return self }
}

extension UInt: FloatingPointArithmetic, UnsignedIntegerArithmetic {
	var toSigned: Int { return Int(self) }
	var toUnsigned: UInt { return self }
	var toFloat: Float { return Float(self) }
}

extension UInt8: FloatingPointArithmetic, UnsignedIntegerArithmetic {
	var toSigned: Int { return Int(self) }
	var toUnsigned: UInt { return UInt(self) }
	var toFloat: Float { return Float(self) }
}

extension UInt32: FloatingPointArithmetic, UnsignedIntegerArithmetic {
	var toSigned: Int { return Int(self) }
	var toUnsigned: UInt { return UInt(self) }
	var toFloat: Float { return Float(self) }
}

extension UInt16: FloatingPointArithmetic, UnsignedIntegerArithmetic {
	var toSigned: Int { return Int(self) }
	var toUnsigned: UInt { return UInt(self) }
	var toFloat: Float { return Float(self) }
}

extension UInt64: FloatingPointArithmetic, UnsignedIntegerArithmetic {
	var toSigned: Int { return Int(self) }
	var toUnsigned: UInt { return UInt(self) }
	var toFloat: Float { return Float(self) }
}

extension Int: FloatingPointArithmetic, SignedIntegerArithmetic {
	var toSigned: Int { return self }
	var toUnsigned: UInt { return UInt(self) }
	var toFloat: Float { return Float(self) }
}

// MARK: Type casts

extension Float {
	var int: Int { return Int(self) }
	var uint: UInt { return UInt(self) }
	var string: String { return String(self) }
}

extension UInt {
	var int: Int { return Int(self) }
	var float: Float { return Float(self) }
	var double: Double { return Double(self) }
	var string: String { return String(self) }
}

extension UInt32 {
	var int: Int { return Int(self) }
	var uint: UInt { return UInt(self) }
	var float: Float { return Float(self) }
	var double: Double { return Double(self) }
	var string: String { return String(self) }
}

extension UInt16 {
	var int: Int { return Int(self) }
	var uint: UInt { return UInt(self) }
	var float: Float { return Float(self) }
	var double: Double { return Double(self) }
	var string: String { return String(self) }
}

extension UInt8 {
	var int: Int { return Int(self) }
	var uint: UInt { return UInt(self) }
	var float: Float { return Float(self) }
	var double: Double { return Double(self) }
	var string: String { return String(self) }
}

extension Int {
	var uint: UInt { return UInt(self) }
	var float: Float { return Float(self) }
	var string: String { return String(self) }
}

// MARK: CoreGraphics

extension CGFloat: FloatingPointArithmetic, IntegerArithmetic {
	var toFloat: Float { return Float(self) }
	var toUnsigned: UInt { return UInt(self) }
	var toSigned: Int { return Int(self) }
}

// MARK: Cocoa

extension NSObject {
    func show() {
        Swift.print(self)
    }
}

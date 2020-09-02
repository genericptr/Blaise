//
//  Tests.swift
//  Blaise
//
//  Created by Ryan Joseph on 4/18/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Foundation

func TestStructForLoop() {
	let r = 10000
	let a = Array(repeating: RGBA8.blackColor, count: 1000000)
	
	var startTime = CFAbsoluteTimeGetCurrent()
	for _ in 0..<r*r {
		for i in 0..<a.count {
			var c = a[i]
			c.a = 0
		}
	}
	var endTime = CFAbsoluteTimeGetCurrent()
	print("index:  \(endTime - startTime)")
	
	startTime = CFAbsoluteTimeGetCurrent()
	for _ in 0..<r*r {
		for p in a {
			var c = p
			c.a = 0
		}
	}
	endTime = CFAbsoluteTimeGetCurrent()
	print("copy iterator: \(endTime - startTime)")
}

func TestMemmove() {
	var src: [UInt32] = Array(repeating: 1, count: 1000)
	var dest: [UInt32] = Array(repeating: 0, count: 1000)
	
	let elemSize = MemoryLayout<UInt32>.stride
	let testCycles = 100000
	let rows = 500
	var startTime: CFAbsoluteTime = 0
	var endTime: CFAbsoluteTime = 0
	
	// BlockMove (from c)
	startTime = CFAbsoluteTimeGetCurrent()
	for _ in 0..<testCycles {
		BlockMove(&dest, Int32(elemSize), &src, 0, Int32(elemSize * rows))
	}
	endTime = CFAbsoluteTimeGetCurrent()
	print("BlockMove:  \(endTime - startTime)")
	
	// replaceSubrange
	startTime = CFAbsoluteTimeGetCurrent()
	for _ in 0..<testCycles {
		dest.replaceSubrange(1...1+rows, with: src[0...rows])
	}
	endTime = CFAbsoluteTimeGetCurrent()
	print("replaceSubrange:  \(endTime - startTime)")
	
	// memmove
	startTime = CFAbsoluteTimeGetCurrent()
	for _ in 0..<testCycles {
		dest.withUnsafeMutableBytes { destBytes in
			src.withUnsafeMutableBytes { srcBytes in
				let destOffset = destBytes.baseAddress! + elemSize
				let srcOffset = srcBytes.baseAddress! + 0
				memmove(destOffset, srcOffset, elemSize * rows)
			}
		}
	}
	endTime = CFAbsoluteTimeGetCurrent()
	print("memmove:  \(endTime - startTime)")
}

fileprivate struct MyData {
	var v: [UInt8] = Array(repeating: 0, count: 64)
}

func TestStructCopy() {
	let w = 1000
	let h = 1000
	var dest: [MyData] = Array(repeating: MyData(), count: w * h)
	let src = MyData()
	var index = 0
	
	let startTime = CFAbsoluteTimeGetCurrent()
	for x in 0..<w {
		for y in 0..<h {
			index = x + (y * w)
			dest[index] = src
		}
	}
	let endTime = CFAbsoluteTimeGetCurrent()
	print("finished:  \(endTime - startTime)")
}

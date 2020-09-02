//
//  RenderImageIO.swift
//  Blaise
//
//  Created by Ryan Joseph on 9/2/20.
//  Copyright © 2020 The Alchemist Guild. All rights reserved.
//

import Foundation
import AppKit

import CoreGraphics

extension RenderContext {
	
	func getBounds() -> CGRect {
		return CGRect(0, 0, CGFloat(width), CGFloat(height))
	}
	
	public func encodePrivateFormat() -> Data? {
		/*
			document properties (size, brushes)
			layers
				bitmaps
		*/
		
		var documentHeader = DocumentHeader(width: 300, height: 300, layerCount: 1, cellSize: 64)
		var renderLayerHeader = RenderLayerHeader(hidden: 0, locked: 0, nameLength: 20)

		var documentByteCount: UInt32 = 0
		
//		let cellCount = RenderTexture.gridSizeForPixels(UInt(documentHeader.width), UInt(documentHeader.height), UInt(documentHeader.cellSize), UInt(documentHeader.cellSize)).volume()
//		let layerCount: Int = 1
		
		let pixelsPerCell: Int = Int(documentHeader.cellSize * documentHeader.cellSize)
		let cellsPerLayer = UInt32(currentLayer.texture.getCellCount())
		let bytesPerPixel = UInt32(MemoryLayout<RGBA8>.size)
		let bytesPerCell = UInt32(bytesPerPixel * pixelsPerCell)
		
		documentByteCount += documentHeader.sizeof()
		documentByteCount += (renderLayerHeader.sizeof() + (bytesPerCell * cellsPerLayer)) * (documentHeader.layerCount)
		
		print("documentHeaderSize \(documentHeader.sizeof())")
		print("documentByteCount \(documentByteCount / 1024)k")
		
		// https://stackoverflow.com/questions/28916535/swift-structs-to-nsdata-and-back?noredirect=1&lq=1
		// https://developer.apple.com/documentation/foundation/data
		// https://stackoverflow.com/questions/37922333/how-to-append-int-to-the-new-data-struct-swift-3
		
//		var data = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(documentHeader.sizeof()))
//		data += documentHeader
		
//		var data = Data()
//		let buffer = UnsafeBufferPointer(start: &documentHeader, count: Int(documentHeader.sizeof()))
//		data.append(buffer)
//		print("data byte count: \(data.count)")

		var storage = MemoryBuffer(capacity: Int(documentByteCount))
		
		storage.append(value: &documentHeader, count: 1)
//		storage.append(record: documentHeader)

		print("storage byte count: \(storage.data.count)")

//		var header: DocumentHeader?
//		let buffer = UnsafeMutableBufferPointer(start: &header, count: 1)
////		print(buffer)
//		storage.data.copyBytes(to: buffer)

		var header_document: DocumentHeader!
		var header_layer: RenderLayerHeader!
		var tempBuffer: NSData
		if let buffer = NSMutableData(capacity: 16) {
			
			tempBuffer = NSData(bytes: &documentHeader, length: Int(documentHeader.sizeof()))
			buffer.append(tempBuffer as Data)
			
			tempBuffer = NSData(bytes: &renderLayerHeader, length: Int(renderLayerHeader.sizeof()))
			buffer.append(tempBuffer as Data)

//			buffer.getBytes(&header, length: 16)
			var seek: Int = 0
			var length: Int = 0
			
			length = Int(documentHeader.sizeof())
			buffer.getBytes(&header_document, range: NSMakeRange(seek, length))
			
			seek = length - 1
			length = Int(renderLayerHeader.sizeof())
			buffer.getBytes(&header_layer, range: NSMakeRange(seek, length))
		}
		
		return storage.data
	}
	
	public func decodePrivateFormat(data: Data) {
	}
	
	func copyImageData(typeName: String) -> Data? {
		guard let bitmapContext = copyBitmapContext() else { return nil }
		guard let image = bitmapContext.makeImage() else { return nil }

		let size = CGSize(width: CGFloat(width), height: CGFloat(height))
		let outImage = NSImage.init(cgImage: image, size: size)
		let data = outImage.tiffRepresentation
		
		let tempRep = NSBitmapImageRep(data: data!)
		var fileType: NSBitmapImageRep.FileType = .tiff
		
		if typeName == kUTTypePNG as String {
			fileType = .png
		} else if typeName == kUTTypeJPEG as String {
			fileType = .jpeg
		} else if typeName == kUTTypeBMP as String {
			fileType = .bmp
		} else if typeName == kUTTypeGIF as String {
			fileType = .gif
		} else if typeName == kUTTypeTIFF as String {
			fileType = .tiff
		}
		
		return tempRep?.representation(using: fileType, properties: [:])
	}
	
	public func copyBitmapContext() -> CGContext? {
		return CGContext(data: nil,
										width: Int(width),
										height: Int(height),
										bitsPerComponent: 8,
										bytesPerRow: MemoryLayout<RGBA8>.stride * Int(width),
										space: CGColorSpaceCreateDeviceRGB(),
										bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
	}
	
	public func loadImage(_ image: NSImage) {
		if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
			let bytesPerPixel = MemoryLayout<RGBA8>.stride
			let bytesPerRow = bytesPerPixel * Int(width)
			if let bitmapContext = CGContext(data: nil,
																		width: Int(width),
																		height: Int(height),
																		bitsPerComponent: 8,
																		bytesPerRow: bytesPerRow,
																		space: CGColorSpaceCreateDeviceRGB(),
																		bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) {
				bitmapContext.draw(cgImage, in: getBounds())
				bitmapContext.flush()
				
				if let data = bitmapContext.data?.assumingMemoryBound(to: RGBA8.PixelType.self) {
					// TODO: this is very inefficient and at the least we should
					// copy cell-size rows per each pass
					let startTime = CFAbsoluteTimeGetCurrent()
					for y in 0..<height-1 {
						for x in 0..<width-1 {
							let i = bytesPerRow * Int(y) + bytesPerPixel * Int(x)
							let a: UInt8 = data[i + 3]
							let r: UInt8 = data[i + 0]
							let g: UInt8 = data[i + 1]
							let b: UInt8 = data[i + 2]
							let pixel = RGBA8(r, g, b, a)
							setPixel(x, y, color: pixel)
						}
					}
					let endTime = CFAbsoluteTimeGetCurrent()
					print("copied image to context in:  \(endTime - startTime)")
				}
			}
		} else {
			// TODO: show an error or return an error at least
			print("cgimage couldn't be created")
		}
	}

	func saveImageToDisk(_ filePath: String) {
		guard let bitmapContext = copyBitmapContext() else { return }
		guard let image = bitmapContext.makeImage() else { return }
		CGImageWriteToDisk(image, to: URL(fileURLWithPath: filePath))
		print("saved image to \(filePath)")
	}
	
}

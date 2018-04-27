//
//  BrushPaletteView.swift
//  Blaise
//
//  Created by Ryan Joseph on 4/24/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Cocoa

class BrushPaletteView: NSViewController, BrushPreviewViewDelegate, ColorPickerViewDelegate, ColorGridViewDelegate {

	// MARK: outlets
	
	@IBOutlet weak var colorGrid: ColorGridView!
	@IBOutlet weak var colorPicker: ColorPickerView!
	@IBOutlet weak var brushPreview: BrushPreviewView!
	
	@IBOutlet weak var brushModeButton: NSButton!
	@IBOutlet weak var tabletModeButton: NSButton!
	@IBOutlet weak var airbrushModeButton: NSButton!
	@IBOutlet weak var brushSizeLabel: NSTextField!
	
	// MARK: properties
	
	var canvas: GLCanvasView? {
		willSet {
			if (newValue!.currentBrush.antialias) { brushModeButton.state = .on }
			if (newValue!.currentBrush.pressureEnabled) { tabletModeButton.state = .on }
			if (newValue!.currentBrush.accumulate) { airbrushModeButton.state = .on }
		}
	}

	// MARK: actions
	
	@IBAction func brushModeChanged(_ sender: NSButton) {
		if sender.state == .on {
			canvas?.currentBrush.antialias = true
		} else {
			canvas?.currentBrush.antialias = false
		}
		
		canvas?.updateBrush()
	}
	
	@IBAction func tabletModeChanged(_ sender: NSButton) {
		if sender.state == .on {
			canvas?.currentBrush.pressureEnabled = true
		} else {
			canvas?.currentBrush.pressureEnabled = false
		}
		
		canvas?.updateBrush()
	}
	
	@IBAction func airbrushModeChanged(_ sender: NSButton) {
		if sender.state == .on {
			canvas?.currentBrush.accumulate = true
		} else {
			canvas?.currentBrush.accumulate = false
		}
		
		canvas?.updateBrush()
	}
	
	
	// MARK: delegates
	
	func colorPickerChanged(_ color: RGBA8) {
		canvas?.currentBrush.color = color
		canvas?.updateBrush()
	}
	
	func colorGridChanged(_ color: RGBA8) {
		canvas?.currentBrush.color = color
		canvas?.updateBrush()
	}

	func brushStateChanged(_ state: BrushState) {
		
		if state.states.contains(.size) {
			canvas?.currentBrush.size = state.size
		}
		if state.states.contains(.antialias) {
			canvas?.currentBrush.antialias = state.antialias
		}
		canvas?.updateBrush()
		updateLabels()
	}

	// MARK: methods
	
	func updateLabels() {
		brushSizeLabel.stringValue = "\(UInt(brushPreview.brushSize))pt"
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		brushPreview.delegate = self
		colorGrid.delegate = self
		colorPicker.delegate = self
		
		brushModeButton.state = .off
		tabletModeButton.state = .off
		airbrushModeButton.state = .off

		brushPreview.brushSize = 32.0
		updateLabels()
	}
		
}

//
//  Styles.swift
//  Blaise
//
//  Created by Ryan Joseph on 4/12/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Foundation

struct CanvasStyle {
	static let PrimaryColor = 0;
	static let SecondaryColor = 1;

	var accumulate: Bool = false
	var backgroundColor: RGBA8
	var foregroundColor: [RGBA8] = []
}

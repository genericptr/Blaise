//
//  Geometry.swift
//  Blaise
//
//  Created by Ryan Joseph on 4/28/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Foundation


// NOTE: makes thicker lines
func PlotLine2(pt0: V2, pt1: V2, plot: (_ x: Int, _ y: Int) -> Void) {
	let dx = abs(pt1.x - pt0.x)
	let dy = abs(pt1.y - pt0.y)
	
	var x: Int = Int(pt0.x)
	var y: Int = Int(pt0.y)
	
	let dt_dx: Float = 1.0 / dx
	let dt_dy: Float = 1.0 / dy
	
	var n: Int = 1
	var x_inc, y_inc: Int
	var t_next_y, t_next_x: Float
	
	
	if (dx == 0) {
		x_inc = 0
		t_next_x = dt_dx // infinity
	} else if (pt1.x > pt0.x) {
		x_inc = 1
		n += Int(pt1.x) - x
		t_next_x = Float(pt0.x + 1 - pt0.x) * dt_dx
	} else {
		x_inc = -1
		n += x - Int(pt1.x)
		t_next_x = Float(pt0.x - pt0.x) * dt_dx
	}
	
	
	if (dy == 0) {
		y_inc = 0
		t_next_y = dt_dy // infinity
	} else if (pt1.y > pt0.y) {
		y_inc = 1;
		n += Int(pt1.y) - y;
		t_next_y = Float(pt0.y + 1 - pt0.y) * dt_dy;
	} else {
		y_inc = -1
		n += y - Int(pt1.y)
		t_next_y = Float(pt0.y - pt0.y) * dt_dy
	}
	
	while n > 0 {
		
		plot(x, y)
		
		if (t_next_x <= t_next_y) { // t_next_x is smallest
			x += x_inc
			t_next_x += dt_dx
		} else if (t_next_y <= t_next_x) { // t_next_y is smallest
			y += y_inc
			t_next_y += dt_dy
		}
		n -= 1
	}
	
}

func PlotLine(x0: Int, y0: Int, x1: Int, y1: Int, plot: (_ x: Int, _ y: Int) -> Void) {
	
	let dx: Int = abs(x1-x0)
	let sx = x0<x1 ? 1 : -1
	let dy: Int = abs(y1-y0)
	let sy = y0<y1 ? 1 : -1
	var err: Int = (dx>dy ? dx : -dy)/2
	var e2: Int
	var x: Int = x0
	var y: Int = y0
	
	while true {
		plot(x,y)
		if (x==x1 && y==y1) {
			break
		}
		e2 = err
		if (e2 > -dx) {
			err -= dy
			x += sx
		}
		if (e2 < dy) {
			err += dx
			y += sy
		}
	}
}

//
//  LineUtils.swift
//  Blaise
//
//  Created by Ryan Joseph on 5/5/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Foundation
import Darwin

// NOTE: makes thicker lines that
func PlotLine_Thick(pt0: V2, pt1: V2, plot: (_ x: Int, _ y: Int) -> Void) {
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

// https://rosettacode.org/wiki/Bitmap/Bresenham%27s_line_algorithm#C.2B.2B

// floating point
func PlotLine(p0: V2, p1: V2, plot: (_ x: Float, _ y: Float) -> Void) {
	
	var x1 = p0.x
	var y1 = p0.y
	
	var x2 = p1.x
	var y2 = p1.y
	
	let steep: Bool = (fabs(y2 - y1) > fabs(x2 - x1))
	
	if steep {
		swap(&x1, &y1)
		swap(&x2, &y2)
	}
	
	if x1 > x2 {
		swap(&x1, &x2)
		swap(&y1, &y2)
	}
	
	let dx: Float = x2 - x1
	let dy: Float = fabs(y2 - y1)
	
	var error: Float = dx / 2.0;
	let ystep: Float = (y1 < y2) ? 1 : -1;
	var y = y1
	let maxX = x2
	var x = x1
	
	while x < maxX {
		if steep {
			plot(y, x)
		} else {
			plot(x, y)
		}
		
		error -= dy
		if(error < 0) {
			y += ystep
			error += dx
		}
		
		x += 1
	}
	
}

// https://rosettacode.org/wiki/Bitmap/Bresenham%27s_line_algorithm#C

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

// https://rosettacode.org/wiki/Xiaolin_Wu%27s_line_algorithm#Swift

// return the fractional part of a Double
fileprivate func fpart(_ x: Double) -> Double {
	return modf(x).1
}

// reciprocal of the fractional part of a Double
fileprivate func rfpart(_ x: Double) -> Double {
	return 1 - fpart(x)
}

func PlotLine_AA(_ p0: Vec2<Double>, _ p1: Vec2<Double>, plot: (_ alpha: Double, _ x: Int, _ y: Int) -> Void) {
	var x0 = p0.x, x1 = p1.x, y0 = p0.y, y1 = p1.y //swapable ptrs
	let steep = abs(y1 - y0) > abs(x1 - x0)
	if steep {
		swap(&x0, &y0)
		swap(&x1, &y1)
	}
	if x0 > x1 {
		swap(&x0, &x1)
		swap(&y0, &y1)
	}
	let dX = x1 - x0
	let dY = y1 - y0
	
	var gradient: Double
	if dX == 0.0 {
		gradient = 1.0
	} else {
		gradient = dY / dX
	}
	
	// handle endpoint 1
	var xend = round(x0)
	var yend = y0 + gradient * (xend - x0)
	var xgap = rfpart(x0 + 0.5)
	let xpxl1 = Int(xend)
	let ypxl1 = Int(yend)
	
	// first y-intersection for the main loop
	var intery = yend + gradient
	
	if steep {
		plot(rfpart(yend) * xgap, ypxl1, xpxl1)
		plot(fpart(yend) * xgap, ypxl1 + 1, xpxl1)
	} else {
		plot(rfpart(yend) * xgap, xpxl1, ypxl1)
		plot(fpart(yend) * xgap, xpxl1, ypxl1 + 1)
	}
	
	xend = round(x1)
	yend = y1 + gradient * (xend - x1)
	xgap = fpart(x1 + 0.5)
	let xpxl2 = Int(xend)
	let ypxl2 = Int(yend)
	
	// handle second endpoint
	if steep {
		plot(rfpart(yend) * xgap, ypxl2, xpxl2)
		plot(fpart(yend) * xgap, ypxl2 + 1, xpxl2)
	} else {
		plot(rfpart(yend) * xgap, xpxl2, ypxl2)
		plot(fpart(yend) * xgap, xpxl2, ypxl2 + 1)
	}
	
	// main loop
	if steep && xpxl1+1 < xpxl2 {
		for x in xpxl1+1..<xpxl2 {
			plot(rfpart(intery), Int(intery), x)
			plot(fpart(intery), Int(intery) + 1, x)
			intery += gradient
		}
	} else if xpxl1+1 < xpxl2 {
		for x in xpxl1+1..<xpxl2 {
			plot(rfpart(intery), x, Int(intery))
			plot(fpart(intery), x, Int(intery) + 1)
			intery += gradient
		}
	}
}

//
//  Preferences.swift
//  Blaise
//
//  Created by Ryan Joseph on 5/1/18.
//  Copyright © 2018 The Alchemist Guild. All rights reserved.
//

import Foundation

enum PreferenceKey: String {
	case minGridZoom = "minGridZoom"
}

class Prefs {
	static func getInt(_ key: PreferenceKey) -> Int {
		return UserDefaults.standard.integer(forKey: key.rawValue)
	}
	
	static func getFloat(_ key: PreferenceKey) -> Float {
		return UserDefaults.standard.float(forKey: key.rawValue)
	}
	
	static func getString(_ key: PreferenceKey) -> String {
		let str = UserDefaults.standard.string(forKey: key.rawValue)
		if str != nil {
			return str!
		} else {
			return ""
		}
	}
	
	static func set(_ key: PreferenceKey, _ value: Any) {
		UserDefaults.standard.set(value, forKey: key.rawValue)
	}

}

//func GetIntPref(_ key: PreferenceKey) -> Int {
//	return UserDefaults.standard.integer(forKey: key.rawValue)
//}
//
//func GetFloatPref(_ key: PreferenceKey) -> Float {
//	return UserDefaults.standard.float(forKey: key.rawValue)
//}
//
//func GetStringPref(_ key: PreferenceKey) -> String {
//	let str = UserDefaults.standard.string(forKey: key.rawValue)
//	if str != nil {
//		return str!
//	} else {
//		return ""
//	}
//}
//
//func SetPref(_ key: PreferenceKey, _ value: Any) {
//	UserDefaults.standard.set(value, forKey: key.rawValue)
//	UserDefaults.standard.synchronize()
//}

func TestPrefs() {
	Prefs.set(.minGridZoom, "foo")
	let i: String = Prefs.getString(.minGridZoom)
	print(i)
}

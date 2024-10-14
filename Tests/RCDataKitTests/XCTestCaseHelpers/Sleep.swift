//
//  Sleep.swift
//  RCDataKit
//
//  Created by Ryan Linn on 10/13/24.
//

import Foundation

func sleep(seconds: Double) async {
    try! await Task.sleep(for: .seconds(seconds))
}

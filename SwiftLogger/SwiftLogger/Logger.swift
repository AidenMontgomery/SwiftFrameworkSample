//
//  Logger.swift
//  SwiftLogger
//
//  Created by Aiden Montgomery on 19/01/2016.
//  Copyright © 2016 Constructive Coding. All rights reserved.
//

import Foundation

public class Logger {
    public init() {}
    public static let sharedInstance = Logger()
    
    public func Log(message: String) {
        print(message)
    }
}
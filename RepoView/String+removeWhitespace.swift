//
//  String+removeWhitespace.swift
//  RepoView
//
//  Created by Bryon Martin on 1/16/18.
//  Copyright © 2018 Bryon Martin. All rights reserved.
//

extension String {
    func removeWhitespace() -> String {
        return components(separatedBy: .whitespaces).joined()
    }
    
}

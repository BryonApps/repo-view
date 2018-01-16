//
//  GitRepository.swift
//  RepoView
//
//  Created by Bryon Martin on 1/12/18.
//  Copyright © 2018 Bryon Martin. All rights reserved.
//
import Foundation

struct GitRepository : Decodable {
    var name: String
    var description: String?
    var stargazersCount: Int
    var forksCount: Int
    var language: String?
    var updatedString: String


    enum CodingKeys : String, CodingKey {
        case name
        case description
        case stargazersCount = "stargazers_count"
        case forksCount = "forks_count"
        case language
        case updatedString = "updated_at"
    }
}



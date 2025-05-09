
//
//  Repository.swift
//  gitler
//
//  Created by Crisler on 5/10/25.
//

import Foundation

struct Repository: Identifiable, Decodable {
    let id: Int
    let name: String
    let language: String?
    let stargazersCount: Int
    let description: String?
    let htmlUrl: String
    let fork: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case language
        case stargazersCount = "stargazers_count"
        case description
        case htmlUrl = "html_url"
        case fork
    }
}

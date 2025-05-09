
//
//  User.swift
//  gitler
//
//  Created by Crisler on 5/10/25.
//

import Foundation

struct User: Identifiable, Decodable {
    let id: Int
    let login: String // Username
    let avatarUrl: String
    let name: String? // Full name (nullable)
    let followers: Int? // Available on user detail endpoint
    let following: Int? // Available on user detail endpoint
    let reposUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case login
        case avatarUrl = "avatar_url"
        case name
        case followers
        case following
        case reposUrl = "repos_url"
    }
}

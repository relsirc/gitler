//
//  GitHubService.swift
//  gitler
//
//  Created by Crisler on 5/10/25.
//

import Foundation

class GitHubService: ObservableObject {
    private let baseURL = "https://api.github.com"
    // TODO: Add Personal Access Token handling
    // private let accessToken = "YOUR_PERSONAL_ACCESS_TOKEN"

    func fetchUsers(since: Int? = nil, perPage: Int = 30) async throws -> [User] {
        var urlString = "\(baseURL)/users?per_page=\(perPage)"
        if let since = since {
            urlString += "&since=\(since)"
        }

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        // TODO: Add Authorization header if accessToken is available
        // if !accessToken.isEmpty {
        //     request.addValue("token \(accessToken)", forHTTPHeaderField: "Authorization")
        // }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let users = try JSONDecoder().decode([User].self, from: data)
        return users
    }
    
    // ADD: fetchUserDetails method
    func fetchUserDetails(username: String) async throws -> User {
        let urlString = "\(baseURL)/users/\(username)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        // Add token if available

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let user = try JSONDecoder().decode(User.self, from: data)
        return user
    }

    // ADD: fetchRepositories method
    func fetchRepositories(username: String, page: Int = 1, perPage: Int = 100) async throws -> [Repository] {
        // The user model from the list might not have repos_url, so we construct it.
        // Alternatively, ensure the User object passed to this view has repos_url or fetch it first.
        // For now, constructing directly.
        let urlString = "\(baseURL)/users/\(username)/repos?type=owner&sort=updated&page=\(page)&per_page=\(perPage)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        // Add token if available

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let repositories = try JSONDecoder().decode([Repository].self, from: data)
        // Filter out forked repositories as per requirements
        return repositories.filter { !$0.fork }
    }
}

//
//  GitHubService.swift
//  gitler
//
//  Created by Crisler on 5/10/25.
//

import Foundation
import Moya

class GitHubService: ObservableObject {
    // CHANGE: Make provider internal and allow injection for testing
    internal let provider: MoyaProvider<GitHubAPI>

    // ADD: Initializer for dependency injection (testing) and default provider
    init(provider: MoyaProvider<GitHubAPI> = MoyaProvider<GitHubAPI>()) {
        self.provider = provider
    }

    func fetchUsers(since: Int? = nil, perPage: Int = 30) async throws -> [User] {
        return try await withCheckedThrowingContinuation { continuation in
            provider.request(.fetchUsers(since: since, perPage: perPage)) { result in
                switch result {
                case .success(let response):
                    do {
                        let users = try response.map([User].self)
                        continuation.resume(returning: users)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                case .failure(let moyaError):
                    continuation.resume(throwing: moyaError)
                }
            }
        }
    }
    
    func fetchUserDetails(username: String) async throws -> User {
        return try await withCheckedThrowingContinuation { continuation in
            provider.request(.fetchUserDetails(username: username)) { result in
                switch result {
                case .success(let response):
                    do {
                        let user = try response.map(User.self)
                        continuation.resume(returning: user)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                case .failure(let moyaError):
                    continuation.resume(throwing: moyaError)
                }
            }
        }
    }

    func fetchRepositories(username: String, page: Int = 1, perPage: Int = 100) async throws -> [Repository] {
        return try await withCheckedThrowingContinuation { continuation in
            provider.request(.fetchRepositories(username: username, page: page, perPage: perPage)) { result in
                switch result {
                case .success(let response):
                    do {
                        let repositories = try response.map([Repository].self)
                        continuation.resume(returning: repositories.filter { !$0.fork })
                    } catch {
                        continuation.resume(throwing: error)
                    }
                case .failure(let moyaError):
                    continuation.resume(throwing: moyaError)
                }
            }
        }
    }
}

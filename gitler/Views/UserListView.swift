//
//  UserListView.swift
//  gitler
//
//  Created by Crisler on 5/10/25.
//

import SwiftUI

struct UserListView: View {
    // We'll add state for users later
    // @State private var users: [User] = []
    @StateObject private var githubService = GitHubService()
    @State private var users: [User] = []
    @State private var isLoading = false
    // CHANGE: Renamed errorMessage to activeError and changed its type to AppError?
    @State private var activeError: AppError?

    var body: some View {
        NavigationView {
            // CHANGE: List content
            List(users) { user in
                // CHANGE: Updated NavigationLink destination
                NavigationLink(destination: UserRepositoryView(username: user.login)) {
                    UserRowView(user: user)
                }
            }
            .navigationTitle("GitHub Users")
            // ADD: .onAppear and .alert
            .onAppear {
                if users.isEmpty { // Fetch only if users list is empty
                    Task {
                        await loadUsers()
                    }
                }
            }
            // CHANGE: Updated .alert modifier
            .alert(
                isPresented: Binding(
                    get: { activeError != nil },
                    set: { isActive in
                        if !isActive { activeError = nil }
                    }
                ),
                error: activeError,
                actions: { _ in // The unwrapped error is passed here if needed for action logic
                    Button("OK") {
                        // The binding automatically handles dismissing the alert
                        // and setting activeError to nil.
                    }
                },
                message: { error in // The unwrapped error is passed here
                    Text(error.recoverySuggestion ?? "An unexpected error occurred. Please try again.")
                }
            )
            // ADD: Overlay for loading state
            .overlay {
                if isLoading && users.isEmpty { // Show loading indicator only on initial load
                    ProgressView("Loading users...")
                }
            }
        }
    }

    // ADD: loadUsers function
    private func loadUsers() async {
        isLoading = true
        // CHANGE: Ensure activeError is nil before a new request
        await MainActor.run {
            activeError = nil
        }
        do {
            let fetchedUsers = try await githubService.fetchUsers()
            // Update on the main thread
            await MainActor.run {
                self.users = fetchedUsers
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                // CHANGE: Set activeError with an AppError instance
                self.activeError = AppError(message: "Failed to load users: \(error.localizedDescription)")
                self.isLoading = false
            }
        }
    }
}

// ADD: AppError struct for alert
struct AppError: LocalizedError {
    let message: String
    var errorDescription: String? { message } // This will be the alert title
    var recoverySuggestion: String? { "Please check your connection and try again." } // This is used by the message closure
}

#Preview {
    UserListView()
}

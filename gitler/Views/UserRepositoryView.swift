
//
//  UserRepositoryView.swift
//  gitler
//
//  Created by Crisler on 5/10/25.
//

import SwiftUI
import WebKit // For WebView

struct UserRepositoryView: View {
    @StateObject private var githubService = GitHubService()
    let username: String // Passed from UserListView

    @State private var userDetails: User?
    @State private var repositories: [Repository] = []
    @State private var isLoadingUserDetails = false
    @State private var isLoadingRepositories = false
    @State private var activeError: AppError?
    
    // For WebView
    @State private var selectedRepositoryURL: URL?
    @State private var showWebView = false

    var body: some View {
        List {
            if isLoadingUserDetails && userDetails == nil {
                Section {
                    HStack {
                        Spacer()
                        ProgressView("Loading user details...")
                        Spacer()
                    }
                }
            } else if let user = userDetails {
                UserDetailsSectionView(user: user)
            }

            if isLoadingRepositories && repositories.isEmpty && userDetails != nil {
                Section {
                    HStack {
                        Spacer()
                        ProgressView("Loading repositories...")
                        Spacer()
                    }
                }
            } else if !repositories.isEmpty {
                RepositoryListSectionView(repositories: repositories) { repo in
                    if let url = URL(string: repo.htmlUrl) {
                        selectedRepositoryURL = url
                        showWebView = true
                    }
                }
            } else if !isLoadingRepositories && userDetails != nil { // Loaded user, but no repos and not loading
                 Section {
                    Text("No public repositories found for this user.")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle(username)
        .navigationBarTitleDisplayMode(.inline)
        .task { // Use .task for initial data loading
            await loadAllData()
        }
        .alert(
            isPresented: Binding(
                get: { activeError != nil },
                set: { isActive in if !isActive { activeError = nil } }
            ),
            error: activeError,
            actions: { _ in Button("OK") {} },
            message: { error in Text(error.recoverySuggestion ?? "An unexpected error occurred.") }
        )
        .sheet(isPresented: $showWebView) {
            if let url = selectedRepositoryURL {
                // Ensure WebView is presented only if URL is valid
                NavigationView { // Added NavigationView for a title and dismiss button
                    WebView(url: url)
                        .navigationTitle("Repository")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Done") {
                                    showWebView = false
                                }
                            }
                        }
                }
            }
        }
    }

    private func loadAllData() async {
        // Don't reload if data already exists (e.g., coming back from navigation)
        // unless a pull-to-refresh is implemented.
        guard userDetails == nil && repositories.isEmpty else { return }
        
        await loadUserDetails()
        // Only load repositories if user details were successfully fetched.
        if activeError == nil, userDetails != nil {
            await loadRepositories()
        }
    }

    private func loadUserDetails() async {
        isLoadingUserDetails = true
        activeError = nil // Reset error
        do {
            let fetchedUser = try await githubService.fetchUserDetails(username: username)
            await MainActor.run {
                self.userDetails = fetchedUser
                isLoadingUserDetails = false
            }
        } catch {
            await MainActor.run {
                self.activeError = AppError(message: "Failed to load user details: \(error.localizedDescription)")
                isLoadingUserDetails = false
            }
        }
    }

    private func loadRepositories() async {
        isLoadingRepositories = true
        // activeError = nil // Don't reset error if user details failed
        do {
            let fetchedRepos = try await githubService.fetchRepositories(username: username)
            await MainActor.run {
                self.repositories = fetchedRepos
                isLoadingRepositories = false
            }
        } catch {
            await MainActor.run {
                self.activeError = AppError(message: "Failed to load repositories: \(error.localizedDescription)")
                isLoadingRepositories = false
            }
        }
    }
}

// MARK: - Subviews for User Details and Repository List

struct UserDetailsSectionView: View {
    let user: User

    var body: some View {
        Section(header: Text("User Details").font(.title2).padding(.bottom, 5)) {
            HStack(alignment: .top, spacing: 15) {
                AsyncImage(url: URL(string: user.avatarUrl)) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 10)) // Changed to RoundedRectangle for a bit more modern look
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 100, height: 100)

                VStack(alignment: .leading, spacing: 5) {
                    Text(user.login)
                        .font(.title3)
                        .fontWeight(.bold)
                    if let name = user.name, !name.isEmpty {
                        Text(name)
                            .font(.body)
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Image(systemName: "person.2.fill")
                        Text("\(user.followers ?? 0) Followers")
                    }
                    .font(.caption)
                    HStack {
                        Image(systemName: "person.crop.circle.badge.plus")
                        Text("\(user.following ?? 0) Following")
                    }
                    .font(.caption)
                }
                Spacer()
            }
            .padding(.vertical)
        }
    }
}

struct RepositoryListSectionView: View {
    let repositories: [Repository]
    let onRepoTapped: (Repository) -> Void

    var body: some View {
        Section(header: Text("Repositories").font(.title2).padding(.bottom, 5)) {
            ForEach(repositories) { repo in
                Button(action: { onRepoTapped(repo) }) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(repo.name)
                            .font(.headline)
                            .foregroundColor(.primary) // Ensure text color is appropriate for a button
                        if let description = repo.description, !description.isEmpty {
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        HStack {
                            if let language = repo.language, !language.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "circle.fill") // Placeholder for language color dot
                                        .resizable()
                                        .frame(width: 8, height: 8)
                                        .foregroundColor(languageColor(language)) // Simple language color
                                    Text(language)
                                }
                            }
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                Text("\(repo.stargazersCount)")
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 5)
            }
        }
    }
    
    // Simple language to color mapping (can be expanded)
    private func languageColor(_ language: String) -> Color {
        switch language.lowercased() {
        case "swift": return .orange
        case "javascript": return .yellow
        case "python": return .blue
        case "java": return .red
        case "html": return .pink
        case "css": return .purple
        default: return .gray
        }
    }
}

// MARK: - WebView
// Simple WebView using WKWebView
struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
}

#Preview {
    // Preview requires a username that exists on GitHub
    NavigationView {
        UserRepositoryView(username: "octocat")
    }
}


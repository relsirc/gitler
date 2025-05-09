import Foundation
import Moya

enum GitHubAPI {
    case fetchUsers(since: Int?, perPage: Int)
    case fetchUserDetails(username: String)
    case fetchRepositories(username: String, page: Int, perPage: Int)
}

extension GitHubAPI: TargetType {
    var baseURL: URL {
        return URL(string: "https://api.github.com")!
    }

    var path: String {
        switch self {
        case .fetchUsers:
            return "/users"
        case .fetchUserDetails(let username):
            return "/users/\(username)"
        case .fetchRepositories(let username, _, _):
            return "/users/\(username)/repos"
        }
    }

    var method: Moya.Method {
        return .get
    }

    var sampleData: Data { // For testing purposes
        return Data()
    }

    var task: Task {
        switch self {
        case .fetchUsers(let since, let perPage):
            var params: [String: Any] = ["per_page": perPage]
            if let since = since {
                params["since"] = since
            }
            return .requestParameters(parameters: params, encoding: URLEncoding.queryString)
        case .fetchUserDetails:
            return .requestPlain
        case .fetchRepositories(_, let page, let perPage):
            let params: [String: Any] = [
                "type": "owner",
                "sort": "updated",
                "page": page,
                "per_page": perPage
            ]
            return .requestParameters(parameters: params, encoding: URLEncoding.queryString)
        }
    }

    var headers: [String: String]? {
        let headers = ["Accept": "application/vnd.github.v3+json"]
        // TODO: Add Personal Access Token handling
        // if let token = ProcessInfo.processInfo.environment["GITHUB_ACCESS_TOKEN"], !token.isEmpty {
        //     // If the token logic were active, 'headers' would need to be 'var'
        //     // and we'd do: headers["Authorization"] = "token \(token)"
        // }
        return headers
    }
}

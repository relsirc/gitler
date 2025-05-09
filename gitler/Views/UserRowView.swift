
//
//  UserRowView.swift
//  gitler
//
//  Created by Crisler on 5/10/25.
//

import SwiftUI

struct UserRowView: View {
    let user: User

    var body: some View {
        HStack {
            AsyncImage(url: URL(string: user.avatarUrl)) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(Circle())
            } placeholder: {
                ProgressView()
            }
            .frame(width: 50, height: 50)

            Text(user.login)
                .font(.headline)
            
            Spacer()
        }
    }
}

// #Preview {
//    UserRowView(user: User(id: 1, login: "mojombo", avatarUrl: "https://avatars.githubusercontent.com/u/1?v=4", name: "Tom Preston-Werner", followers: 23000, following: 11, reposUrl: "https://api.github.com/users/mojombo/repos"))
// }

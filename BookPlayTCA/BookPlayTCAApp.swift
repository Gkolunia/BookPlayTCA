//
//  BookPlayTCAApp.swift
//  BookPlayTCA
//
//  Created by Mykola Hrybeniuk on 31.07.2024.
//

import SwiftUI
import ComposableArchitecture

@main
struct BookPlayTCAApp: App {
    var body: some Scene {
        WindowGroup {
            BookPlayMainView(store: .init(initialState: BookPlayMain.State.init(metadataUrlString: URL.init(string: "https://firebasestorage.googleapis.com/v0/b/test-a6f79.appspot.com/o/book_metadata.json?alt=media&token=cd7ee3b7-cc8e-468c-9bde-5481b8a135f0")!,
                                                                                downloadMode: .notDownloaded,
                                                                                id: .init()), reducer: {
                BookPlayMain()._printChanges()
            }))
        }
    }
}

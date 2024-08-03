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
            BookPlayMainView(store: .init(initialState: BookPlayMain.State.init(metadataUrlString: URL.init(string: "https://firebasestorage.googleapis.com/v0/b/test-a6f79.appspot.com/o/book_metadata.json?alt=media&token=b29fece5-a418-4413-9a7b-1ee1d42df642")!,
                                                                                downloadMode: .notDownloaded, isLyrics: false), reducer: {
                BookPlayMain()._printChanges()
            }))
        }
    }
}

//
//  BookPlayTCAApp.swift
//  BookPlayTCA
//
//  Created by Mykola Hrybeniuk on 31.07.2024.
//

import SwiftUI
import ComposableArchitecture
import XCTestDynamicOverlay

let metadataURLString = "https://firebasestorage.googleapis.com/v0/b/test-a6f79.appspot.com/o/book_metadata.json?alt=media&token=b29fece5-a418-4413-9a7b-1ee1d42df642"

@main
struct BookPlayTCAApp: App {
    var body: some Scene {
        WindowGroup {
            if !_XCTIsTesting {
                BookPlayMainView(store: .init(initialState: BookPlayMainReducer.State.init(metadataUrlString: metadataURLString,
                                                                                           downloadMode: .notDownloaded,
                                                                                           isLyricsScreenMode: false,
                                                                                           playerState: .init()),
                                              reducer: {
                    BookPlayMainReducer()._printChanges()
                }))
            }
            
        }
    }
}

//
//  BookPlayMainView.swift
//  BookPlayTCA
//
//  Created by Mykola Hrybeniuk on 04.08.2024.
//

import AVFoundation
import ComposableArchitecture
import SwiftUI

struct BookPlayMainView: View {
    
    let store: StoreOf<BookPlayMainReducer>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            
            switch viewStore.downloadMode {
            case .downloading, .initialDownloading:
                ZStack {
                    ProgressView()
                        .frame(width: 16, height: 16)
                }
                
            case .notDownloaded:
                ZStack {
                    ProgressView()
                        .frame(width: 16, height: 16)
                        .onAppear(perform: {
                            viewStore.send(.screenLoaded)
                        })
                }
                
            case .downloadingFailed:
                Text("Error, world!")
                
            case .downloaded:
                VStack {
                    if store.isLyrics {
                        ScrollWithFadedEdgesView(text: viewStore.lyricsText)
                    } else {
                        AsyncImage(url: viewStore.coverImageUrl)
                    }
                    
                    Text(viewStore.chaptersCount)
                    Text(viewStore.chapterName)
                
                    BookPlayerComponentView(store: store.scope(state: \.playerState, action: \.playerAction))
                    ToggleButtonView(isRightSelected: viewStore.binding(
                                        get: \.isLyrics,
                                        send: BookPlayMainReducer.Action.changeScreenType),
                                     leftIcon: "headphones",
                                     rightIcon: "text.alignleft")
                }
                .padding()
            }
        }
    }

}

#Preview {
    BookPlayMainView(store: .init(initialState: BookPlayMainReducer.State.init(metadataUrlString: "https://firebasestorage.googleapis.com/v0/b/test-a6f79.appspot.com/o/book_metadata.json?alt=media&token=cd7ee3b7-cc8e-468c-9bde-5481b8a135f0",
                                                                               downloadMode: .notDownloaded, isLyrics: .init(false), playerState: .init()), reducer: {}))
}

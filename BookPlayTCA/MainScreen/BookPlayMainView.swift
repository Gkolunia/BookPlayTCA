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
            
            switch store.state.downloadMode {
            case .downloading(_), .startingToDownload:
                ZStack {
                    ProgressView()
                        .frame(width: 16, height: 16)
                }
                
            case .notDownloaded:
                ZStack {
                    ProgressView()
                        .frame(width: 16, height: 16)
                        .onAppear(perform: {
                            store.send(.screenLoaded)
                        })
                }
                
            case .downloadingFailed:
                Text("Error, world!")
                
            case .downloaded:
                
                VStack {
                    if store.isLyrics {
                        ScrollWithFadedEdgesView(text: store.lyricsText)
                    } else {
                        AsyncImage(url: store.state.coverImageUrl)
                    }
                    
                    Text(store.chaptersCount)
                    Text(store.chapterName)
                    
                    BookPlayerComponentView(store: .init(initialState: .init(currentTrack: createAVItem()), reducer: {
                        BookPlayerComponentReducer(nextTrackHandler: {
                            store.send(.nextChapter)
                        }, previousTrackHandler: {
                            store.send(.previousChapter)
                        })._printChanges()
                    }))
                    
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
    
    private func createAVItem() -> AVPlayerItem? {
        guard let url = store.state.currentUrl else {
            return nil
        }
        return .init(url: url)
    }
}



#Preview {
    BookPlayMainView(store: .init(initialState: BookPlayMainReducer.State.init(metadataUrlString:  URL.init(string: "https://firebasestorage.googleapis.com/v0/b/test-a6f79.appspot.com/o/book_metadata.json?alt=media&token=cd7ee3b7-cc8e-468c-9bde-5481b8a135f0")!,
                                                                        downloadMode: .notDownloaded, isLyrics: .init(false)), reducer: {}))
}

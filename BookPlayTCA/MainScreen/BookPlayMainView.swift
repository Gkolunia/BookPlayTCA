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
                
            case .downloaded, .downloadingFailed:
                VStack {
                    if store.isLyricsScreenMode {
                        ScrollWithFadedEdgesView(text: viewStore.lyricsText)
                    } else {
                        AsyncImage(url: viewStore.coverImageUrl) { result in
                                    result.image?
                                        .resizable()
                                        .scaledToFit()
                        }
                        .cornerRadius(16)
                    }
                    
                    
                    Text(viewStore.chaptersCount)
                        .foregroundStyle(.gray)
                        .font(.system(size: 16, weight: .semibold))
                        .padding(.all, /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
                    Text(viewStore.chapterName)
                        .font(.system(size: 14, weight: .semibold))
                        .multilineTextAlignment(.center)
                    
                    
                    
                
                    BookPlayerComponentView(store: store.scope(state: \.playerState, action: \.playerAction))
                    ToggleButtonView(isRightSelected: viewStore.binding(
                                        get: \.isLyricsScreenMode,
                                        send: BookPlayMainReducer.Action.changeScreenType),
                                     leftIcon: "headphones",
                                     rightIcon: "text.alignleft")
                }
                .padding()
                .alert("Book loading is failed", isPresented: .constant(viewStore.downloadMode == .downloadingFailed)) {
                    Button("Try Again", role: .cancel) {
                        viewStore.send(.tryLoadBookAgain)
                    }
                }
            }
        }
        
    }

}

#Preview {
    BookPlayMainView(store: .init(initialState: BookPlayMainReducer.State.init(metadataUrlString: metadataURLString,
                                                                               downloadMode: .downloaded, isLyricsScreenMode: .init(false), playerState: .init()), reducer: {}))
}

//
//  BookPlayMain.swift
//  BookPlayTCA
//
//  Created by Mykola Hrybeniuk on 31.07.2024.
//

import AVFoundation
import ComposableArchitecture
import SwiftUI

struct Metadata: Codable, Equatable {
    struct Chapter: Codable, Equatable {
        let title: String
        let fileUrl: String
        let text: String
    }
    
    let bookName: String
    let imageUrl: String
    let keyPoints: [Chapter]
}

@Reducer
struct BookPlayMain {
    
    @ObservableState
    struct State {
        let metadataUrlString: URL
        var downloadAlert: AlertState<DownloadComponent.Action.Alert>?
        var downloadMode: Mode
        var coverImageUrl: URL?
        var nameBook: String = ""
        var chaptersCount: String = ""
        var chapterName: String = ""
        var keyPoints: [Metadata.Chapter] = []
        var currentUrl: URL?
        var lyricsText: String = ""
        var isLyrics: Bool
        
        enum Field: String, Hashable {
          case isLyrics
        }
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case play
        case screenLoaded
        case downloadMetaData(Result<DownloadClient.Event, Error>)
    }
    
    @Dependency(\.downloadClient) var downloadClient
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            
            switch action {
            case .binding:
                return .none
            case .play:
                return .none
                
            case .screenLoaded:
                
                guard state.downloadMode == .notDownloaded else { return .none }
                state.downloadMode = .startingToDownload
                
                return .run { [url = state.metadataUrlString] send in
                    for try await event in self.downloadClient.download(url: url) {
                        await send(.downloadMetaData(.success(event)), animation: .default)
                    }
                } catch: { error, send in
                    await send(.downloadMetaData(.failure(error)), animation: .default)
                }
                
                
            case .downloadMetaData(.success(.response(_, let data))):
                let decoder = JSONDecoder()
                do {
                    let metaData = try decoder.decode(Metadata.self, from: data)
                    
                    state.coverImageUrl = URL.init(string: metaData.imageUrl)
                    state.nameBook = metaData.bookName
                    state.downloadMode = .downloaded
                    state.keyPoints = metaData.keyPoints
                    
                    if let intro = metaData.keyPoints.first {
                        state.currentUrl = URL(string: intro.fileUrl)
                        state.chapterName = intro.title
                        state.lyricsText = intro.text
                    }
                    
                    state.chaptersCount = "KEY POINT 1 OF \(metaData.keyPoints.count)"
                }
                catch {
                    state.downloadMode = .downloadingFailed
                    return .none
                }
                
                state.downloadMode = .downloaded
                return .none
                
            case let .downloadMetaData(.success(.updateProgress(progress))):
                state.downloadMode = .downloading(progress: progress)
                return .none
                
            case .downloadMetaData(.failure):
                state.downloadMode = .downloadingFailed
                return .none

            }
        }
    }
    
}

struct BookPlayMainView: View {
    
    @Bindable var store: StoreOf<BookPlayMain>
    
    var body: some View {
        
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
                    ZStack(content: {
                        ScrollView {
                            Text(store.lyricsText)
                                .font(.system(size: 22))
                        }
                        .contentMargins(.all, 20.0, for: .scrollContent)
                        
                        VStack(content: {
                            Rectangle()
                                .fill(
                                    LinearGradient(gradient: Gradient(colors: [.white, .clear]), startPoint: .top, endPoint: .bottom)
                                )
                                .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, maxHeight: 50)
                            Spacer()
                            Rectangle()
                                .fill(
                                    LinearGradient(gradient: Gradient(colors: [.white, .clear]), startPoint: .bottom, endPoint: .top)
                                )
                                .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, maxHeight: 50)
                        })
                    })
                    
                    
                    
                } else {
                    AsyncImage(url: store.state.coverImageUrl)
                }
                
                Text(store.chaptersCount)
                Text(store.chapterName)
                
                BookPlayerComponentView(store: .init(initialState: .init(currentTrack: createAVItem()), reducer: {
                    BookPlayerComponent()._printChanges()
                }))
                
                ToggleButton(isRightSelected: $store.isLyrics, leftIcon: "headphones", rightIcon: "text.alignleft")
                
                
            }
            .padding()
            
            
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
    BookPlayMainView(store: .init(initialState: BookPlayMain.State.init(metadataUrlString:  URL.init(string: "https://firebasestorage.googleapis.com/v0/b/test-a6f79.appspot.com/o/book_metadata.json?alt=media&token=cd7ee3b7-cc8e-468c-9bde-5481b8a135f0")!,
                                                                        downloadMode: .notDownloaded, isLyrics: .init(false)), reducer: {}))
}

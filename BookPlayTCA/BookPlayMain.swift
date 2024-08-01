//
//  BookPlayMain.swift
//  BookPlayTCA
//
//  Created by Mykola Hrybeniuk on 31.07.2024.
//

import AVFoundation
import ComposableArchitecture
import SwiftUI

struct Metadata: Codable {
    
    struct Chapter: Codable {
        let title: String
        let audioFileUrl: String
    }
    
    let bookName: String
    let imageUrl: String
//    let keyPoints: [Chapter]
}

@Reducer
struct BookPlayMain {
    
    @ObservableState
    struct State: Equatable {
        let metadataUrlString: URL
        var downloadAlert: AlertState<DownloadComponent.Action.Alert>?
        var downloadMode: Mode
        let id: UUID
        var coverImageUrl: URL?
        var nameBook: String = ""
    }
    
    enum Action: Sendable {
        case play
        case screenLoaded
        case downloadClient(Result<DownloadClient.Event, Error>)
    }
    
    @Dependency(\.downloadClient) var downloadClient
    
    var body: some Reducer<State, Action> {
        
        Reduce { state, action in
            
            switch action {
            case .play:
                return .none
                
            case .screenLoaded:
                
                guard state.downloadMode == .notDownloaded else { return .none }
                state.downloadMode = .startingToDownload
                
                return .run { [url = state.metadataUrlString] send in
                    for try await event in self.downloadClient.download(url: url) {
                        await send(.downloadClient(.success(event)), animation: .default)
                    }
                } catch: { error, send in
                    await send(.downloadClient(.failure(error)), animation: .default)
                }
                
                
            case .downloadClient(.success(.response(let data))):
                let decoder = JSONDecoder()
                do {
                    let metaData = try decoder.decode(Metadata.self, from: data)
                    
                    state.coverImageUrl = URL.init(string: metaData.imageUrl)
                    state.nameBook = metaData.bookName
                    state.downloadMode = .downloaded
                }
                catch {
                    state.downloadMode = .downloadingFailed
                }
                
                return .none
                
            case let .downloadClient(.success(.updateProgress(progress))):
                state.downloadMode = .downloading(progress: progress)
                return .none
                
            case .downloadClient(.failure):
                state.downloadMode = .downloadingFailed
                return .none
            }
        }
    }
    
}

struct BookPlayMainView: View {
    
    let store: StoreOf<BookPlayMain>
    
    var body: some View {
        
        switch store.state.downloadMode {
        case .downloading(_), .startingToDownload:
            ZStack {
                ProgressView()
                Rectangle()
                    .frame(width: 6, height: 6)
            }
        
        case .notDownloaded:
            ZStack {
                ProgressView()
                    .onAppear(perform: {
                        store.send(.screenLoaded)
                    })
                Rectangle()
                    .frame(width: 6, height: 6)
            }
        
        case .downloadingFailed:
            Text("Error, world!")
            
        case .downloaded:
            VStack {
                AsyncImage(url: store.state.coverImageUrl)
                Text(store.nameBook)
            }
            .padding()
            
            
        }
    }
}

#Preview {
    BookPlayMainView(store: .init(initialState: BookPlayMain.State.init(metadataUrlString:  URL.init(string: "https://firebasestorage.googleapis.com/v0/b/test-a6f79.appspot.com/o/book_metadata.json?alt=media&token=cd7ee3b7-cc8e-468c-9bde-5481b8a135f0")!,
                                                                        downloadMode: .notDownloaded, id: .init()), reducer: {}))
}

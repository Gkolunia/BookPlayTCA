//
//  BookPlayMain.swift
//  BookPlayTCA
//
//  Created by Mykola Hrybeniuk on 31.07.2024.
//

import Foundation
import ComposableArchitecture

@Reducer
struct BookPlayMainReducer {
    
    @ObservableState
    struct State: Equatable {
        let metadataUrlString: String
        var downloadMode: Mode = .notDownloaded
        var coverImageUrl: URL?
        var keyPoints: [Metadata.Chapter] = []
        var isLyricsScreenMode: Bool = false
        
        var currentChapter: Metadata.Chapter?
        var chaptersCount: String = ""
        var lyricsText: String { currentChapter?.text ?? "" }
        var chapterName: String { currentChapter?.title ?? "" }
        var currentUrl: URL? {
            guard let url = currentChapter?.fileUrl else {
                return nil
            }
            return URL(string: url)
        }
        
        var playerState: BookPlayerComponentReducer.State
    }
    
    enum Action {
        case changeScreenType
        case screenLoaded
        case tryLoadBookAgain
        case downloadMetaData(Result<Metadata, Error>)
        case playerAction(BookPlayerComponentReducer.Action)
    }
    
    @Dependency(\.apiClient) var apiClient
    
    var body: some Reducer<State, Action> {
        Scope(state: \.playerState, action: \.playerAction) {
            BookPlayerComponentReducer()
        }
        Reduce { state, action in
            
            switch action {
            case .changeScreenType:
                state.isLyricsScreenMode.toggle()
                return .none
                
            case .screenLoaded, .tryLoadBookAgain:
                guard state.downloadMode == .notDownloaded || state.downloadMode == .downloadingFailed else {
                    return .none
                }
                
                state.downloadMode = .initialDownloading
                return .run { [url = state.metadataUrlString] send in
                    let metaData = try await apiClient.bookMetadata(url: url)
                    await send(.downloadMetaData(.success(metaData)))
                } catch: { error, send in
                    await send(.downloadMetaData(.failure(error)))
                }
                
            case .downloadMetaData(.success(let metaData)):
                state.coverImageUrl = URL.init(string: metaData.imageUrl)
                state.downloadMode = .downloaded
                state.keyPoints = metaData.keyPoints
                state.currentChapter = metaData.keyPoints.first
                state.downloadMode = .downloaded
                state.playerState.currentTrack = state.currentUrl
                state.chaptersCount = "KEY POINT 1 OF \(metaData.keyPoints.count)"
                return .none
   
            case .downloadMetaData(.failure):
                state.downloadMode = .downloadingFailed
                return .none
            
            case .playerAction(let playerAction):
                switch playerAction {
                case .nextTrack:
                    guard let chapter = state.currentChapter else {
                        state.currentChapter = state.keyPoints.first
                        return .none
                    }
                    
                    guard let previous = state.keyPoints.after(chapter) else {
                        return .send(.playerAction(.pause))
                    }
                    self.setState(for: previous, state: &state)
                    
                    return .send(.playerAction(.playFromStart))
                    
                case .previousTrack:
                    guard let chapter = state.currentChapter else {
                        state.currentChapter = state.keyPoints.first
                        return .none
                    }
                    guard let next = state.keyPoints.before(chapter) else {
                        return .send(.playerAction(.pause))
                    }
                    
                    self.setState(for: next, state: &state)
                    return .send(.playerAction(.playFromStart))
                    
                default:
                    break
                }

                return .none
            }
        }
    }
    
    private func setState(for item: Metadata.Chapter, state: inout State) {
        let index = state.keyPoints.firstIndex(of: item) ?? 0
        state.chaptersCount = "KEY POINT \(index + 1) OF \(state.keyPoints.count)"
        state.currentChapter = item
        state.playerState.currentTrack = state.currentUrl
    }
    
}

enum Mode: Equatable {
    case initialDownloading
    case downloading
    case downloaded
    case notDownloaded
    case downloadingFailed
}

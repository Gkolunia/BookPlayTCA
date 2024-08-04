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
        var downloadMode: Mode
        var coverImageUrl: URL?
        var keyPoints: [Metadata.Chapter] = []
        var isLyricsScreenMode: Bool
        
        var currentChapter: Metadata.Chapter?
        var chaptersCount: String { "KEY POINT 1 OF \(keyPoints.count)" }
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
                
            case .screenLoaded:
                guard state.downloadMode == .notDownloaded else { return .none }
                
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
                    state.currentChapter = state.keyPoints.after(chapter, loop: true)
                    state.playerState.currentTrack = state.currentUrl
                    
                    return BookPlayerComponentReducer().reduce(into: &state.playerState, action: .playFromStart)
                        .map(Action.playerAction)
                    
                    
                case .previousTrack:
                    guard let chapter = state.currentChapter else {
                        state.currentChapter = state.keyPoints.first
                        return .none
                    }
                    state.currentChapter = state.keyPoints.before(chapter, loop: true)
                    state.playerState.currentTrack = state.currentUrl
                    
                    return BookPlayerComponentReducer().reduce(into: &state.playerState, action: .playFromStart)
                        .map(Action.playerAction)
                    
                default:
                    break
                }

                return .none
            }
        }
    }
    
}

enum Mode: Equatable {
    case initialDownloading
    case downloading
    case downloaded
    case notDownloaded
    case downloadingFailed
}

//
//  BookPlayMain.swift
//  BookPlayTCA
//
//  Created by Mykola Hrybeniuk on 31.07.2024.
//

import AVFoundation
import ComposableArchitecture
import SwiftUI

@Reducer
struct BookPlayMainReducer {
    
    @ObservableState
    struct State: Equatable {
        let metadataUrlString: URL
        var downloadAlert: AlertState<DownloadComponent.Action.Alert>?
        var downloadMode: Mode
        var coverImageUrl: URL?
        var keyPoints: [Metadata.Chapter] = []
        var isLyrics: Bool
        
        var currentChapter: Metadata.Chapter?
        
        var chaptersCount: String  {
            return "KEY POINT 1 OF \(keyPoints.count)"
        }
        var currentUrl: URL? {
            guard let url = currentChapter?.fileUrl else {
                return nil
            }
            return URL(string: url)
        }
        var lyricsText: String {
            currentChapter?.text ?? ""
        }
        var chapterName: String {
            currentChapter?.title ?? ""
        }
    }
    
    enum Action {
        case changeScreenType
        case play
        case screenLoaded
        case downloadMetaData(Result<DownloadClient.Event, Error>)
        case nextChapter
        case previousChapter
    }
    
    @Dependency(\.downloadClient) var downloadClient
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            
            switch action {
            case .play:
                return .none
                
            case .changeScreenType:
                state.isLyrics.toggle()
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
                    state.downloadMode = .downloaded
                    state.keyPoints = metaData.keyPoints
                    state.currentChapter = metaData.keyPoints.first
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
            
            case .nextChapter:
                guard let chapter = state.currentChapter else {
                    state.currentChapter = state.keyPoints.first
                    return .none
                }
                state.currentChapter = state.keyPoints.after(chapter)
                
                return .none
            
            case .previousChapter:
                guard let chapter = state.currentChapter else {
                    state.currentChapter = state.keyPoints.first
                    return .none
                }
                state.currentChapter = state.keyPoints.before(chapter)
                
                return .none

            }
        }
    }
    
}



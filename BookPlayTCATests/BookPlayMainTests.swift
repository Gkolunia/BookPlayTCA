//
//  BookPlayMainTests.swift
//  BookPlayTCATests
//
//  Created by Mykola Hrybeniuk on 05.08.2024.
//

import ComposableArchitecture
import XCTest
@testable import BookPlayTCA

final class BookPlayMainTests: XCTestCase {
    
    @MainActor
    func testBasics() async {
        let state = BookPlayMainReducer.State.init(metadataUrlString: "MetadataUrl", playerState: .init())
        
        let store = TestStore(initialState: state) {
            BookPlayMainReducer()
        }
        
        await store.send(.changeScreenType) {
            $0.isLyricsScreenMode = true
        }
        
        await store.send(.screenLoaded) {
            $0.downloadMode = .initialDownloading
        }
        
        await store.receive(\.downloadMetaData) {
            $0.downloadMode = .downloaded
            $0.keyPoints = Metadata.mock.keyPoints
            $0.coverImageUrl = URL(string: Metadata.mock.imageUrl)
            let currentChapter = Metadata.mock.keyPoints.first!
            $0.currentChapter = currentChapter
            $0.playerState.currentTrack = URL(string: currentChapter.fileUrl)
            $0.chaptersCount = "KEY POINT 1 OF 2"
        }
    }
    
    @MainActor
    func testSelectingChapter() async {
        let clock = TestClock()
        let currentChapter = Metadata.mock.keyPoints.first!
        let state = BookPlayMainReducer.State.init(metadataUrlString: "url",
                                                   downloadMode: .downloaded,
                                                   coverImageUrl: nil,
                                                   keyPoints: Metadata.mock.keyPoints,
                                                   isLyricsScreenMode: false,
                                                   currentChapter: currentChapter,
                                                   playerState: .init(currentTrack: URL(string: currentChapter.fileUrl)))
        
        let store = TestStore(initialState: state) {
            BookPlayMainReducer()
        } withDependencies: {
            $0.continuousClock = clock
        }
        
        await store.send(.playerAction(.nextTrack)) {
            let currentChapter = Metadata.mock.keyPoints.last!
            $0.currentChapter = currentChapter
            $0.playerState.isLoadingTrackInfo = false
            $0.playerState.currentTrack = URL(string: currentChapter.fileUrl)
            $0.chaptersCount = "KEY POINT 2 OF 2"
        }
        
        await store.receive(\.playerAction.playFromStart) {
            $0.playerState.isPlaying = true
        }
        
        await store.receive(\.playerAction.loadTrackInfo) {
            $0.playerState.isLoadingTrackInfo = true
        }
        
        await store.receive(\.playerAction.totalTime) {
            $0.playerState.isLoadingTrackInfo = false
        }
        
        await clock.advance(by: .seconds(1))
        await store.receive(\.playerAction.tick)
        await store.receive(\.playerAction.nextTrack)
        await store.receive(\.playerAction.pause) {
            $0.playerState.isPlaying = false
        }
        
        await store.finish()
    }
    
}

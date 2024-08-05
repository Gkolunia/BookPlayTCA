//
//  BookPlayerComponentTests.swift
//  BookPlayTCATests
//
//  Created by Mykola Hrybeniuk on 05.08.2024.
//

import ComposableArchitecture
import XCTest
@testable import BookPlayTCA

final class BookPlayerComponentTests: XCTestCase {

    @MainActor
    func testPlayer() async {
        let clock = TestClock()
        let state = BookPlayerComponentReducer.State.init(currentTrack: URL(string: "TrackUrl"))
        
        let store = TestStore(initialState: state) {
            BookPlayerComponentReducer()
        }  withDependencies: {
            $0.continuousClock = clock
        }
        
        await store.send(.viewOnAppear)
        
        await store.receive(\.playPauseTapped) {
            $0.isPlaying = true
        }
        
        await store.receive(\.loadTrackInfo) {
            $0.isLoadingTrackInfo = true
        }
        
        await store.receive(\.totalTime) {
            $0.isLoadingTrackInfo = false
        }
        
        await store.send(.pause) {
            $0.isPlaying = false
        }
        
        await store.finish()
    }
    
}

//
//  BookPlayerComponentReducer.swift
//  BookPlayTCA
//
//  Created by Mykola Hrybeniuk on 04.08.2024.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct BookPlayerComponentReducer {
    
    @ObservableState
    struct State: Equatable {
        let id: AnyHashable
        var currentTime: Double = 0.0
        var speed: Int = 1
        var totalTime: Double = 0.0
        var isPlaying: Bool = false
        var showLyrics: Bool = false
        var currentTrackIndex: Int = 0
        var currentTrack: URL?
        var isLoadingTrackInfo: Bool = false
        var totalTimeString: String { format(time: totalTime) }
        var currentTimeString: String { format(time: currentTime) }
        
        private func format(time: Double) -> String {
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.hour, .minute, .second]
            formatter.unitsStyle = .positional
            if let str = formatter.string(from: time) {
                return str
            }
            return ""
        }
    }
    
    enum Action: Equatable {
        case viewOnAppear
        case playPauseTapped
        case playFromStart
        case seek(Double)
        case jumpBackward
        case jumpForward
        case previousTrack
        case nextTrack
        case toggleCoverLyrics
        case totalTime(Double)
        case currentTime(Double)
        case loadTrackInfo
        case changeSpeed
        case tick
    }
    
    @Dependency(\.playerClient) var playerClient
    @Dependency(\.continuousClock) var clock
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
            case .viewOnAppear:
                guard state.currentTrack != nil else { return .none }
                
                return .run { send in
                    await send(.playPauseTapped)
                    await send(.loadTrackInfo)
                }
                
            case .playPauseTapped:
                state.isPlaying.toggle()
                
                if !state.isPlaying {
                    playerClient.pause()
                    return .cancel(id: state.id)
                }
                
                guard let item = state.currentTrack else { return .none }
                
                isUrlAlreadyPlaying(urlTrack: item) ? playerClient.playCurrent() : playerClient.play(url: item)
                
                return .run { send in
                    for await _ in self.clock.timer(interval: .seconds(1)) {
                        await send(.tick)
                    }
                }
                .cancellable(id: state.id)
            
            case .playFromStart:
                guard let item = state.currentTrack else { return .none }
                
                state.currentTime = 0.0
                playerClient.play(url: item)
                
                return .run { send in
                    await send(.loadTrackInfo)
                    for await _ in self.clock.timer(interval: .seconds(1)) {
                        await send(.tick)
                    }
                }
                .cancellable(id: state.id)

            case .seek(let time):
                playerClient.setCurrentTime(time: time)
                state.currentTime = min(max(time, 0), state.totalTime)
                return .none
                
            case .jumpBackward:
                state.currentTime = max(state.currentTime - 5, 0)
                playerClient.setCurrentTime(time: state.currentTime)
                return .none
                
            case .jumpForward:
                state.currentTime = min(state.currentTime + 10, state.totalTime)
                playerClient.setCurrentTime(time: state.currentTime)
                return .none
                
            case .previousTrack, .nextTrack:
                if state.isPlaying {
                    playerClient.pause()
                    return .cancel(id: state.id)
                }
                return .none
                
            case .toggleCoverLyrics:
                state.showLyrics.toggle()
                return .none
                
            case .totalTime(let duration):
                state.totalTime = duration
                state.isLoadingTrackInfo = false
                return .none
                
            case .loadTrackInfo:
                state.isLoadingTrackInfo = true
                return .run { send in
                    await send(.totalTime( (try? playerClient.duration()) ?? 0.0 ))
                }
                
            case .currentTime(let currentTime):
                state.currentTime = currentTime
                return .none
                
            case .changeSpeed:
                state.speed = state.speed + 1 > 3 ? 1 : state.speed + 1
                playerClient.changeSpeed(rate: state.speed)
                return .none
                
            case .tick:
                state.currentTime = playerClient.currentTime
                if state.currentTime >= state.totalTime {
                    _ = Effect<BookPlayerComponentReducer.Action>.cancel(id: state.id)
                    return .run { send in
                        await send(.nextTrack)
                    }
                }
                
                return .none
            }
        }
        
    }
    
    private func isUrlAlreadyPlaying(urlTrack: URL) -> Bool {
        playerClient.urlOfCurrentlyPlayingInPlayer() == urlTrack
    }
    
}

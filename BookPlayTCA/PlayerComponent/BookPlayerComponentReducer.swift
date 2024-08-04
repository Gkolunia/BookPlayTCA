//
//  BookPlayerComponentReducer.swift
//  BookPlayTCA
//
//  Created by Mykola Hrybeniuk on 04.08.2024.
//

import SwiftUI
import ComposableArchitecture
import AVFoundation

@Reducer
struct BookPlayerComponentReducer {
    
    @ObservableState
    struct State: Equatable {
        var currentTime: Double = 0.0
        var speed: Int = 1
        var totalTime: Double = 300.0
        var isPlaying: Bool = false
        var showLyrics: Bool = false
        var currentTrackIndex: Int = 0
        var currentTrack: AVPlayerItem?
        var isLoadingTrackInfo: Bool = false
        
        var totalTimeString: String {
            format(time: totalTime)
        }
        
        var currentTimeString: String {
            format(time: currentTime)
        }
        
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
        case playPauseTapped
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
    }
    
    let nextTrackHandler: () -> ()
    let previousTrackHandler: () -> ()
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .playPauseTapped:
                state.isPlaying.toggle()
                return .none
            case .seek(let time):
                state.currentTrack?.seek(to: .init(seconds: time, preferredTimescale: 2), completionHandler: nil)
                state.currentTime = min(max(time, 0), state.totalTime)
                return .none
            case .jumpBackward:
                state.currentTime = max(state.currentTime - 5, 0)
                state.currentTrack?.seek(to: .init(seconds: state.currentTime, preferredTimescale: 2), completionHandler: nil)
                return .none
            case .jumpForward:
                state.currentTime = min(state.currentTime + 10, state.totalTime)
                state.currentTrack?.seek(to: .init(seconds: state.currentTime, preferredTimescale: 2), completionHandler: nil)
                return .none
                
            case .previousTrack:
                previousTrackHandler()
//                state.currentTime = 0
                return .none
                
            case .nextTrack:
                nextTrackHandler()
//                state.currentTime = 0
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
                return .run { [track = state.currentTrack] send in
                    await send(.totalTime((try? track?.asset.load(.duration).seconds) ?? 0.0))
                }
            case .currentTime(let currentTime):
                state.currentTime = currentTime
                return .none
            case .changeSpeed:
                state.speed = state.speed + 1 > 3 ? 1 : state.speed + 1
                
                return .none
            }
        }
        
    }
    
}

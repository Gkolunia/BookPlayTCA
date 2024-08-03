//
//  BookPlayerComponent.swift
//  BookPlayTCA
//
//  Created by Mykola Hrybeniuk on 02.08.2024.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct BookPlayerComponent {
    
    @ObservableState
    struct State: Equatable {
        var currentTime: Double = 0.0
        var totalTime: Double = 300.0
        var isPlaying: Bool = false
        var showLyrics: Bool = false
        var currentTrackIndex: Int = 0
        var tracks: [String] = ["Track 1", "Track 2", "Track 3"]
    }
    
    enum Action: Equatable {
        case playPauseTapped
        case seek(Double)
        case jumpBackward
        case jumpForward
        case previousTrack
        case nextTrack
        case toggleCoverLyrics
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .playPauseTapped:        
                state.isPlaying.toggle()
                return .none
            case .seek(let time):        
                state.currentTime = min(max(time, 0), state.totalTime)
                return .none
            case .jumpBackward:        
                state.currentTime = max(state.currentTime - 10, 0)
                return .none
            case .jumpForward:        
                state.currentTime = min(state.currentTime + 10, state.totalTime)
                return .none
            case .previousTrack:        
                state.currentTrackIndex = max(state.currentTrackIndex - 1, 0)
                state.currentTime = 0
                return .none
            case .nextTrack:
                state.currentTrackIndex = min(state.currentTrackIndex + 1, state.tracks.count - 1)
                state.currentTime = 0
                return .none
            case .toggleCoverLyrics:        
                state.showLyrics.toggle()
                return .none
            }
        }
        
    }
    
}


struct BookPlayerComponentView: View {
    let store: StoreOf<BookPlayerComponent>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                if viewStore.showLyrics {
                    Text("Lyrics view")
                } else {
                    Text("Cover view")
                }
                
                Slider(
                    value: viewStore.binding(
                        get: \.currentTime,
                        send: BookPlayerComponent.Action.seek
                    ),
                    in: 0...viewStore.totalTime
                )
                .padding()
                
                
                HStack {
                    Button(action: { viewStore.send(.previousTrack) }) {
                        playerImageControl(imageWithName: "backward.end.fill")
                    }
                    
                    Button(action: { viewStore.send(.jumpBackward) }) {
                        playerImageControl(imageWithName: "gobackward.5")
                    }
                    
                    Button(action: { viewStore.send(.playPauseTapped) }) {
                        playerImageControl(imageWithName: viewStore.isPlaying ? "pause.fill" : "play.fill")
                    }
                    
                    Button(action: { viewStore.send(.jumpForward) }) {
                        playerImageControl(imageWithName: "goforward.10")
                    }
                    
                    Button(action: { viewStore.send(.nextTrack) }) {
                        playerImageControl(imageWithName: "forward.end.fill")
                    }
                }
                .padding()
                
                Button(action: { viewStore.send(.toggleCoverLyrics) }) {
                    Text(viewStore.showLyrics ? "Show Cover" : "Show Lyrics")
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder private func playerImageControl(imageWithName: String) -> some View {
        Image(systemName: imageWithName)
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(.black)
            .frame(width: 30, height: 30, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
            .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/, /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
    }
    
}


#Preview {
    BookPlayerComponentView(store: .init(initialState: .init(), reducer: {}))
}

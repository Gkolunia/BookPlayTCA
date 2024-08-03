//
//  BookPlayerComponent.swift
//  BookPlayTCA
//
//  Created by Mykola Hrybeniuk on 02.08.2024.
//

import SwiftUI
import ComposableArchitecture
import AVFoundation

@Reducer
struct BookPlayerComponent {
    
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

struct BookPlayerComponentView: View {
    @State var audioPlayer: AVPlayer = AVPlayer()
    @State var timeObserver: Any?
    let store: StoreOf<BookPlayerComponent>
    
    var pub = NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                HStack(content: {
                    Text(viewStore.currentTimeString)
                    Slider(
                        value: viewStore.binding(
                            get: \.currentTime,
                            send: BookPlayerComponent.Action.seek
                        ),
                        in: 0...viewStore.totalTime
                    )
                    .padding()
                    
                    if viewStore.isLoadingTrackInfo {
                        ProgressView()
                            .frame(width: 6, height: 6)
                    } else {
                        Text(viewStore.totalTimeString)
                    }
                })
                
                Button(action: {
                    viewStore.send(.changeSpeed)
                }, label: {
                    Text("Speed x" + String(viewStore.speed))
                })
                
                HStack {
                    Button(action: { viewStore.send(.previousTrack) }) {
                        playerImageControl(imageWithName: "backward.end.fill")
                    }
                    
                    Button(action: { viewStore.send(.jumpBackward) }) {
                        playerImageControl(imageWithName: "gobackward.5")
                    }
                    
                    Button(action: { 
                        viewStore.send(.playPauseTapped)
                        
                        if viewStore.isPlaying {
                            self.audioPlayer.play()
                        } else {
                            self.audioPlayer.pause()
                        }
                        
                    }) {
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
            }
            .padding()
            .onAppear(perform: {
                guard let item = viewStore.currentTrack else {
                    return
                }
                self.audioPlayer = AVPlayer(playerItem: item)
                viewStore.send(.loadTrackInfo)
                
                let interval = CMTime(value: 1, timescale: 2)
                self.timeObserver = audioPlayer.addPeriodicTimeObserver(forInterval: interval,
                                                                  queue: .main) { time in
                    viewStore.send(.currentTime(time.seconds))
                }
            })
            .onReceive(pub) { (output) in
                viewStore.send(.playPauseTapped)
                viewStore.send(.currentTime(0))
            }
            .onChange(of: store.state.speed) { oldValue, newValue in
                audioPlayer.rate = Float(newValue)
            }
            .onChange(of: store.state.currentTrack) { oldValue, newValue in
                guard let item = newValue else {
                    return
                }
                
                
                
                self.audioPlayer.replaceCurrentItem(with: item)
                viewStore.send(.loadTrackInfo)
                
                guard let observer = timeObserver else {
                    return
                }
                self.audioPlayer.removeTimeObserver(observer)
                
                let interval = CMTime(value: 1, timescale: 2)
                self.timeObserver = audioPlayer.addPeriodicTimeObserver(forInterval: interval,
                                                                  queue: .main) { time in
                    viewStore.send(.currentTime(time.seconds))
                }
            }
            
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

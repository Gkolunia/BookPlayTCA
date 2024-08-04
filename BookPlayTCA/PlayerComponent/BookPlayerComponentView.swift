//
//  BookPlayerComponent.swift
//  BookPlayTCA
//
//  Created by Mykola Hrybeniuk on 02.08.2024.
//

import SwiftUI
import ComposableArchitecture
import AVFoundation

struct BookPlayerComponentView: View {
    @State var audioPlayer: AVPlayer = AVPlayer()
    @State var timeObserver: Any?
    let store: StoreOf<BookPlayerComponentReducer>
    
    var pub = NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                HStack(content: {
                    Text(viewStore.currentTimeString)
                    Slider(
                        value: viewStore.binding(
                            get: \.currentTime,
                            send: BookPlayerComponentReducer.Action.seek
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

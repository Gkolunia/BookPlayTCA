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
    
    let store: StoreOf<BookPlayerComponentReducer>
    
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
                viewStore.send(.viewOnAppear)
            })
            
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
    BookPlayerComponentView(store: .init(initialState: .init(id: UUID()), reducer: {}))
}

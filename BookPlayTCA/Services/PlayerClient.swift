//
//  PlayerClient.swift
//  BookPlayTCA
//
//  Created by Mykola Hrybeniuk on 04.08.2024.
//

import AVFoundation
import ComposableArchitecture

@DependencyClient
struct PlayerClient {
    
    private let audioPlayer: AVPlayer = AVPlayer()
    
    var currentTime: Double {
        return audioPlayer.currentTime().seconds
    }
    
    func play(url: URL) {
        audioPlayer.replaceCurrentItem(with: .init(url: url))
        audioPlayer.play()
    }
    
    func playCurrent() {
        audioPlayer.play()
    }
    
    func pause() {
        audioPlayer.pause()
    }
    
    func setCurrentTime(time: Double) {
        audioPlayer.currentItem?.seek(to: .init(seconds: time, preferredTimescale: 2), completionHandler: nil)
    }
    
    func duration() async throws -> Double {
        return try await audioPlayer.currentItem?.asset.load(.duration).seconds ?? 0.0
    }
    
    func changeSpeed(rate: Int) {
        audioPlayer.rate = Float(rate)
    }
    
    func urlOfCurrentlyPlayingInPlayer() -> URL? {
        ((audioPlayer.currentItem?.asset) as? AVURLAsset)?.url
    }
}

extension PlayerClient: TestDependencyKey {
//  static let previewValue = Self( bookMetadata: { _ in .mock } )
  static let testValue = Self()
}

extension DependencyValues {
  var playerClient: PlayerClient {
    get { self[PlayerClient.self] }
    set { self[PlayerClient.self] = newValue }
  }
}

extension PlayerClient: DependencyKey {
    static let liveValue = PlayerClient()
}

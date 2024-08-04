//
//  Metadata.swift
//  BookPlayTCA
//
//  Created by Mykola Hrybeniuk on 04.08.2024.
//

import Foundation

struct Metadata: Codable, Equatable {
    struct Chapter: Codable, Equatable {
        let title: String
        let fileUrl: String
        let text: String
    }
    
    let bookName: String
    let imageUrl: String
    let keyPoints: [Chapter]
}

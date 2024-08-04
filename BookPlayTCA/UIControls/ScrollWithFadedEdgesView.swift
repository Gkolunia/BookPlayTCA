//
//  ScrollWithFadedEdgesView.swift
//  BookPlayTCA
//
//  Created by Mykola Hrybeniuk on 04.08.2024.
//

import SwiftUI

struct ScrollWithFadedEdgesView: View {
    
    let text: String

    var body: some View {
        ZStack(content: {
            ScrollView {
                Text(text)
                    .font(.system(size: 22))
            }
            .contentMargins(.all, 20.0, for: .scrollContent)
            
            VStack(content: {
                Rectangle()
                    .fill(
                        LinearGradient(gradient: Gradient(colors: [.white, .clear]), startPoint: .top, endPoint: .bottom)
                    )
                    .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, maxHeight: 50)
                Spacer()
                Rectangle()
                    .fill(
                        LinearGradient(gradient: Gradient(colors: [.white, .clear]), startPoint: .bottom, endPoint: .top)
                    )
                    .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, maxHeight: 50)
            })
        })
    }
}

#Preview {
    ScrollWithFadedEdgesView(text: "1234")
}

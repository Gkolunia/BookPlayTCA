//
//  File.swift
//  BookPlayTCA
//
//  Created by Mykola Hrybeniuk on 03.08.2024.
//

import SwiftUI

struct ToggleButton: View {
    
    @Binding var isRightSelected: Bool
    @State var leftIcon: String
    @State var rightIcon: String
    
    
    var body: some View {
            ZStack{
                Capsule()
                    .fill(.white)
                    .stroke(.gray.opacity(0.4), lineWidth: 1)
                    .frame(width: 106, height: 52)
                HStack{
                    ZStack{
                        Capsule()
                            .fill(.blue)
                            .frame(width: 44, height: 44)
                            .offset(x: isRightSelected ? 50 : 0)
                            .animation(/*@START_MENU_TOKEN@*/.easeIn/*@END_MENU_TOKEN@*/, value: 0.5)
                        
                        Image(systemName: leftIcon)
                            .renderingMode(.template)
                            .foregroundStyle( isRightSelected ? Color.black : Color.white)
                    }
                    ZStack{
                        Image(systemName: rightIcon)
                            .renderingMode(.template)
                            .frame(width: 44, height: 44)
                            .foregroundStyle( isRightSelected ? Color.white : Color.black)
                    }
                }
            }
            .onTapGesture {
                isRightSelected.toggle()
            }
    }
}

#Preview {
    ToggleButton(isRightSelected: .constant(false), leftIcon: "headphones", rightIcon: "text.alignleft")
}

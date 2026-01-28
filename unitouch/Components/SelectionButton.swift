//
//  SelectionButton.swift
//  unitouch
//
//  Created by Tijn Giesberts on 3/5/25.
//

import SwiftUI

struct SelectionButton: View {
    @State private var longPressed = false
    var text: String
    var width: CGFloat
    var height: CGFloat
    var action1: (() -> Void)? = nil
    var action2: (() -> Void)? = nil
    
    // Custom init for size
    init(text: String, size: CGFloat, action2: (() -> Void)? = nil, action1: (() -> Void)? = nil) {
        self.text = text
        self.width = size
        self.height = size
        self.action1 = action1
        self.action2 = action2
    }

    // Default memberwise initializer remains available
    init(text: String, width: CGFloat, height: CGFloat, action2: (() -> Void)? = nil, action1: (() -> Void)? = nil) {
        self.text = text
        self.width = width
        self.height = height
        self.action1 = action1
        self.action2 = action2
    }

    var body: some View {
        ZStack {
            Text(text)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .foregroundColor(.black)
                .font(.title2)
        }
        .frame(width: width, height: height)
        .background(text == "" ? Color.black : Color.white)
        .cornerRadius(8)
        .shadow(radius: 2)
        .highPriorityGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    print("Long pressed")
                    longPressed = true
                    action2?()
                }
        )
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    if !longPressed {
                        print("Short pressed")
                        action1?()
                    }
                    longPressed = false
                }
        )
    }
}

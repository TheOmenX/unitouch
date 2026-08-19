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
    var disabled: Bool = false
    var action1: (() -> Void)? = nil
    var action2: (() -> Void)? = nil
    
    // Custom init for size
    init(text: String, size: CGFloat, disabled: Bool = false, action2: (() -> Void)? = nil, action1: (() -> Void)? = nil) {
        self.text = text
        self.width = size
        self.height = size
        self.disabled = disabled
        self.action1 = action1
        self.action2 = action2
    }

    // Default memberwise initializer remains available
    init(text: String, width: CGFloat, height: CGFloat, disabled: Bool = false, action2: (() -> Void)? = nil, action1: (() -> Void)? = nil) {
        self.text = text
        self.width = width
        self.height = height
        self.disabled = disabled
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
        .background(text == "" ? Color.black : (self.disabled ? Color.gray : Color.white) )
        .cornerRadius(8)
        .shadow(radius: 2)
        .highPriorityGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    if !disabled {
                        longPressed = true
                        action2?()
                    }
                }
        )
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    if !disabled {
                        if !longPressed {
                            action1?()
                        }
                        longPressed = false
                    }
                }
        )
    }
}

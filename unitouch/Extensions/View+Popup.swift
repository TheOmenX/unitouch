//
//  View+Popup.swift
//  unitouch
//
//  Created by Tijn Giesberts on 31/03/2026.
//

import Foundation
import SwiftUI

// 1. Define the custom modifier
struct CustomPopupModifier<PopupContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    
    // @ViewBuilder allows us to pass in dynamic UI elements easily
    @ViewBuilder let popupContent: () -> PopupContent
    
    func body(content: Content) -> some View {
        ZStack {
            // The original, underlying view
            content
            
            if isPresented {
                // 2. The tinted, unclickable background
                Color.black
                    .opacity(0.5)
                    .ignoresSafeArea()
                    // Optional: If you want tapping the background to dismiss the popup,
                    // uncomment the line below. Otherwise, it just blocks touches.
                    // .onTapGesture { isPresented = false }
                    .transition(.opacity)
                    .zIndex(1)
                
                // 3. The dynamic popup content in the center
                popupContent()
                    // Your custom color scale background
                    .background(Color.background[800])
                    // Round the corners of the background box
                    .cornerRadius(20)
                    // Optional: A shadow to lift it off the dark overlay
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    // Outer padding to ensure the box never touches the phone screen edges
                    .padding(.horizontal, 12)
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(2)
            }
        }
        // Animate the presentation and dismissal
        .animation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0), value: isPresented)
    }
}

extension View {
    func popup<PopupContent: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> PopupContent
    ) -> some View {
        self.modifier(CustomPopupModifier(isPresented: isPresented, popupContent: content))
    }
}

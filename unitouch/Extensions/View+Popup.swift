//
//  View+Popup.swift
//  unitouch
//
//  Created by Tijn Giesberts on 31/03/2026.
//

import Foundation
import SwiftUI

// MARK: - 1. Boolean-based Modifier (Your original)
struct CustomPopupModifier<PopupContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    @ViewBuilder let popupContent: () -> PopupContent
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented {
                Color.black.opacity(0.5).ignoresSafeArea().transition(.opacity).zIndex(1)
                
                popupContent()
                    .background(Color.background[800])
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 12)
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(2)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0), value: isPresented)
    }
}

// MARK: - 2. Item-based Modifier (New)
struct CustomItemPopupModifier<Item, PopupContent: View>: ViewModifier {
    @Binding var item: Item?
    @ViewBuilder let popupContent: (Item) -> PopupContent
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            // Check if the item is not nil and unwrap it
            if let unwrappedItem = item {
                Color.black.opacity(0.5).ignoresSafeArea().transition(.opacity).zIndex(1)
                    // Optional: Tap background to dismiss (set item to nil)
                    // .onTapGesture { item = nil }
                
                // Pass the unwrapped item into the content closure
                popupContent(unwrappedItem)
                    .background(Color.background[800])
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 12)
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(2)
            }
        }
        // Animate based on whether the item exists or not
        .animation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0), value: item != nil)
    }
}

// MARK: - View Extensions
extension View {
    // Standard Boolean Popup
    func popup<PopupContent: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> PopupContent
    ) -> some View {
        self.modifier(CustomPopupModifier(isPresented: isPresented, popupContent: content))
    }
    
    // Item-based Popup
    func popup<Item, PopupContent: View>(
        item: Binding<Item?>,
        @ViewBuilder content: @escaping (Item) -> PopupContent
    ) -> some View {
        self.modifier(CustomItemPopupModifier(item: item, popupContent: content))
    }
}

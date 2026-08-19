//
//  LoadingView.swift
//  unitouch
//
//  Created by Tijn Giesberts on 21/05/2025.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack{
            Color.black.opacity(0.3) // Semi-transparent background
                .edgesIgnoringSafeArea(.all) // Make sure it covers full screen
            
            ProgressView("Loading...") // Centered loader
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(2) // Make the spinner larger
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

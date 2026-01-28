//
//  ConnectedSymbol.swift
//  unitouch
//
//  Created by Tijn Giesberts on 12/06/2025.
//

import SwiftUI

struct ConnectedSymbol: View {
    @State private var wifiStrength: Double = 0.25
    @Bindable var backendManager = BackendManager.shared
    @State private var timer: Timer? = nil
    @State private var wifiColor = Color.orange

    var body: some View {
        VStack(spacing: 20) {
            Image("ConnectedSymbol", variableValue: wifiStrength)
                .font(.system(size: 150))
                .symbolRenderingMode(.palette)
                .foregroundStyle(wifiColor, .white)
                .padding()
                .symbolEffect(.bounce, value: backendManager.connectionState)
                .onAppear { startTimer(); self.setInfo(); }
                .onDisappear { stopTimer() }
                .onChange(of: backendManager.connectionState) { self.setInfo() }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        
        ZStack{
            if (backendManager.connectionState != .reconnecting) {
                Button("Reconnect") {
                    backendManager.retries = 0
                    backendManager.reconnect()
                }
                .padding()
                .background(Color.blue)
                .background(Color.white)
                .clipShape(Capsule())
            }
        }.frame(height: 50)
    }

    private func setInfo(){
        if backendManager.connectionState == .ready {
            wifiColor = Color.green
            wifiStrength = 1.0
            stopTimer()
        } else if backendManager.connectionState == .reconnecting {
            wifiStrength = 0.0
            wifiColor = Color.orange
            startTimer()
        } else {
            wifiStrength = 0.0
            wifiColor = Color.red
            stopTimer()
        }
    }
    
    private func startTimer() {
        // Ensure the timer is not already running
        guard timer == nil else { return }

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            withAnimation {
                // Cycle through the strength values
                wifiStrength = (wifiStrength + 0.25).truncatingRemainder(dividingBy: 1.0)
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

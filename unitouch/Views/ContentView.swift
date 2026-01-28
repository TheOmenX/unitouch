//
//  ContentView.swift
//  unitouch
//
//  Created by Tijn Giesberts on 29/4/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Bindable var backendManager = BackendManager.shared
    @Environment(\.scenePhase) var scenePhase
    
    @Environment(\.modelContext) var modelContext
    @Query var backendData: [BackendData]
    
    var body: some View {
        VStack{
            ZStack{
                switch(backendManager.appState) {
                case .setup:
                    LoadingView()
                case .tableOpen:
                    TableView()
                case .payment:
                    PaymentView()
                case .splitTable:
                    SplitTableView()
                case .login:
                    LoginView()
                default:
                    SelectionView()
                }
            }
        }
        .fullScreenCover(isPresented: .constant(backendManager.connectionState != .ready && backendManager.retries > 1) ) {
            ConnectedSymbol()
        }
        .onAppear {
            backendManager.setModelContext(modelContext)
            if backendData.count > 0 {
                backendManager.loadBackendData(backendData.first ?? BackendData())
                print(backendData.first!.timestamp)
                
                //Delete all backedData except the first one
                for data in backendData.dropFirst() {
                    modelContext.delete(data)
                }
            }
        }
        .alert(item: $backendManager.statusError) { error in
            switch(error){
            case .tableNotEmpty(let action):
                return Alert(
                    title: Text("Verplaatsen"),
                    message: Text(error.message),
                    primaryButton: .default(Text("Annuleren")),
                    secondaryButton: .default(Text("Doorgaan"), action: {action?()})
                )
            default:
                return Alert(
                    title: Text(error.id),
                    message: Text(error.message),
                    dismissButton: .default(Text("Ok"))
                )
            }
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active && backendManager.connectionState == .lost {
                print("Scene became active, reconnecting...")
                
                backendManager.reconnect()
            }
        }
        .onOpenURL {url in
            print(url.absoluteString)
            guard
                url.host() == "result",
                let params = url.queryParameters,
                let result = params.first(where: { key, value in key == "status" })?.value,
                let message = params.first(where: {key, _ in key == "message"})?.value
            else {
                //backendManager.paymentStatus = .invalidReturn;
                return
            }
            
            if result == "failure" {
                print("Transaction failed")
                Task { @MainActor in
                    backendManager.statusError = .unknown(err: message.removingPercentEncoding ?? "")
                }
            }else {
                Task { @MainActor in
                    backendManager.vivaPaymentReceived = true
                }
            }
        }
    }
}


#Preview {
    ContentView()
}

//
//  ContentView.swift
//  unitouch
//
//  Created by Tijn Giesberts on 29/4/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject var session = SessionManager()
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.modelContext) var modelContext
    @Query var backendData: [BackendData]
    
    var body: some View {
        VStack{
            ZStack{
                switch(session.state) {
                case .disconnected:
                    HStack{
                        Text("Disconnected")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .loading:
                    LoadingView()
                case .order:
                    TableView(session: session)
//                case .payment:
//                    PaymentView()
                case .splitSelection(let table, let nextState):
                    SplitTableView(session: session, nextState: nextState, table: table)
                case .userSelection:
                    LoginView(
                        users: session.backendData.users,
                        onSelect: { user in
                            session.setUsers(user: user)
                        }, onFail: {
                            session.activeError = .invalidPassword
                        })
                case .main:
                    SelectionView(session: session)
                default:
                    LoadingView()
                }
            }
        }
        .alert(item: $session.activeError) { errorInfo in
            Alert(
                title: Text("Er ging iets mis"),
                message: Text(errorInfo.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .task {
            await session.verifyData(modelContext: modelContext, backendData: backendData.first ?? BackendData())
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
                    //backendManager.statusError = .unknown(err: message.removingPercentEncoding ?? "")
                }
            }else {
                Task { @MainActor in
                    //backendManager.vivaPaymentReceived = true
                }
            }
        }
    }
}


#Preview {
    ContentView()
}

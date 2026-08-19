//
//  ContentView.swift
//  unitouch
//
//  Created by Tijn Giesberts on 29/4/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var store: RestaurantStore
    
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.modelContext) var modelContext
    @Query var payments: [Payment]
    
    @State private var showVivaWalletPopup: (Double, Double)? = nil
    
    var body: some View {
        VStack{
            ZStack{
                switch(router.state) {
                case .login:
                    LoginView(users: store.users)
                case .main:
                    SelectionView(payments: payments)
                case .order(let tableID, let subTableIndex):
                    TableView(tableID: tableID, subTableIndex: subTableIndex)
                default:
                    EmptyView()
                }
            }
            .background(Color.background[900])
            .ignoresSafeArea(.container, edges: .bottom)
            .popup(item: $router.activeError) { item in
                ErrorPopup(error: item, close: {
                    router.activeError = nil
                })
            }
            .popup(item: $showVivaWalletPopup) { item in
                PaymentComplete(amount: item.0, tip: item.1, close: {
                    self.showVivaWalletPopup = nil
                })
            }
            .onOpenURL {url in
                handleVivaWalletCallback(url: url)
            }
        }
        .onAppear {
            Task {
                await initialDataSync()
            }
        }
    }
    
    // MARK: - Initial Sync Logic
    private func initialDataSync() async {
        router.showLoading("Syncing Data...")
        do {
            let data = try await NetworkService.shared.syncData()
            router.hideLoading()
            store.backendData = data
            router.navigate(to: .login)
        } catch {
            router.hideLoading()
            router.showError(.dataSyncFailed(details: error.localizedDescription))
            router.navigate(to: .disconnected)
        }
    }
    
    // MARK: - Deep Link Logic
    private func handleVivaWalletCallback(url: URL) {
        guard
            url.host() == "result",
            let params = url.queryParameters,
            let result = params.first(where: { key, value in key == "status" })?.value,
            let message = params.first(where: {key, _ in key == "message"})?.value
        else {
            router.activeError = .invalidVivaWalletURL
            return
        }
            
        if result == "failure" {
            let errorCode = params.first { $0.key == "errorCode" }?.value
            if errorCode != "1000" {
                let errorMessage = message.removingPercentEncoding ?? "Onbekende fout"
                router.activeError = .vivaPaymentProcessingError(details: errorMessage)
            }
        }else if result == "success" {
            guard
                let merchantReference = params.first(where: {key, _ in key == "merchantReference"})?.value,
                let userIdRaw = merchantReference.components(separatedBy: "-").first,
                let userId = Int(userIdRaw),
                let userName = merchantReference.components(separatedBy: "-").dropFirst().first,
                let tableFlat = merchantReference.components(separatedBy: "-").dropFirst(2).first,
//                        let table = TableInfo(flatTable: tableFlat),
                let amountRaw = params.first(where: {key, _ in key == "amount"})?.value,
                let tipAmountRaw = params.first(where: {key, _ in key == "tipAmount"})?.value,
                let amount = Double(amountRaw),
                let tipAmount = Double(tipAmountRaw)
            else {
                router.activeError = .invalidVivaWalletURL
                return
            }
            
//                    if let currentUser = session.currentUser {
//                        session.setUsers(user: currentUser, setState: false)
//                    }else {
//                        let recentUser = DataManager.shared.load(forKey: "recentUser", as: UnitouchUser.self)
//                        if let recentUser = recentUser {
//                            session.setUsers(user: recentUser, setState: false)
//                        }
//                    }
//                    session.finishVivaPayment(table: table, amount: amount/100, tipAmount: tipAmount/100, userId: userId, userName: userName, modelContext: modelContext)
//                    self.showVivaWalletPopup = (amount/100, tipAmount/100)
            
        }
    }
}

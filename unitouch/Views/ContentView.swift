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
    @Query var payments: [Payment]
    
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
                case .splitTable:
                    SplitTableView(session: session)
                case .payment(let balance, let bill):
                    PaymentView(session: session, balance: balance, bill: bill)
                case .splitSelection(let table, let nextState):
                    SubTableSelectionView(session: session, nextState: nextState, table: table)
                case .userSelection:
                    LoginView(
                        users: session.backendData.users,
                        onSelect: { user in
                            session.setUsers(user: user)
                            DataManager.shared.save(user, forKey: "recentUser" )
                        }, onFail: {
                            session.activeError = .invalidPassword
                        })
                case .main:
                    SelectionView(session: session, payments: payments)
                case .tableMap(let nextState):
                    TableMapView(session: session, nextState: nextState)
                default:
                    LoadingView()
                }
            }
        }
        .background(Color.background[900])
        .ignoresSafeArea(edges: .bottom)
        .alert(item: $session.activeError) { errorInfo in
            Alert(
                title: Text("Er ging iets mis"),
                message: Text(errorInfo.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .task {
            await session.verifyData()
        }
        .onOpenURL {url in
            guard
                url.host() == "result",
                let params = url.queryParameters,
                let result = params.first(where: { key, value in key == "status" })?.value,
                let message = params.first(where: {key, _ in key == "message"})?.value
            else {
                //session.activeError = .invalidPaymentURL
                return
            }
            
            if result == "failure" {
                session.activeError = .unknown(err: message.removingPercentEncoding ?? "")
            }else if result == "success" {
                guard
                    let merchantReference = params.first(where: {key, _ in key == "merchantReference"})?.value,
                    let userIdRaw = merchantReference.components(separatedBy: "-").first,
                    let userId = Int(userIdRaw),
                    let userName = merchantReference.components(separatedBy: "-").dropFirst().first,
                    let tableFlat = merchantReference.components(separatedBy: "-").dropFirst(2).first,
                    let table = TableInfo(flatTable: tableFlat),
                    let amountRaw = params.first(where: {key, _ in key == "amount"})?.value,
                    let tipAmountRaw = params.first(where: {key, _ in key == "tipAmount"})?.value,
                    let amount = Double(amountRaw),
                    let tipAmount = Double(tipAmountRaw)
                else {
                    return
                }
                
                if let currentUser = session.currentUser {
                    session.setUsers(user: currentUser, setState: false)
                }else {
                    let recentUser = DataManager.shared.load(forKey: "recentUser", as: UnitouchUser.self)
                    if let recentUser = recentUser {
                        session.setUsers(user: recentUser, setState: false)
                    }
                }
                session.finishVivaPayment(table: table, amount: amount/100, tipAmount: tipAmount/100, userId: userId, userName: userName, modelContext: modelContext)
            }
        }
    }
}


#Preview {
    ContentView()
}

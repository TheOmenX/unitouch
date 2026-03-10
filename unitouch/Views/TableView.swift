//
//  TableView.swift
//  unitouch
//
//  Created by Tijn Giesberts on 29/4/25.
//

import SwiftUI

fileprivate struct LookupItems: Identifiable {
    let id = UUID()
    let lookupId: Int
    var items: [UnitouchProduct]
}


struct TableView: View {
    
    @ObservedObject var session: SessionManager
    
    @State private var newItems: [NewItem] = []
    @State private var deletedItems: [NewItem] = []
    
    @State private var lookupItems: LookupItems? = nil
    
    @State private var selectedId: Int = 1
    @State private var itemSize: CGFloat = 0
    
    @State private var clickedItem: NewItem? = nil
    
    @State private var addTextAlert: Bool = false;
    @State private var textItemIndex: Int = -1;
    @State private var message: String = ""
    
    var body: some View {
        VStack{
            ZStack {
                Text("Account - Tafel \(session.currentTable?.formatTableRaw ?? "-")")
            }
            .frame(maxWidth: .infinity)
            .background(Color.gray)
            TabView{
                selectionView
                overviewView
                functionsView
            }
            .tabViewStyle(.page)
        }
    }
    
    var selectionView: some View {
        VStack{
            HStack{
                categoryBar
                itemBar
            }
            ZStack {
                ZStack {
                    GeometryReader { geometry in
                        let columns = 4
                        let spacing: CGFloat = 8
                        let totalSpacing = spacing * CGFloat(columns - 1)
                        let calculatedSize = (geometry.size.width - totalSpacing) / CGFloat(columns)
                        
                        Color.clear
                            .onAppear {
                                itemSize = calculatedSize
                            }
                    }
                    .frame(height: 0) // Prevent it from taking visible space
                    
                    HStack {
                        Button(action: { Task {
                            session.finishTable(newItems: newItems, deletedItems: deletedItems)
                        } }) {
                            ZStack {
                                if (!newItems.isEmpty && newItems.last?.plu != 1999){
                                    HStack{
                                        Text("\(newItems.last?.quantity ?? 0)")
                                            .frame(maxWidth: 40, maxHeight: .infinity)
                                            .foregroundColor(.black)
                                            .font(.title2)
                                            .bold()
                                        Text(newItems.last?.name ?? "Einde")
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                            .foregroundColor(.black)
                                            .font(.title2)
                                    }
                                }else {
                                    Text("Einde")
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .foregroundColor(.black)
                                        .font(.title2)
                                }
                            }
                            .frame(width: itemSize * 3, height: itemSize)
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(radius: 2)
                        }
                        
                        Button(action: {
                            if let last = newItems.last, last.plu != 1999 {
                                newItems.removeLast()
                                if let idx = session.blockedItems.firstIndex(where: {$0.plu == last.plu}) {
                                    session.blockedItems[idx].count += last.quantity
                                    session.addBlockedItem(plu: last.plu, count: last.quantity)
                                    
                                }
                            }
                        }) {
                            ZStack {
                                Image(systemName: "x.square.fill")
                                    .foregroundStyle(Color.black, Color.white)
                                    .font(.system(size: 70))
                            }
                            .frame(width: itemSize, height: itemSize)
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(radius: 2)
                        }
                    }
                }
            }
        }
        .sheet(item: $lookupItems) { data in
            VStack {
                
                List(
                    data.items
                        .sorted(by: { (a: UnitouchProduct, b: UnitouchProduct) -> Bool in a.unk3 < b.unk3 }),
                    id: \.self
                ) { item in
                    Text(item.name)
                        .frame(maxWidth: .infinity, alignment: .leading) // Stretch full width
                        .contentShape(Rectangle())
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .listRowInsets(EdgeInsets())
                        .onTapGesture {
                            createNewItem(item: item)
                            lookupItems = nil
                        }
                }
                .listStyle(.plain)
                .padding(.top, 24)
            }
        }
    }
    
    var categoryBar: some View {
        VStack {
            List(session.backendData.categories.sorted {$0.id < $1.id}, id: \.self) { category in
                HStack{
                    Text(category.name)
                }
                .frame(maxWidth: .infinity, alignment: .leading) // Stretch full width
                .contentShape(Rectangle())
                .listRowBackground(selectedId == category.id ? Color.orange : Color.clear)
                .onTapGesture {
                    selectedId = category.id
                    print("Selected ID: \(selectedId)")
                }
            }
            .listStyle(.plain)
            
        }
    }
    
    var itemBar: some View{
        VStack {
            List(
                session.backendData.items
                    .sorted(by: { (a: UnitouchProduct, b: UnitouchProduct) -> Bool in a.unk3 < b.unk3 })
                    .filter { (it: UnitouchProduct) in it.page == selectedId },
                id: \.self
            ) { item in
                HStack{
                    Text(item.name)
                        .frame(maxWidth: .infinity, alignment: .leading) // Stretch full width
                        .contentShape(Rectangle())
                        .padding(.vertical, 8)
                        .listRowInsets(EdgeInsets())
                        .onTapGesture {
                            if let idx = session.blockedItems.firstIndex(where: {$0.plu == item.plu}) {
                                if session.blockedItems[idx].count > 0 {
                                    session.blockedItems[idx].count -= 1
                                    session.addBlockedItem(plu: session.blockedItems[idx].plu, count: -1){
                                        createNewItem(item: item)
                                    }
                                }else {
                                    session.activeError = .itemBlocked
                                }
                            }
                            else {
                                createNewItem(item: item)
                            }
                        }
                    if let blocked = session.blockedItems.first(where: {$0.plu == item.plu}) {
                        Text(String(blocked.count))
                            .font(.caption)
                    }
                }
            }
            .listStyle(.plain)
        }
    }
    
    func createNewItem(item: UnitouchProduct){
        if !newItems.isEmpty && newItems.last?.plu == item.plu {
            newItems[newItems.count - 1].quantity += 1
        }else {
            newItems.append(NewItem(
                user: session.currentUser?.id ?? 1,
                plu: item.plu,
                name: item.name,
                quantity: 1,
                rang: item.rang,
                unk1: "F",
                price: Int(item.price*100),
                comment: item.followPrevious
            ) )
        }
        
        if item.lookup > 0, let lookupItem = session.backendData.lookups.first(where: {$0.id == item.lookup}) {
            self.lookupItems = LookupItems(lookupId: item.lookup, items: [])
            
            for plu in lookupItem.items.sorted() {
                if let product = session.backendData.items.first(where: {$0.plu == plu}) {
                    self.lookupItems?.items.append(product)
                }
            }
        }
    }
    
    var overviewView: some View {
        ZStack{
            GeometryReader { geometry in
                let columns = 8
                let spacing: CGFloat = 1
                let totalSpacing = spacing * CGFloat(columns - 1)
                let itemSize = (geometry.size.width - totalSpacing) / CGFloat(columns)
                VStack{
                    List {
                        HStack {
                            Text("Status")
                                .frame(width: itemSize)
                                .font(.caption)
                            Text("Qty")
                                .frame(width: itemSize)
                                .font(.caption)
                            Text("Omschrijving")
                                .frame(width: itemSize*6)
                                .font(.caption)
                        }
                        ForEach((session.currentTableItems + newItems), id: \.self) { item in
                            HStack {
                                if(newItems.contains(item)) {
                                    Image(systemName: "plus")
                                        .foregroundStyle(Color.gray)
                                        .frame(width: itemSize)
                                }else if (deletedItems.contains(item)){
                                    Image(systemName: "x.square.fill")
                                        .foregroundStyle(Color.red, Color.black)
                                        .frame(width: itemSize)
                                        .font(.system(size:itemSize*0.6))
                                }else {
                                    Image(systemName: "circle.fill")
                                        .foregroundStyle(Color.orange)
                                        .frame(width: itemSize)
                                }
                                
                                
                                Text("\(item.quantity)")
                                    .frame(width: itemSize)
                                Text(item.name)
                                    .frame(width: itemSize*6, alignment: .leading)
                                    .font(item.comment ? .caption : .body )
                                
                            }
                            .frame(maxWidth: .infinity, alignment: .leading) // Stretch full width
                            .contentShape(Rectangle())
                            .onTapGesture {
                                clickedItem = item
                            }
                        }
                    }
                    .listStyle(.plain)
                    .sheet(item: $clickedItem) { item in
                        VStack {
                            Text("Selected item:")
                            Text(item.name)
                                .font(.title)
                                .padding()
                            
                            HStack(){
                                SelectionButton(text: "Tekst", width: geometry.size.width/3-6, height: geometry.size.width/4-6, action1: {
                                    textItemIndex = (newItems.firstIndex(of: item) ?? -2)
                                    if(textItemIndex > -1) {addTextAlert = true}
                                })
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            HStack{
                                SelectionButton(text: "Annuleren", width: geometry.size.width/3-6, height: geometry.size.width/4-6, action1: {clickedItem = nil} )
                                SelectionButton(text: "Verwijder", width: geometry.size.width/3-6, height: geometry.size.width/4-6, action1:
                                {
                                    if(newItems.contains(item)){
                                        var start = -1;
                                        var end = -1
                                        for i in 0...(newItems.count-1) {
                                            if (newItems[i] == item){
                                                start = i
                                                end = i+1
                                            }else if (start != -1){
                                                if (newItems[i].comment){
                                                    end = i+1
                                                }else{
                                                    break
                                                }
                                            }
                                        }
                                        if(start != -1) {
                                            newItems.removeSubrange(start..<end)
                                            clickedItem = nil
                                        }
                                    }else{
                                        var found = false
                                        for el in session.currentTableItems {
                                            if (el == item){
                                                deletedItems.append(el)
                                                found = !el.comment
                                            }else if (found){
                                                if (el.comment){
                                                    deletedItems.append(el)
                                                }else{
                                                    break
                                                }
                                            }
                                        }
                                    }
                                    
                                    if let idx = session.blockedItems.firstIndex(where: {$0.plu == item.plu}) {
                                        session.blockedItems[idx].count += item.quantity
                                        session.addBlockedItem(plu: item.plu, count: item.quantity)
                                    }
                                    
                                    clickedItem = nil
                                })
                                SelectionButton(text: "Ok", width: geometry.size.width/3-6, height: geometry.size.width/4-6, action1: {clickedItem = nil})
                            }
                        }
                    }
                    Spacer()
                    HStack{
                        SelectionButton(text: "Terug", width: geometry.size.width/3-6, height: geometry.size.width/4-6)
                        SelectionButton(text: "Einde", width: geometry.size.width/3-6, height: geometry.size.width/4-6, action1: { Task {session.finishTable(newItems: newItems, deletedItems: deletedItems)} })
                        SelectionButton(text: "Functies", width: geometry.size.width/3-6, height: geometry.size.width/4-6)
                    }
                }
            }
        }.alert("Geef bericht in", isPresented: $addTextAlert, actions: {
            TextField("Bericht", text: $message)
            Button("Ok", action: {
                newItems.insert(NewItem(
                    user: session.currentUser?.id ?? 0,
                    plu: 1999,
                    name: message,
                    quantity: 1,
                    rang: 1,
                    unk1: "F",
                    price: 0,
                    comment: true),
                                at: textItemIndex+1 )
                message = ""
            })
            Button("Annuleren", role: .cancel, action: {})
        })
    }
    
    var functionsView: some View {
        VStack{
            SelectionButton(text: "Split", size: 200, action1: {
                session.state = .splitTable(nextAction: .move)
            })
            SelectionButton(text: "Split Betalen", size: 200, action1: {
                session.state = .splitTable(nextAction: .pay)
            })
        }
    }
}




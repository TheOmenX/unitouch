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

enum TableTab {
    case selection, overview, functions
}


struct TableView: View {
    
    @ObservedObject var session: SessionManager
    
    @State private var newItems: [NewItem] = []
    @State private var deletedItems: [NewItem] = []
    
    @State private var lookupItems: LookupItems? = nil
    
    
    @State private var menu: UnitouchMenu? = nil
    @State private var selectedStep: Int = 1
    @State private var selectedChoices: [Int: UnitouchProduct] = [:]
    
    @State private var selectedId: Int = 1
    @State private var itemSize: CGFloat = 0
    
    @State private var clickedItem: NewItem? = nil
    
    @State private var addTextAlert: Bool = false;
    @State private var textItemIndex: Int = -1;
    @State private var message: String = ""
    
    @State private var activeTab = TableTab.selection
    
    var body: some View {
        VStack(spacing:0){
            Text("Tafel \(session.currentTable?.formatTableRaw ?? "-")")
                .padding(2)
                .font(.custom("Roboto-Bold", size: 18))
                .foregroundStyle(Color.primary[500])
                .frame(maxWidth: .infinity)
                .background(Color.background[800])
                
            Divider()
                .frame(maxWidth: .infinity)
                .background(Color.background[700])
            TabView(selection: $activeTab){
                selectionView.tag(TableTab.selection)
                overviewView.tag(TableTab.overview)
                functionsView.tag(TableTab.functions)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea(edges: .bottom)
        }
    }
    
    var selectionView: some View {
        VStack(spacing: 0){
            HStack(spacing: 0){
                CategoryBarView(categories: session.backendData.categories, selectedId: $selectedId)
                Divider()
                    .frame(maxHeight: .infinity)
                    .foregroundStyle(Color.background[700])
                itemBar
            }
            Rectangle()
                .fill(Color.background[500])
                .frame(height: 1)
                .frame(maxWidth: .infinity)
                .ignoresSafeArea(edges: .bottom)
            VStack{
                HStack {
                    Button(action: { Task {
                        activeTab = TableTab.overview
                    } }) {
                        ZStack {
                            if (!newItems.isEmpty && newItems.last?.plu != 1999){
                                HStack{
                                    Text(newItems.last?.name ?? "\u{00A0}")
                                        .foregroundColor(.white)
                                        .font(.custom("Robot-Bold", size: 24))
                                    Spacer()
                                    Text("\(newItems.last?.quantity ?? 0)x")
                                        .foregroundColor(.white)
                                        .font(.custom("Roboto-Bold", size: 16))
                                }
                            }else {
                                Text("\u{00A0}")
                                    .foregroundColor(.black)
                                    .font(.title2)
                            }
                        }
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, maxHeight: 64)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.primary[500].opacity(0.3), lineWidth: 4)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 16))
                        .cornerRadius(16)
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
                                .foregroundStyle(Color.white, Color.danger[500])
                                .font(.system(size: 70))
                        }
                        .frame(width: 64, height: 64)
                        .cornerRadius(16)
                    }
                }
                
                Button(action: {
                    session.finishTable(newItems: newItems, deletedItems: deletedItems)
                }) {
                    Text("EINDE BESTELLING")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.primary[500])
                        .foregroundColor(.black)
                        .cornerRadius(15)
                        .font(.custom("Roboto-Bold", size: 20))
                        .shadow(color: Color.primary[500].opacity(0.5), radius: 5, x: 0, y: 0)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.background[700])
            .ignoresSafeArea(edges: .bottom)
            
        }
        .ignoresSafeArea(edges: .bottom)
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
        .sheet(item: $menu) { data in
            HStack {
                VStack {
                    List(data.steps.sorted(by: { $0.key < $1.key }), id: \.key) { item in
                        Text("Rang \(item.key)")
                            .background(selectedStep == item.key ? Color.orange : Color.clear)
                            .onTapGesture {
                                selectedStep = item.key
                            }
                    }
                }
                VStack {
                    List(data.steps[selectedStep]?.sorted() ?? [], id: \.self) { plu in
                        if let product = session.backendData.items.first(where: { $0.plu == plu }) {
                            Text(product.name)
                                .background(selectedChoices[selectedStep]?.plu == product.plu ? Color.orange : Color.clear)
                                .onTapGesture {
                                    selectedChoices[selectedStep] = product
                                    
                                    if selectedChoices.count == data.steps.count {
                                        for step in data.steps.keys.sorted() {
                                            if let choice = selectedChoices[step] {
                                                createNewItem(item: choice)
                                            }
                                        }
                                            
                                        self.menu = nil
                                        self.selectedStep = 1
                                        self.selectedChoices = [:]
                                    }
                                }
                        }
                    }
                }
            }
        }
    }
    
    var itemBar: some View{
        ScrollView{
            VStack{
                ForEach(
                    session.backendData.items
                        .sorted(by: { (a: UnitouchProduct, b: UnitouchProduct) -> Bool in a.unk3 < b.unk3 })
                        .filter { (it: UnitouchProduct) in it.page == selectedId },
                    id: \.self
                ) { item in
                    let blockedCount = session.blockedItems.first(where: { $0.plu == item.plu })?.count ?? -1
                    Button(action: {
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
                    }) {
                        HStack{
                            Text(item.name)
                                .font(.custom("Roboto-Bold", size: 20))
                                .opacity(blockedCount == 0 ? 0.4 : 1)
                            Spacer()
                            Text("€" + Decimal(item.price).toCurrency)
                                .font(.custom("Roboto-Bold", size: 14))
                                .foregroundStyle(Color.primary[500])
                                .opacity(blockedCount == 0 ? 0.4 : 1)
                            if blockedCount >= 0 {
                                Image(systemName: "\(blockedCount).circle.fill")
                                    .foregroundStyle(Color.danger[500], Color.danger[500].opacity(0.1))
                                    .font(.system(size: 18))
                                
                            }else {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(Color.primary[500], Color.primary[500].opacity(0.1))
                                    .font(.system(size: 18))
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(Color.background[700])
                        .opacity(blockedCount == 0 ? 0.4 : 1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(RoundedRectangle(cornerRadius: 10))
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding(.horizontal, 8)
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
        
        
        if let menu = session.backendData.menus.first(where: { $0.item == item.plu }) {
            print(menu.steps)
            self.menu = menu
            self.selectedId = 1
            self.selectedChoices = [:]
        }
            
        
        
    }
    
    var overviewView: some View {
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
        
            /*
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
             */
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

/*----------------------------------------------\
|                                               |
|                 Categorie Bar                 |
|                                               |
\----------------------------------------------*/

struct CategoryBarView: View {
    var categories: [UnitouchCategory]
    @Binding var selectedId: Int

    var body: some View {
        ScrollView {
            VStack(spacing: 0){
                ForEach(categories.sorted { $0.id < $1.id }, id: \.self) { category in
                    categoryContainer(category: category)
                        .padding(0)
                    Divider()
                        .frame(maxWidth: .infinity)
                        .background(Color.background[700])
                }
            }
        }
        .frame(maxWidth: 128, alignment: .center)
        .scrollIndicators(.hidden)
    }

    func categoryContainer(category: UnitouchCategory) -> some View {
        HStack{
            Text(category.name.uppercased())
                .font(.custom("Roboto-Bold", size: 20))
                .foregroundStyle(selectedId == category.id ? .black : .white)
                .padding()
        }
        .contentShape(Rectangle())
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
        .background(selectedId == category.id ? Color.primary[500] : Color.background[900])
        .onTapGesture {
            selectedId = category.id
        }
        
    }
}

/*----------------------------------------------\
|                                               |
|                   Item Bar                    |
|                                               |
\----------------------------------------------*/

#Preview {
    @Previewable @State var selectedId = 1
    
    CategoryBarView(categories: [
        UnitouchCategory(id: 1, name: "hard lopers"),
        UnitouchCategory(id: 2, name: "warme dranken"),
        UnitouchCategory(id: 3, name: "gebak"),
        UnitouchCategory(id: 4, name: "fris dranken"),
        UnitouchCategory(id: 5, name: "bieren"),
        UnitouchCategory(id: 6, name: "wijnen"),
        UnitouchCategory(id: 7, name: "borrel happen"),
        UnitouchCategory(id: 8, name: "broodjes"),
        UnitouchCategory(id: 9, name: "tosti & kids"),
        UnitouchCategory(id: 10, name: "salades & soepen"),
        UnitouchCategory(id: 11, name: "ontbijt"),
        UnitouchCategory(id: 12, name: "alc. dranken"),
    ], selectedId: $selectedId)
}


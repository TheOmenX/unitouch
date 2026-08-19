//
//  TableView.swift
//  unitouch
//
//  Created by Tijn Giesberts on 29/4/25.
//

import SwiftUI

enum TableTab {
    case selection, overview, search
}

struct TableView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var store: RestaurantStore
    
    var tableID: String
    var subTableIndex: Int
    var activeTable: Components.Schemas.RestaurantTable {
        return store.tables.first(where: { $0.id == tableID })!
    }
    
    @State var activeOrderItems: [Components.Schemas.OrderItem] = []
    @State var activeOrderID: String? = nil
    @State private var promptGuestCount: Bool = false
    @State private var guestCountStr: String = ""
    
    //MARK: - Active Items
    @State private var newItems: [Components.Schemas.OrderItem] = []
    @State private var deletedItems: [String] = [] // UUIDs
    
    //MARK: - Table Search Switch
    var searchMode: Bool = false
    
    //MARK: - Lookup Variables
    @State private var activeLookup: Components.Schemas.Lookup? = nil
    
    //MARK: - Menu Variables
    @State private var menu: Components.Schemas.Menu? = nil
    @State private var selectedStepID: String = ""
    @State private var selectedChoices: [String: Components.Schemas.Item] = [:] // MenuStepID : ItemID
    
    //MARK: - Category ID
    @State private var selectedId: String = ""
    
    //MARK: - Active Editing Item
    @State private var clickedItem: Components.Schemas.OrderItem? = nil
    
    //MARK: - Commenting on Items
    @State private var commentAlert: Bool = false;
    @State private var message: String = ""
    
    //MARK: - Animation Bullshit
    @State private var isPressed = false
    
    
    //MARK: - Navigation
    @State private var activeTab = TableTab.selection
    
    // MARK: - Search Bar
    @State private var showSearch: Bool = false
    @State private var searchText: String = ""
    @FocusState private var searchFieldIsFocused: Bool
    
    var body: some View {
        VStack(spacing:0){
            //MARK: - Search Bar
            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                            showSearch.toggle()
                        }
                        if showSearch {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                                searchFieldIsFocused = true
                            }
                        } else {
                            searchFieldIsFocused = false
                            searchText = ""
                        }
                    }) {
                        ZStack(alignment: .center) {
                            Text(searchMode ? "Tafel Zoeken" : "Tafel \(activeTable.displayLabel(subTableIndex))")
                                .font(.custom("Roboto-Bold", size: 18))
                                .foregroundStyle(Color.primary[500])
                            HStack{
                                Spacer()
                                Image(systemName: showSearch ? "chevron.up" : "chevron.down")
                                    .foregroundStyle(Color.background[400])
                            }
                        }
                        .padding(12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                .background(Color.background[800])
                
                // animated search dropdown
                if showSearch {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(Color.background[400])
                            TextField("Zoek artikel", text: $searchText)
                                .focused($searchFieldIsFocused)
                                .textFieldStyle(.plain)
                                .onSubmit {
                                    showSearch = false
                                    searchText = ""
                                }
                                .foregroundColor(Color.primary[500])
                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(Color.background[400])
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.background[900])
                        .cornerRadius(10)
                        .padding(.horizontal, 12)
                    }
                    .padding(.vertical, 10)
                    .background(Color.background[900])
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Divider()
                    .frame(maxWidth: .infinity)
                    .background(Color.background[700])
            }
            
            TabView(selection: $activeTab){
                selectionView.tag(TableTab.selection)
                if(searchMode) {
                    //searchView.tag(TableTab.search)
                } else {
                    overviewView.tag(TableTab.overview)
                }
                
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea(edges: .bottom)
        }
        .task {
            self.selectedId = self.store.categories.first?.id ?? ""
            print(self.activeTable)
            do {
                let order = try await NetworkService.shared.getTableOrder(tableId: self.tableID, subTable: self.subTableIndex)
                self.activeOrderItems = order.items
                self.activeOrderID = order.order_id
                self.promptGuestCount = order.guest_count == 0
                
            } catch(let err) {
                print(err.localizedDescription)
                router.activeError = err as? UnitouchError
            }
        }
        .popup(item: $clickedItem) { item in
            let sub_items = item.sub_items ?? []
            VStack {
                Text("Geselecteerd artikel:")
                    .font(.custom("Roboto-Regular", size: 18))
                    .foregroundStyle(Color.background[100])
                HStack{
                    Text("\(item.quantity)x")
                        .font(.custom("Roboto-Bold", size: 24))
                        .foregroundStyle( (newItems.contains(item) || deletedItems.contains(item.id)) ? Color.background[800] : Color.background[100])
                        .frame(width: 48, height: 48)
                        .background(newItems.contains(item) ? Color.primary[400] : (deletedItems.contains(item.id) ? Color.danger[400] : Color.background[900]))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    Text(item.item_name)
                        .font(.custom("Roboto-Bold", size: 36))
                        .padding()
                }
                ForEach(sub_items, id: \.id) { sub_item in
                    let isBeingDeleted = deletedItems.contains(where: { $0 == sub_item.id })
                    HStack{
                        Circle()
                            .foregroundStyle(Color.background[600])
                            .frame(width: 20, height: 20)
                            .overlay(
                                Text("\(sub_item.quantity)")
                                    .font(.custom("Roboto-Bold", size: 17))
                                    .foregroundStyle(Color.background[800])
                            )
                        
                        Text(sub_item.item_name)
                            .font(.custom("Roboto-Italic", size: 20))
                            .foregroundStyle(Color.background[600])
                            .padding(.horizontal, 12)
                            .overlay(
                                Divider()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.danger[500])
                                    .padding(.vertical, 10)
                                    .opacity(isBeingDeleted ? 1 : 0)
                            )
                        
                        Image(systemName: isBeingDeleted ? "arrow.uturn.left" : "trash")
                            .foregroundStyle(isBeingDeleted ? .orange : Color.danger[500])
                            .onTapGesture {
                                if deletedItems.contains(sub_item.id){
                                    deletedItems.removeAll(where: { $0 == sub_item.id })
                                }else if newItems.contains(sub_item) {
                                    newItems.removeAll(where: { $0.id == sub_item.id })
                                } else {
                                    deletedItems.append(sub_item.id)
                                }
                            }
                    }
                }
                ForEach(item.comments, id: \.self) { comment in
                    HStack{
                        Text(comment)
                            .font(.custom("Roboto-Italic", size: 20))
                            .foregroundStyle(Color.background[600])
                            .padding(.horizontal, 12)
//                            .overlay(
//                                Divider()
//                                    .frame(maxWidth: .infinity)
//                                    .background(Color.danger[500])
//                                    .padding(.vertical, 10)
//                                    .opacity(isBeingDeleted ? 1 : 0)
//                            )
                    }
                }
                    
                
                //TODO: Make item amount increasable/decreasable
                
                HStack{
                    BlankOutlineButton(action: {
                        commentAlert = true
                    }) {
                        Text("Text")
                    }
                    BlankOutlineButton(action: {
                        // Remove items from order (or add them back when they are already set for removal)
                        if deletedItems.contains(item.id){
                            deletedItems.removeAll(where: { $0 == item.id })
                            
//                            if let idx = blockedItems.firstIndex(where: {$0.item_id == item.item_id}) {
//                                blockedItems[idx].amount -= item.quantity
////                                TODO: fix locking of items
//                                session.addBlockedItem(plu: item.plu, count: -item.quantity)
//                            }
                        }else {
                            if(newItems.contains(item)){
                                newItems.removeAll { $0.id == item.id }
                                clickedItem = nil
                            }else{
                                deletedItems.append(item.id)
                            }
                            
//                        TODO: fix locking of items
//                            if let idx = session.blockedItems.firstIndex(where: {$0.plu == item.plu}) {
//                                session.blockedItems[idx].count += item.quantity
//                                session.addBlockedItem(plu: item.plu, count: item.quantity)
//                            }
                        }
                        
                        clickedItem = nil
                    }) {
                        Text(deletedItems.contains(item.id) ? "Toevoegen" : "Verwijderen")
                    }
                }
                HStack{
                    PrimaryFilledButton(action: {clickedItem = nil}) {
                        Text("Ok")
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 20)
        }
        .popup(isPresented: $promptGuestCount) {
            VStack{
                Text("Aantal personen")
                    .font(.custom("Roboto-Bold", size: 18))
                    .foregroundStyle(Color.background[100])
                    .padding(.bottom, 10)
                Text(guestCountStr.isEmpty ? "\u{00A0}" : guestCountStr)
                    .font(.custom("Roboto-Bold", size: 36))
                    .padding(.bottom, 20)
                Divider()
                    .frame(maxWidth: .infinity)
                    .background(Color.background[700])
                    .padding(.vertical, 10)
                InputKeypad(input: $guestCountStr, inputValidation: { input in
                    if !input.contains("."), let count = Int(input), count > 0 && count <= 99 {
                        return true
                    } else { return false }
                })
                
                PrimaryFilledButton(action: {
                    if (activeOrderID != nil) {
                        Task {
                            do {
                                try await NetworkService.shared.setGuestCount(tableID: self.tableID, subTable: self.subTableIndex,payload: Components.Schemas.SetGuestCountRequest(guest_count: Int(guestCountStr) ?? 0) )
                                self.promptGuestCount = false
                            } catch(let err){
                                print(err)
                                router.activeError = .unknown(err: "Could not set guest count")
                            }
                        }
                    }
                }) {
                    Text("Ok")
                }
            }
                .padding()
        }
        .alert("Geef bericht in", isPresented: $commentAlert, actions: {
            TextField("Bericht", text: $message)
            Button("Ok", action: {
                guard !message.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        
                // 1. Find the index in the actual state array
                if let targetId = clickedItem?.id,
                   let index = newItems.firstIndex(where: { $0.id == targetId }) {
                    // 2. Mutate the real array element directly
                    newItems[index].comments.append(message)
                    
                    // 3. Keep the popup preview in sync if it is still open
                    clickedItem = newItems[index]
                }
                
                message = ""
            })
            Button("Annuleren", role: .cancel, action: {})
        })
    }
    
    var selectionView: some View {
        VStack(spacing: 0){
            HStack(spacing: 0){
                if searchText.isEmpty {
                    CategoryBarView(categories: store.categories, selectedId: $selectedId)
                    Divider()
                        .frame(maxHeight: .infinity)
                        .foregroundStyle(Color.background[700])
                    
                    ItemBarView(items: store.items(forCategory: selectedId)) { selectedItem in
                        handleItemTap(item: selectedItem)
                    }
                } else {
                    ScrollView {
                        VStack {
                            ForEach(store.items, id: \.id) { item in
                                ItemRowView(item: item, blockedCount: -1) {
                                    handleItemTap(item: item)
                                }
                            }
                        }
                    }
                }
            }
            Rectangle()
                .fill(Color.background[500])
                .frame(height: 1)
                .frame(maxWidth: .infinity)
                .ignoresSafeArea(edges: .bottom)
            VStack{
                HStack {
                    ZStack {
                        if (!newItems.isEmpty) {
                            HStack {
                                Text(newItems.last?.item_name ?? "\u{00A0}")
                                    .foregroundColor(.white)
                                    .font(.custom("Roboto-Bold", size: 24))
                                Spacer()
                                Text("\(newItems.last?.quantity ?? 0)x")
                                    .foregroundColor(.white)
                                    .font(.custom("Roboto-Bold", size: 16))
                            }
                        } else {
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
                    .opacity(isPressed ? 0.6 : 1.0)
                    .scaleEffect(isPressed ? 0.98 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: isPressed)
                    .onLongPressGesture(
                        minimumDuration: 0.7,
                        perform: {
                            if !newItems.isEmpty {
                                clickedItem = newItems.last
                            }
                        },
                        onPressingChanged: { pressing in
                            isPressed = pressing
                        }
                    )
                    .onTapGesture {
                        Task {
                            activeTab = TableTab.overview
                        }
                    }
                    
                    Button(action: {
                        if let last = newItems.last {
                            newItems.removeLast()
//                            TODO: FIX blocked items
//                            if let idx = session.blockedItems.firstIndex(where: {$0.plu == last.plu}) {
//                                session.blockedItems[idx].count += last.quantity
//                                session.addBlockedItem(plu: last.plu, count: last.quantity)
//                            }
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
                if searchMode {
                    PrimaryFilledButton(action: {
                        //session.searchTables(items: newItems)
                        //activeTab = .search
                    }) {
                        Text("TAFEL ZOEKEN")
                    }
                } else {
                    PrimaryFilledButton(action: {
                        Task {
                            await finalizeOrder()
                        }
                    }) {
                        Text("EINDE BESTELLING")
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.background[700])
            .ignoresSafeArea(edges: .bottom)
            
        }
        .ignoresSafeArea(edges: .bottom)
        // MARK: - LOOKUP POPUP
        .sheet(item: $activeLookup) { lookup in
            VStack {
                List(
                    lookup.resolvedItems(using: store),
                    // TODO:    .sorted(by: { (a: Components.Schema.Item, b: Components.Schema.Item) -> Bool in a. < b.unk3 }),
                    id: \.self
                ) { item in
                    Text(item.name)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .listRowInsets(EdgeInsets())
                        .onTapGesture {
                            createNewItem(item: item)
                            activeLookup = nil
                        }
                }
                .listStyle(.plain)
                .padding(.top, 24)
            }
        }
        // MARK: - MENU POPUP
        .popup(item: $menu) { menu in
            HStack {
                VStack {
                    List((menu.steps.sorted(by: { $0.sort_order < $1.sort_order })), id: \.id) { step in
                        Text(step.name)
                            .font(.custom("Roboto-Bold", size: 20))
                            .listRowBackground(selectedStepID == step.id ? Color.primary[600] : (selectedChoices[step.id] != nil ? Color.primary[800] : Color.background[900]))
                            .onTapGesture {
                                selectedStepID = step.id
                            }
                    }
                    .scrollContentBackground(.hidden)
                }
                VStack {
                    List(menu.steps.first { $0.id == selectedStepID}?.resolvedItems(using: store) ?? []) { item in
                        Text(item.name)
                            .listRowBackground(selectedChoices[selectedStepID] == item ? Color.primary[600] : Color.background[900])
                            .onTapGesture {
                                selectedChoices[selectedStepID] = item
                            }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
        }
    }
    
    var overviewView: some View {
        VStack{
            ScrollView {
                VStack{
                    let combinedItems = activeOrderItems + newItems
                    ForEach(combinedItems, id: \.self) { item in
                        itemContainer(item: item)
                        .onTapGesture {
                            clickedItem = item
                        }
                    }
                }
                .background(Color.background[800])
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.background[700].opacity(0.3), lineWidth: 2)
                )
                .padding(12)
            }
            
            Spacer()
            Divider()
                .frame(maxWidth: .infinity)
                .background(Color.background[700])
            VStack{
                HStack{
                    BlankOutlineButton(action: {
                        activeTab = .selection
                    }) {
                        Text("Artikel toevoegen")
                            .font(.custom("Roboto-Bold", size: 16))
                    }
                    BlankOutlineButton(action: {
                        Task {
                            // TODO: define move behavior
                        }
                    }) {
                        Text("Verplaatsen")
                            .font(.custom("Roboto-Bold", size: 16))
                    }
                }
                HStack{
                    BlankOutlineButton(action: {
                        Task {
                            // TODO: define split behavior
                        }
                    }) {
                        Text("Split")
                            .font(.custom("Roboto-Bold", size: 16))
                    }
                    BlankOutlineButton(action: {
                        Task {
                            // TODO: define pay behavior
                        }
                    }) {
                        Text("Betalen")
                            .font(.custom("Roboto-Bold", size: 16))
                    }
                }

                PrimaryFilledButton(action: {
                    Task {
                        await finalizeOrder()
                    }
                }) {
                    Text("EINDE BESTELLING")
                }
            }
            .padding(.horizontal, 8)
        }
    }
    
    /*
    var searchView: some View {
        VStack{
            ScrollView {
                VStack{
                    let combinedItems = session.currentTableItems + newItems
                    ForEach(combinedItems, id: \.self) { item in
                        itemContainer(item: item)
                            .onTapGesture {
                                clickedItem = item
                            }
                    }
                }
                .background(Color.background[800])
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.background[700].opacity(0.3), lineWidth: 2)
                )
                .padding(12)
            }
            
            Spacer()
            Divider()
                .frame(maxWidth: .infinity)
                .background(Color.background[700])
            
            ScrollView {
                ForEach(session.openTables) { table in
                    HStack {
                        VStack{
                            HStack{
                                Text(table.displayLabel)
                                    .font(.custom("Roboto-Bold", size: 18))
                                    .foregroundStyle(Color.background[100])
                            }
                            HStack(spacing: 0){
                                Image(systemName: "clock")
                                    .font(.system(size: 14)) // keep icon size consistent
                                    .foregroundStyle(Color.background[400])
//                                Text(table.time)
//                                    .foregroundStyle(Color.background[400])
//                                    .font(.custom("Roboto-Regular", size: 14))
                            }
                        }
                        
                        Spacer()
                        
//                        Text(table.balance.formatted(.currency(code: "EUR")))
//                            .font(.custom("Roboto-Bold", size: 18))
//                            .foregroundStyle(Color.background[100])
                    }
                    .contentShape(Rectangle())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .onTapGesture {
                        Task {
                            await session.enterTable(tableId: table.physicalTable.id, subTable: table.subTableIndex)
                        }
                    }
                    Divider()
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                }
            
            
            BlankOutlineButton(action: {
                    //TODO: define exit behavior
            }) {
                Text("ANNULEREN")
            }.padding(.horizontal)
        }
    }
    // */
    
    @ViewBuilder
    func itemContainer(item: Components.Schemas.OrderItem) -> some View {
        let isNewItem = newItems.contains(where: { $0.id == item.id })
        let isDeletedItem = deletedItems.contains(where: { $0 == item.id })
        
        
        HStack {
            Text("\(item.quantity)x")
                .font(.custom("Roboto-Bold", size: 18))
                .foregroundStyle( (isNewItem || isDeletedItem) ? Color.background[800] : Color.background[100])
                .frame(width: 36, height: 36)
                .background(isNewItem ? Color.primary[400] : (isDeletedItem ? Color.danger[400] : Color.background[900]))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            Text(item.item_name)
                .font(.custom("Roboto-Bold", size: 18))
                .foregroundStyle(Color.background[100])
            
            Spacer()
            Text((Double(item.quantity) * item.unit_price).formatted(.currency(code: "EUR")))
                .foregroundStyle(Color.background[100])
        }
        .padding(.horizontal, 10)
        .padding(.top, 10)
        .padding(.bottom, 2)
        
        ForEach(item.sub_items ?? []) { subItem in
            HStack{
                Spacer().frame(width: 48)
                Text(subItem.item_name)
                    .font(.custom("Roboto-Italic", size: 13))
                    .foregroundStyle(Color.background[600])
                Spacer()
                if(subItem.unit_price != 0) {
                    Text((Double(subItem.quantity) * subItem.unit_price).formatted(.currency(code: "EUR")))
                        .font(.custom("Roboto-Italic", size: 13))
                        .foregroundStyle(Color.background[600])
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 2)
        }
        ForEach(item.comments, id: \.self) { comment in
            HStack{
                Spacer().frame(width: 48)
                Text(comment)
                    .font(.custom("Roboto-Italic", size: 13))
                    .foregroundStyle(Color.background[600])
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 2)
            
        }

        Divider()
            .frame(maxWidth: .infinity)
            .background(Color.background[700])
            .padding(.top, 8)
        
    }
    
    
    // MARK: - Logical functions
    private func handleItemTap(item: Components.Schemas.Item) {
        createNewItem(item: item)
        
////      TODO: fix
//        if let idx = session.blockedItems.firstIndex(where: {$0.item_id == item.id}) {
//            if session.blockedItems[idx].amount > 0 {
//                session.blockedItems[idx].amount -= 1
////                session.addBlockedItem(plu: session.blockedItems[idx].plu, count: -1){
////                    createNewItem(item: item)
////                }
//            } else {
//                session.activeError = .itemBlocked
//            }
//        } else {
//            createNewItem(item: item)
//        }
    }
    
    func createNewItem(item: Components.Schemas.Item) {
        if !newItems.isEmpty && newItems.last?.item_id == item.id {
            newItems[newItems.count - 1].quantity += 1
        } else {
            newItems.append(Components.Schemas.OrderItem(
                id: UUID().uuidString,
                item_id: item.id,
                item_name: item.name,
                unit_price: item.price,
                discount_amount: 0.0,
                vat_rate: item.vat_rate,
                quantity: 1,
                comments: [],
                sort_order: (newItems.last?.sort_order ?? -1) + 1,
                created_at: Date(),
                created_by: router.currentUser?.id ?? ""
            ))
        }
        
        self.activeLookup = item.resolvedLookup(in: store) ?? nil
        
        if let menu = item.resolvedMenu(in: store) {
            self.menu = menu
            self.selectedId = ""
            self.selectedChoices = [:]
        }
    }
    
    func finalizeOrder() async {
        do {
            try await NetworkService.shared.updateTable(
                tableId: self.tableID,
                subTable: self.subTableIndex,
                payload: Components.Schemas.TableUpdateRequest(
                    add: newItems,
                    remove: deletedItems
                )
            )
            router.navigate(to: .main)
        } catch {
            router.activeError = .unknown(err: "Could not update items on table")
        }
    }
}

     
/*----------------------------------------------\
|                                               |
|           Extracted Modular Views             |
|                                               |
\----------------------------------------------*/

struct ItemBarView: View {
    var items: [Components.Schemas.Item]
    var onItemSelected: (Components.Schemas.Item) -> Void
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(items, id: \.id) { item in
                    ItemRowView(item: item, blockedCount: -1) {
                        onItemSelected(item)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .padding(.horizontal, 8)
    }
}

struct ItemRowView: View {
    let item: Components.Schemas.Item
    let blockedCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
        }) {
            HStack{
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: item.categories.first?.color ?? "#FFFFFF"))
                    .frame(width: 6)
                    .frame(maxHeight: .infinity)
                Text(item.name)
                    .font(.custom("Roboto-Bold", size: 20))
                    .opacity(blockedCount == 0 ? 0.4 : 1)
                    .multilineTextAlignment(.leading)
                Spacer()
                Text("€" + Decimal(item.price).toCurrency)
                    .font(.custom("Roboto-Bold", size: 14))
                    .foregroundStyle(Color.primary[500])
                    .opacity(blockedCount == 0 ? 0.4 : 1)
                
                if blockedCount >= 0 {
                    Image(systemName: "\(blockedCount).circle.fill")
                        .foregroundStyle(Color.danger[500], Color.danger[500].opacity(0.1))
                        .font(.system(size: 18))
                } else {
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

struct CategoryBarView: View {
    var categories: [Components.Schemas.Category]
    @Binding var selectedId: String

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

    func categoryContainer(category: Components.Schemas.Category) -> some View {
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

#Preview {
    @Previewable @State var selectedId = UUID().uuidString
    
    
    CategoryBarView(categories: [
        Components.Schemas.Category(id: selectedId, name: "hard lopers", sort_order: 0),
        Components.Schemas.Category(id: UUID().uuidString, name: "warme dranken", sort_order: 1),
        Components.Schemas.Category(id: UUID().uuidString, name: "gebak", sort_order: 2),
        Components.Schemas.Category(id: UUID().uuidString, name: "fris dranken", sort_order: 3),
        Components.Schemas.Category(id: UUID().uuidString, name: "bieren", sort_order: 4),
        Components.Schemas.Category(id: UUID().uuidString, name: "wijnen", sort_order: 5),
        Components.Schemas.Category(id: UUID().uuidString, name: "borrel happen", sort_order: 6),
        Components.Schemas.Category(id: UUID().uuidString, name: "broodjes", sort_order: 7),
        Components.Schemas.Category(id: UUID().uuidString, name: "tosti & kids", sort_order: 8),
        Components.Schemas.Category(id: UUID().uuidString, name: "salades & soepen", sort_order: 9),
        Components.Schemas.Category(id: UUID().uuidString, name: "ontbijt", sort_order: 10),
        Components.Schemas.Category(id: UUID().uuidString, name: "alc. dranken", sort_order: 11),
    ], selectedId: $selectedId)
}

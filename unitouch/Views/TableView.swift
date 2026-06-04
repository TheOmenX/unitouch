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
    
    @Binding var newItems: [NewItem]
    @Binding var deletedItems: [NewItem]
    
    @State private var lookupItems: LookupItems? = nil
    
    @State private var selectedId: Int = 1
    @State private var itemSize: CGFloat = 0
    
    @State private var clickedItem: NewItem? = nil
    
    @State private var addTextAlert: Bool = false;
    @State private var textItemIndex: Int = -1;
    @State private var message: String = ""
    
    @State private var activeTab = TableTab.selection
    
    @State private var isPressed = false
    
    @State private var numberOfPeople = ""
    
    @State private var showSearch: Bool = false
    @State private var searchText: String = ""
    @FocusState private var searchFieldIsFocused: Bool
    
    var body: some View {
        VStack(spacing:0){
            // tappable header
            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        // toggle dropdown (animated) and focus the search field when opened
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                            showSearch.toggle()
                        }
                        if showSearch {
                            // delay to let animation start then focus
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                                searchFieldIsFocused = true
                            }
                        } else {
                            searchFieldIsFocused = false
                            searchText = ""
                        }
                    }) {
                        ZStack(alignment: .center) {
                            Text("Tafel \(session.currentTable?.formatTableRaw ?? "-")")
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
                overviewView.tag(TableTab.overview)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea(edges: .bottom)
        }
        .popup(item: $clickedItem) { item in
            let combinedItems = session.currentTableItems + newItems
            let index = combinedItems.firstIndex(where: {$0.id == item.id}) ?? -1
            let comments = Array(combinedItems.dropFirst(index + 1).prefix(while: { $0.comment }))
                
            
            VStack {
                Text("Geselecteerd artikel:")
                    .font(.custom("Roboto-Regular", size: 18))
                    .foregroundStyle(Color.background[100])
                HStack{
                    Text("\(item.quantity)x")
                        .font(.custom("Roboto-Bold", size: 24))
                        .foregroundStyle( (newItems.contains(item) || deletedItems.contains(item)) ? Color.background[800] : Color.background[100])
                        .frame(width: 48, height: 48)
                        .background(newItems.contains(item) ? Color.primary[400] : (deletedItems.contains(item) ? Color.danger[400] : Color.background[900]))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    Text(item.name)
                        .font(.custom("Roboto-Bold", size: 36))
                        .padding()
                }
                ForEach(comments, id: \.id) { comment in
                    let isBeingDeleted = deletedItems.contains(where: { $0.id == comment.id })
                    HStack{
                        Circle()
                            .foregroundStyle(Color.background[600])
                            .frame(width: 20, height: 20)
                            .overlay(
                                Text("\(comment.quantity)")
                                    .font(.custom("Roboto-Bold", size: 17))
                                    .foregroundStyle(Color.background[800])
                            )
                        
                        Text(comment.name)
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
                                if deletedItems.contains(comment){
                                    deletedItems.removeAll(where: { $0.id == comment.id })
                                }else if newItems.contains(comment) {
                                    newItems.removeAll(where: { $0.id == comment.id })
                                } else {
                                    deletedItems.append(comment)
                                }
                            }
                            
                            
                        
                    }
                }
                    
                
                //TODO: Make item amount increasable/decreasable
                
                HStack{
                    BlankOutlineButton(action: {
                        textItemIndex = (newItems.firstIndex(of: item) ?? -2)
                        if(textItemIndex > -1) {addTextAlert = true}
                    }) {
                        Text("Text")
                    }
                    BlankOutlineButton(action: {
                        if deletedItems.contains(item){
                            deletedItems.removeAll(where: { $0.id == item.id })
                            
                            if let idx = session.blockedItems.firstIndex(where: {$0.plu == item.plu}) {
                                session.blockedItems[idx].count -= item.quantity
                                session.addBlockedItem(plu: item.plu, count: -item.quantity)
                            }
                        }else {
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
                        }
                        
                        clickedItem = nil
                    }) {
                        Text(deletedItems.contains(item) ? "Toevoegen" : "Verwijderen")
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
        .popup(isPresented: $session.requestNumberOfPeople) {
            VStack{
                Text("Aantal personen")
                    .font(.custom("Roboto-Bold", size: 18))
                    .foregroundStyle(Color.background[100])
                    .padding(.bottom, 10)
                Text(numberOfPeople.isEmpty ? "\u{00A0}" : numberOfPeople)
                    .font(.custom("Roboto-Bold", size: 36))
                    .padding(.bottom, 20)
                Divider()
                    .frame(maxWidth: .infinity)
                    .background(Color.background[700])
                    .padding(.vertical, 10)
                InputKeypad(input: $numberOfPeople, inputValidation: { input in
                    if !input.contains("."), let count = Int(input), count > 0 && count <= 99 {
                        return true
                    } else { return false }
                })
                
                PrimaryFilledButton(action: {
                    session.setNumberOfPeople(count: Int(numberOfPeople) ?? 0)
                }) {
                    Text("Ok")
                }
            }
                .padding()
        }
        .alert("Geef bericht in", isPresented: $addTextAlert, actions: {
            TextField("Bericht", text: $message)
            Button("Ok", action: {
                let textChunks = chunkText(message)
                for chunk in textChunks.reversed() {
                    newItems.insert(NewItem(
                        user: session.currentUser?.id ?? 0,
                        plu: 1999,
                        name: chunk,
                        quantity: 1,
                        rang: 1,
                        unk1: "F",
                        price: 0,
                        comment: true),
                                    at: textItemIndex+1 )
                }
                message = ""
            })
            Button("Annuleren", role: .cancel, action: {})
        })
    }
    
    private func dedupProducts(_ items: [UnitouchProduct]) -> [UnitouchProduct] {
        var seen = Set<Int>()
        return items.filter { seen.insert($0.plu).inserted }
    }
    
    var selectionView: some View {
        VStack(spacing: 0){
            HStack(spacing: 0){
                if searchText.isEmpty {
                    CategoryBarView(categories: session.backendData.categories, selectedId: $selectedId)
                    Divider()
                        .frame(maxHeight: .infinity)
                        .foregroundStyle(Color.background[700])
                    itemBar
                } else {
                    ScrollView {
                        VStack {
                            ForEach(dedupProducts(session.backendData.items
                                .filter { (it: UnitouchProduct) in it.name.lowercased().contains(searchText.lowercased().trimmingCharacters(in: .whitespaces)) }),
                                    id: \.self
                            ) { item in
                                itemRow(item: item)
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
                        if (!newItems.isEmpty && newItems.last?.plu != 1999) {
                            HStack {
                                Text(newItems.last?.name ?? "\u{00A0}")
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
                    // --- NEW VISUAL EFFECTS ---
                    .opacity(isPressed ? 0.6 : 1.0)          // Dims the button when pressed
                    .scaleEffect(isPressed ? 0.98 : 1.0)     // Optional: Adds a subtle "squish" effect
                    .animation(.easeInOut(duration: 0.1), value: isPressed) // Makes the transition smooth
                    // --- UPDATED GESTURES ---
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
    }
    
    
    /*----------------------------------------------\
    |                                               |
    |                   Item Bar                    |
    |                                               |
    \----------------------------------------------*/
    
    var itemBar: some View{
        ScrollView{
            VStack{
                ForEach(
                    session.backendData.items
                        .sorted(by: { (a: UnitouchProduct, b: UnitouchProduct) -> Bool in a.unk3 < b.unk3 })
                        .filter { (it: UnitouchProduct) in it.page == selectedId },
                    id: \.self
                ) { item in
                    itemRow(item: item)
                        
                }
            }
            .padding(.vertical, 8)
        }
        .padding(.horizontal, 8)
    }
    
    @ViewBuilder
    func itemRow(item: UnitouchProduct) -> some View {
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
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(rgbInteger: item.color))
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
    
    func createNewItem(item: UnitouchProduct) {
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
        VStack{
            ScrollView {
                VStack{
                    let combinedItems = session.currentTableItems + newItems
                    ForEach(combinedItems.indices, id: \.self) { index in
                        itemContainer(items: combinedItems, index: index)
                        .onTapGesture {
                            clickedItem = combinedItems[index]
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
                        session.finishTable(newItems: newItems, deletedItems: deletedItems, closeTable: false)
                        
                        session.currentTableItems = []
                        
                        session.state = .main
                    }) {
                        Text("Verplaatsen")
                            .font(.custom("Roboto-Bold", size: 16))
                    }
                }
                HStack{
                    BlankOutlineButton(action: {
                        session.finishTable(newItems: newItems, deletedItems: deletedItems, closeTable: false)
                        
                        session.state = .splitTable
                    }) {
                        Text("Split")
                            .font(.custom("Roboto-Bold", size: 16))
                    }
                    BlankOutlineButton(action: {
                        session.finishTable(newItems: newItems, deletedItems: deletedItems, closeTable: false)
                        session.currentTableItems = []
                        if let currentTable = session.currentTable {
                            session.startPayment(table: currentTable)
                        } else {
                            session.closeTable()
                        }
                        
                    }) {
                        Text("Betalen")
                            .font(.custom("Roboto-Bold", size: 16))
                    }
                }
                PrimaryFilledButton(action: {
                    session.finishTable(newItems: newItems, deletedItems: deletedItems)
                }) {
                    Text("EINDE BESTELLING")
                }
            }
            .padding(.horizontal, 8)
        }
    }
    
    @ViewBuilder
    func itemContainer(items: [NewItem], index: Int) -> some View {
        let item = items[index]
        let nextItem = items.indices.contains(index+1) ? items[index+1] : nil
        let isComment = item.comment
        let nextIsComment = nextItem?.comment ?? false
        let isNewItem = newItems.contains(where: { $0.id == item.id })
        let isDeletedItem = deletedItems.contains(where: { $0.id == item.id })
        
        if isComment {
            HStack{
                Spacer().frame(width: 48)
                Text(item.name)
                    .font(.custom("Roboto-Italic", size: 13))
                    .foregroundStyle(Color.background[600])
                Spacer()
                if(item.price != 0) {
                    Text((Double(item.quantity * item.price)/100).formatted(.currency(code: "EUR")))
                        .font(.custom("Roboto-Italic", size: 13))
                        .foregroundStyle(Color.background[600])
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, nextIsComment ? 2 : 10)
        } else {
            HStack {
                Text("\(item.quantity)x")
                    .font(.custom("Roboto-Bold", size: 18))
                    .foregroundStyle( (isNewItem || isDeletedItem) ? Color.background[800] : Color.background[100])
                    .frame(width: 36, height: 36)
                    .background(isNewItem ? Color.primary[400] : (isDeletedItem ? Color.danger[400] : Color.background[900]))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Text(item.name)
                    .font(.custom("Roboto-Bold", size: 18))
                    .foregroundStyle(Color.background[100])
                
                Spacer()
                Text((Double(item.quantity * item.price)/100).formatted(.currency(code: "EUR")))
                    .foregroundStyle(Color.background[100])
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)
            .padding(.bottom, nextIsComment ? 2 : 10)
        }
        if !nextIsComment {
            Divider()
                .frame(maxWidth: .infinity)
                .background(Color.background[700])
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

func chunkText(_ text: String, maxLength: Int = 20) -> [String] {
    var result: [String] = []
    
    // Convert to Substring for zero-allocation slicing
    var remainingText = text[...]
    
    while !remainingText.isEmpty {
        // 1. Drop leading whitespace for the current line
        remainingText = remainingText.drop(while: { $0.isWhitespace })
        if remainingText.isEmpty { break }
        
        // 2. If the remaining text fits entirely, take it all and finish
        if remainingText.count <= maxLength {
            result.append(String(remainingText))
            break
        }
        
        // 3. Look at the maximum allowed characters for this line
        let prefix = remainingText.prefix(maxLength)
        
        // 4. Find the last space within this limit to avoid breaking words
        if let lastSpaceIndex = prefix.lastIndex(where: { $0.isWhitespace }) {
            
            // Extract the chunk up to the space
            let chunk = remainingText[remainingText.startIndex..<lastSpaceIndex]
            result.append(String(chunk))
            
            // Move the pointer past the space for the next iteration
            remainingText = remainingText[remainingText.index(after: lastSpaceIndex)...]
            
        } else {
            // 5. THE EDGE CASE: No space found within the 19 characters.
            // We must perform a hard split.
            let chunk = remainingText.prefix(maxLength-1)
            result.append(String(chunk))
            
            // Move the pointer exactly 19 characters forward
            remainingText = remainingText.dropFirst(maxLength-1)
        }
    }
    
    return result
}

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


//
//  ContentView.swift
//  unitouch
//
//  Created by Tijn Giesberts on 29/4/25.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var backendManager = BackendManager.shared
    
    @State private var tableNum: String = ""
    @State private var showAlert: Bool = false
    
    var body: some View {
        if backendManager.activeTable != nil {
            TableView()
        }else{
            
            
            GeometryReader { geometry in
                let columns = 4
                let spacing: CGFloat = 8
                let totalSpacing = spacing * CGFloat(columns - 1)
                let itemSize = (geometry.size.width - totalSpacing) / CGFloat(columns)
                
                VStack(alignment: .trailing) {
                    ZStack {
                        Text(tableNum)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .foregroundColor(.black)
                            .font(.title2)
                    }
                    .frame(maxWidth: itemSize*3+spacing*2, minHeight: itemSize, maxHeight: itemSize)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(radius: 2)
                    
                    Grid(horizontalSpacing: spacing, verticalSpacing: spacing) {
                        GridRow {
                            SelectionButton(text: "Tafel", size: itemSize) {
                                if(!backendManager.openTable(table: Int(tableNum) ?? 0))
                                {print("showing alert");showAlert.toggle()}
                                tableNum = ""
                            }
                            SelectionButton(text: "7", size: itemSize)
                                {tableNum += "7"}
                            SelectionButton(text: "8", size: itemSize)
                                {tableNum += "8"}
                            SelectionButton(text: "9", size: itemSize)
                                {tableNum += "9"}
                        }
                        GridRow {
                            SelectionButton(text: "", size: itemSize)
                            SelectionButton(text: "4", size: itemSize)
                                {tableNum += "4"}
                            SelectionButton(text: "5", size: itemSize)
                                {tableNum += "5"}
                            SelectionButton(text: "6", size: itemSize)
                                {tableNum += "6"}
                        }
                        GridRow {
                            SelectionButton(text: "Betalen", size: itemSize)
                            SelectionButton(text: "1", size: itemSize)
                                {tableNum += "1"}
                            SelectionButton(text: "2", size: itemSize)
                                {tableNum += "2"}
                            SelectionButton(text: "3", size: itemSize)
                                {tableNum += "3"}
                        }
                        GridRow {
                            SelectionButton(text: "Verpl.", size: itemSize)
                            SelectionButton(text: "0", size: itemSize)
                            {tableNum += "0"}
                            SelectionButton(text: ".", size: itemSize)
                            SelectionButton(text: "CL", size: itemSize)
                                {tableNum = ""}
                        }
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("Kon tafel niet openen"),
                        message: Text("Er ging iets mis met het openen van de tafel.")
                    )
                }
        }
    }
}


struct SelectionButton: View {
    var text: String
    var width: CGFloat
    var height: CGFloat
    var action: (() -> Void)? = nil
    
    // Custom init for size
    init(text: String, size: CGFloat, action: (() -> Void)? = nil) {
        self.text = text
        self.width = size
        self.height = size
        self.action = action
    }

    // Default memberwise initializer remains available
    init(text: String, width: CGFloat, height: CGFloat, action: (() -> Void)? = nil) {
        self.text = text
        self.width = width
        self.height = height
        self.action = action
    }

    var body: some View {
        Button(action: {
            action?()
        }) {
            ZStack {
                Text(text)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .foregroundColor(.black)
                    .font(.title2)
            }
            .frame(width: width, height: height)
            .background(text == "" ? Color.black : Color.white)
            .cornerRadius(8)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ContentView()
}

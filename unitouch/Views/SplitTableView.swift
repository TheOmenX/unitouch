//
//  SplitTableView.swift
//  unitouch
//
//  Created by Tijn Giesberts on 01/02/2026.
//

import SwiftUI

struct SplitTableView: View {
    @ObservedObject var session: SessionManager
    
    var body: some View {
        ZStack{
            GeometryReader { geometry in
                let columns = 8
                let spacing: CGFloat = 1
                let totalSpacing = spacing * CGFloat(columns - 1)
                let itemSize = (geometry.size.width - totalSpacing) / CGFloat(columns)
                VStack{
                    List {
                        ForEach(session.currentTableItems.indices, id: \.self) { index in
                            HStack {
                                Text("\(session.currentTableItems[index].quantity - session.currentTableItems[index].splitMove)")
                                    .frame(width: itemSize)
                                Text("\(session.currentTableItems[index].splitMove)")
                                    .frame(width: itemSize)
                                Text(session.currentTableItems[index].name)
                                    .frame(width: itemSize*6, alignment: .leading)
                                    .font(session.currentTableItems[index].comment ? .caption : .body )
                                
                            }
                            .frame(maxWidth: .infinity, alignment: .leading) // Stretch full width
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 50, coordinateSpace: .local)
                                    .onEnded { value in
                                        if session.currentTableItems[index].comment {
                                            return
                                        }
                                        
                                        let horizontalAmount = value.translation.width
                                        
                                        var valueChange = 0
                                        
                                        if horizontalAmount < 0 && session.currentTableItems[index].splitMove > 0 { /// Left swipe
                                            print("Left Swipe")
                                            valueChange = -1
                                        } else if horizontalAmount > 0 && session.currentTableItems[index].quantity - session.currentTableItems[index].splitMove > 0 { /// Right swipe
                                            print("Right Swipe")
                                            valueChange = 1
                                        }
                                        
                                        var currentItemIndex = index + 1
                                        session.currentTableItems[index].splitMove += valueChange
                                        while currentItemIndex < session.currentTableItems.count && session.currentTableItems[currentItemIndex].comment == true {
                                            if session.currentTableItems[currentItemIndex].splitMove + valueChange <= session.currentTableItems[currentItemIndex].quantity && session.currentTableItems[currentItemIndex].splitMove + valueChange >= 0 {
                                                session.currentTableItems[currentItemIndex].splitMove += valueChange
                                                currentItemIndex += 1
                                            } else {
                                                return
                                            }
                                        }
                                            
                                        
                                    }
                            )
                        }
                    }
                    .listStyle(.plain)
                    HStack() {
                        SelectionButton(text: "Annuleren", width: itemSize*4 + spacing*3, height: itemSize*2, action1: {
                            session.closeTable()
                        })
                        SelectionButton(text: "Bevestigen", width: itemSize*4 + spacing*3, height: itemSize*2, action1: {
                            session.state = .main
                        })
                    }
                }
            }
        }
        .onAppear(){
            print(session.currentTableItems)
        }
    }
}



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
        VStack{
            ScrollView {
                VStack{
                    ForEach(session.currentTableItems.indices, id: \.self) { index in
                        itemContainer(items: session.currentTableItems, index: index)
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
                    PrimaryFilledButton(action: {
                        session.continueSplitTable(next: .move)
                    }) {
                        Text("Verplaatsen")
                            .font(.custom("Roboto-Bold", size: 16))
                    }
                    PrimaryFilledButton(action: {
                        session.continueSplitTable(next: .pay)
                        
                    }) {
                        Text("Betalen")
                            .font(.custom("Roboto-Bold", size: 16))
                    }
                }
                BlankOutlineButton(action: {
                    session.closeTable()
                }) {
                    Text("Annuleren")
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 24)
        }
    }

    @ViewBuilder
    func itemContainer(items: [NewItem], index: Int) -> some View {
        let item = items[index]
        let nextItem = items.indices.contains(index+1) ? items[index+1] : nil
        let isComment = item.comment
        let nextIsComment = nextItem?.comment ?? false
        
        if isComment {
            HStack{
                Spacer().frame(width: 24)
                Circle()
                    .foregroundStyle(Color.background[600])
                    .frame(width: 14, height: 14)
                    .overlay(
                        Text("\(item.quantity - item.splitMove)")
                            .font(.custom("Roboto-Bold", size: 10))
                            .foregroundStyle(Color.background[800])
                    )
                Spacer().frame(width: 12)
                    
                Text(item.name)
                    .font(.custom("Roboto-Italic", size: 13))
                    .foregroundStyle(Color.background[600])
                Spacer()
                Circle()
                    .foregroundStyle(Color.background[600])
                    .frame(width: 14, height: 14)
                    .overlay(
                        Text("\(item.splitMove)")
                            .font(.custom("Roboto-Bold", size: 10))
                            .foregroundStyle(Color.background[800])
                    )
                Spacer().frame(width: 12)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, nextIsComment ? 2 : 10)
        } else {
            HStack {
                Text("\(item.quantity - item.splitMove)x")
                    .font(.custom("Roboto-Bold", size: 18))
                    .foregroundStyle(Color.background[100])
                    .frame(width: 36, height: 36)
                    .background(Color.background[900])
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Text(item.name)
                    .font(.custom("Roboto-Bold", size: 18))
                
                Spacer()
                Text("\(item.splitMove)x")
                    .font(.custom("Roboto-Bold", size: 18))
                    .foregroundStyle(Color.background[100])
                    .frame(width: 36, height: 36)
                    .background(Color.background[900])
                    .clipShape(RoundedRectangle(cornerRadius: 8))
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



//
//  TableMapView.swift
//  unitouch
//
//  Created by Tijn Giesberts on 18/02/2026.
//

import SwiftUI

/*
struct TableMapView: View {
    @ObservedObject var session: SessionManager
    var nextState: SubTableActions
    @State private var backgroundImage: UIImage? = nil
    
    var body: some View {
        GeometryReader { geometry in
            let columns = 6
            let spacing: CGFloat = 1
            let totalSpacing = spacing * CGFloat(columns - 1)
            let itemSize = (geometry.size.width - totalSpacing) / CGFloat(columns)
            
            VStack{
                TabView {
                    ForEach(session.backendData.backgrounds.sorted(by: { $0.id < $1.id }), id: \.id) { background in
                        imageView(for: background, geometry: geometry)
                    }
                }
                .tabViewStyle(.page)
                HStack{
                    SelectionButton(text: "Terug", width: itemSize*2, height: itemSize, action1: {
                        session.resetState()
                    })
                }
            }
        }
        
    }
    
    func imageView(for background: UnitouchBackground, geometry: GeometryProxy) -> some View {
        ZStack{
            let scalar = geometry.size.width / 165
            let offset = 1 * scalar

            Image(uiImage: background.image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: .infinity, alignment: .top)
            
                
            
            ForEach(session.backendData.tables.filter { $0.BTNfrmCnt == background.id }) { table in
                let rectW = CGFloat(table.BTNw) * scalar
                let rectH = CGFloat(table.BTNh) * scalar
                let centerX = CGFloat(table.BTNx) * scalar + rectW / 2 + offset
                let centerY = CGFloat(table.BTNy) * scalar + rectH / 2 + offset
                let tableKey = "\(table.BTNaccNum)0"
                let tableStatus = session.openTables.first(where: { $0.tableInfo.formatTableFlat == tableKey })?.status ?? 0
                let fillIntColor = session.backendData.tableColors.first(where: { "\($0.BTNStatus)" == "\(tableStatus)" })?.BTNFill ?? 65280
                let textIntColor = session.backendData.tableColors.first(where: { "\($0.BTNStatus)" == "\(tableStatus)" })?.BTNText ?? 16711680
                
                Rectangle()
                    .fill(Color(rgbInteger: fillIntColor))
                    .frame(width: rectW, height: rectH)
                    .position(x: centerX, y: centerY)
                    .onTapGesture {
                        if let table = TableInfo(flatTable: "\(table.BTNaccNum)0") {
                            session.checkSubTable(table: table, nextState: nextState)
                        } else {
                            session.activeError = .openTableFailed(details: "Tafel kon niet worden geopend, er ging iets mis bij het verwerken van de tafelgegevens.")
                        }
                    }
            
                Text(table.BTNlabel)
                    .foregroundColor(Color(rgbInteger: textIntColor))
                    .position(x: centerX, y: centerY)
                    
                
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}
 */


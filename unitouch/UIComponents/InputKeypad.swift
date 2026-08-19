//
//  InputKeypad.swift
//  unitouch
//
//  Created by Tijn Giesberts on 31/03/2026.
//

import SwiftUI

struct InputKeypad: View {
    @Binding var input: String
    var inputValidation: (String) -> Bool = { _ in true }
    
    var body: some View {
        ZStack {
            VStack{
                ForEach(1...3, id: \.self) { row in
                    HStack{
                        ForEach(1...3, id: \.self) { column in
                            let number = (row - 1) * 3 + column
                            Button(action: {
                                let candidate = input + "\(number)"
                                if inputValidation(candidate) {
                                    input.append("\(number)")
                                }
                            }) {
                                Text("\(number)")
                                    .frame(width: 90, height: 70)
                                    .background(Color.background[800])
                                    .cornerRadius(12)
                                    .font(.custom("Roboto-Bold", size: 34))
                            }
                            .padding(3)
                        }
                    }
                }
                
                HStack{
                    Button(action: {
                        let candidate = input + "."
                        if inputValidation(candidate) {
                            input.append(".")
                        }
                    }) {
                        Text(".")
                            .frame(width: 90, height: 70)
                            .background(Color.background[800])
                            .cornerRadius(12)
                            .bold()
                            .font(.title)
                        
                    }.padding(3)
                    
                    Button(action: {
                        let candidate = input + "0"
                        if inputValidation(candidate) {
                            input.append("0")
                        }
                    }) {
                        Text("0")
                            .frame(width: 90, height: 70)
                            .background(Color.background[800])
                            .cornerRadius(12)
                            .bold()
                            .font(.title)
                    }.padding(3)
                    
                    Button(action: {
                        input = ""
                    }) {
                        Image(systemName: "trash")
                            .frame(width: 90, height: 70)
                            .foregroundStyle(.red)
                            .font(.system(size: 30))
                            
                    }
                    .padding(3)
                }
            }
        }
    }
}

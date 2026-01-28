//
//  CustomAlertView.swift
//  unitouch
//
//  Created by Tijn Giesberts on 24/05/2025.
//

import SwiftUI

struct CustomAlertView: View {
    @Environment(\.colorScheme) var colorScheme

    let title: String
    let description: String

    var cancelAction: (() -> Void)?
    var cancelActionTitle: String?

    var primaryAction: (() -> Void)?
    var primaryActionTitle: String?

    @Binding var inputText: String
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text(title)
                    .font(.headline)
                    .padding(.top)

                if !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                TextField("Enter password", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .focused($isTextFieldFocused)
                    .keyboardType(.numberPad)

                Divider()

                HStack {
                    if let cancelAction, let cancelActionTitle {
                        Button(cancelActionTitle, action: cancelAction)
                            .frame(maxWidth: .infinity)
                    }

                    if cancelActionTitle != nil && primaryActionTitle != nil {
                        Divider()
                    }

                    if let primaryAction, let primaryActionTitle {
                        Button(primaryActionTitle, action: primaryAction)
                            .frame(maxWidth: .infinity)
                            .bold()
                    }
                }
                .frame(height: 44)
            }
            .frame(maxWidth: 300)
            .background(.ultraThickMaterial)
            .cornerRadius(12)
            .onAppear {
                DispatchQueue.main.async {
                    isTextFieldFocused = true
                }
            }
        }
    }
}

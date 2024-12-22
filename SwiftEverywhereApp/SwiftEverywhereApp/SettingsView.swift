//
//  SettingsView.swift
//  SwiftEverywhereApp
//
//  Created by Bill Gestrich on 12/21/24.
//

import Combine
import SECommon
import SwiftUI

struct SettingsView: View {
    let viewModel: DevicesViewModel
    let urlStore: URLStore
    @Environment(\.dismiss) private var dismiss
    @State private var newURL: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Server URLs")) {
                    List {
                        ForEach(urlStore.serverURLs.indices, id: \.self) { index in
                            HStack {
                                Text(urlStore.serverURLs[index])
                                Spacer()
                                if urlStore.selectedServerIndex == index {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .onTapGesture {
                                urlStore.selectedServerIndex = index
                                dismiss()
                            }
                        }
                        .onDelete { offsets in
                            urlStore.serverURLs.remove(atOffsets: offsets)
                            if urlStore.selectedServerIndex >= urlStore.serverURLs.count {
                                urlStore.selectedServerIndex = max(0, urlStore.serverURLs.count - 1)
                            }
                        }
                    }
                }
                
                Section(header: Text("Add New Server")) {
                    TextField("New Server URL", text: $newURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                    Button("Add") {
                        guard !newURL.isEmpty else { return }
                        urlStore.serverURLs.append(newURL)
                        newURL = ""
                    }
                    .disabled(newURL.isEmpty)
                }
                Section {
                    Button("Push Notification Test") {
                        Task {
                            let notification = PushNotification(title: "My Title", subtitle: "My Subtitle", message: "My Message: \(Date().description)")
                            do {
                                try await viewModel.apiClient?.sendPushNotification(notification)
                            } catch {
                                print(error)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

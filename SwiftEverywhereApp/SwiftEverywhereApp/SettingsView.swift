//
//  SettingsView.swift
//  SwiftEverywhereApp
//
//  Created by Bill Gestrich on 12/21/24.
//

import Combine
import SwiftUI

struct SettingsView: View {
    @ObservedObject var urlStore: URLStore
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

class URLStore: ObservableObject {
    @Published var serverURLs: [String]
    @Published var selectedServerIndex: Int
    
    private let urlsKey = "serverURLs"
    private let selectedIndexKey = "selectedServerIndex"
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        // Load stored data or provide defaults
        if let data = UserDefaults.standard.data(forKey: urlsKey),
           let urls = try? JSONDecoder().decode([String].self, from: data) {
            self.serverURLs = urls
        } else {
            self.serverURLs = []
        }
        
        self.selectedServerIndex = UserDefaults.standard.integer(forKey: selectedIndexKey)
        
        // Save changes automatically when values change
        $serverURLs
            .sink { [weak self] urls in
                guard let self else { return }
                if let data = try? JSONEncoder().encode(urls) {
                    UserDefaults.standard.set(data, forKey: self.urlsKey)
                }
            }
            .store(in: &cancellables)
        
        $selectedServerIndex
            .sink { [weak self] index in
                guard let self else { return }
                UserDefaults.standard.set(index, forKey: self.selectedIndexKey)
            }
            .store(in: &cancellables)
    }
}

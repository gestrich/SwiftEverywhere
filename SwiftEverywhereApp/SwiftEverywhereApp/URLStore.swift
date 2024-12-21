//
//  URLStore.swift
//  SwiftEverywhereApp
//
//  Created by Bill Gestrich on 12/21/24.
//

import SwiftUI

@Observable
class URLStore {
    var urlStoreUpdated: (() -> Void)?
    var serverURLs: [String] {
        didSet {
            if let data = try? JSONEncoder().encode(serverURLs) {
                UserDefaults.standard.set(data, forKey: urlsKey)
            }
        }
    }
    var selectedServerIndex: Int {
        didSet {
            UserDefaults.standard.set(selectedServerIndex, forKey: selectedIndexKey)
            urlStoreUpdated?()
        }
    }
    
    private let urlsKey = "serverURLs"
    private let selectedIndexKey = "selectedServerIndex"
    
    init() {
        if let data = UserDefaults.standard.data(forKey: urlsKey),
           let urls = try? JSONDecoder().decode([String].self, from: data) {
            self.serverURLs = urls
        } else {
            self.serverURLs = []
        }
        
        self.selectedServerIndex = UserDefaults.standard.integer(forKey: selectedIndexKey)
    
    }
}

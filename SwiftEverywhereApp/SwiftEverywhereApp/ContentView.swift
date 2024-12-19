import Charts
import Combine
import Foundation
import SECommon
import SwiftUI

struct ContentView: View {
    @StateObject var urlStore = URLStore()
    @State var channel1Readings = [AnalogReading]()
    @State var channel2Readings = [AnalogReading]()
    @State var ledState: LEDState = LEDState(on: false)
    @State var channel1Reading = AnalogReading(channel: Self.channel1, uploadDate: Date(), value: 0.0)
    @State var channel2Reading  = AnalogReading(channel: Self.channel2, uploadDate: Date(), value: 0.0)
    @State private var showSettings = false
    @State var viewLoaded = false
    @State var timer: Timer?
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Button {
                        Task {
                            do {
                                try await toggleLEDState()
                                try await loadLEDState()
                            } catch {
                                print("Error: \(error)")
                            }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "lightbulb.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundStyle(ledState.on ? Color.yellow : Color.gray )
                                .frame(width: 25)
                        }
                    }
                }
                Section("Light Sensor") {
                    Text(formatToTwoDecimals(channel1Reading.value) + "%")
                    Chart {
                        ForEach(channel1Readings) {
                            BarMark(
                                x: .value("Date", $0.uploadDate),
                                y: .value("Reading", $0.value)
                            )
                        }
                    }
                    .chartXAxis {
                        AxisMarks(format: Date.FormatStyle.dateTime.hour(),
                                  values: .automatic(desiredCount: 8))
                    }
                }
                Section("Temperature Sensor") {
                    Text(formatToTwoDecimals(channel2Reading.value) + "%")
                    Chart {
                        ForEach(channel2Readings) {
                            BarMark(
                                x: .value("Date", $0.uploadDate),
                                y: .value("Reading", $0.value)
                            )
                        }
                    }
                    .chartXAxis {
                        AxisMarks(format: Date.FormatStyle.dateTime.hour(),
                                  values: .automatic(desiredCount: 8))
                    }
                }
                Section {
                    if urlStore.serverURLs.indices.contains(urlStore.selectedServerIndex) {
                        Text("Connected to: \(urlStore.serverURLs[urlStore.selectedServerIndex])")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(.top)
                    }
                }
            }.opacity(viewLoaded ? 1.0 : 0.0)
            .navigationTitle("Swift Everywhere")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Settings") {
                        showSettings = true
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            try await loadStates()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(urlStore: urlStore)
        }
        .task {
            do {
                try await loadStates()
            } catch {
                print("Error: \(error)")
            }
            viewLoaded = true
        }
        .onChange(of: scenePhase) { (oldPhase, newPhase) in
            if newPhase == .active {
                Task {
                    try await loadStates()
                }
            }
        }
        .onAppear {
            timer = Timer(timeInterval: 60.0, repeats: true, block: { _ in
                Task {
                    try await loadStates()
                }
            })
        }
    }
    
    func loadStates() async throws {
        try await loadLEDState()
        try await loadChannel1Reading()
        try await loadChannel2Reading()
        try await loadChannel1Readings()
        try await loadChannel2Readings()
    }
    
    @MainActor
    func loadChannel1Reading() async throws {
        guard let apiClient else {
            throw ContentViewError.missingBaseURL
        }
        channel1Reading = try await apiClient.getAnalogReading(channel: Self.channel1)
    }
    
    @MainActor
    func loadLEDState() async throws {
        guard let apiClient else {
            throw ContentViewError.missingBaseURL
        }
        self.ledState = try await apiClient.getLEDState()
    }
    
    @MainActor
    func loadChannel2Reading() async throws {
        guard let apiClient else {
            throw ContentViewError.missingBaseURL
        }
        self.channel2Reading = try await apiClient.getAnalogReading(channel: Self.channel2)
    }
    
    @MainActor
    func loadChannel1Readings() async throws {
        guard let apiClient else {
            throw ContentViewError.missingBaseURL
        }
        self.channel1Readings = try await apiClient.getAnalogReadings(channel: Self.channel1, range: DateRangeRequest(startDate: Date().addingTimeInterval(-60 * 60 * 24), endDate: Date()))
    }
    
    @MainActor
    func loadChannel2Readings() async throws {
        guard let apiClient else {
            throw ContentViewError.missingBaseURL
        }
        self.channel2Readings = try await apiClient.getAnalogReadings(channel: Self.channel2, range: DateRangeRequest(startDate: Date().addingTimeInterval(-60 * 60 * 24), endDate: Date()))
    }
    
    @MainActor
    func toggleLEDState() async throws {
        guard let apiClient else {
            throw ContentViewError.missingBaseURL
        }
        let newState = LEDState(on: !ledState.on)
        try await apiClient.updateLEDState(newState)
        try await loadLEDState()
    }
    
    func formatToTwoDecimals(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2

        return formatter.string(for: number) ?? "N/A"
    }

    static var channel1: Int {
        return 2
    }
    
    static var channel2: Int {
        return 2
    }
    
    var apiClient: PiClientAPIImplementation? {
        guard urlStore.serverURLs.indices.contains(urlStore.selectedServerIndex),
              let url = URL(string: urlStore.serverURLs[urlStore.selectedServerIndex]) else {
            return nil
        }
        
        return PiClientAPIImplementation(baseURL: url)
    }
    
    enum ContentViewError: Error {
        case missingBaseURL
    }
}

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

extension AnalogReading: @retroactive Identifiable {
    public var id: Date {
        return uploadDate
    }
}

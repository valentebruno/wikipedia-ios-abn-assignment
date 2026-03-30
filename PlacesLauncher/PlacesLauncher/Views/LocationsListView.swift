import SwiftUI

@MainActor
struct LocationsListView: View {
    private enum ActiveSheet: String, Identifiable {
        case customCoordinates
        case accessibility

        var id: String { rawValue }
    }

    @StateObject private var viewModel: LocationsViewModel
    @State private var activeSheet: ActiveSheet?
    @AppStorage("accessibility.prefersLargeText") private var prefersLargeText = false
    @AppStorage("accessibility.prefersHighContrast") private var prefersHighContrast = false
    @AppStorage("accessibility.prefersReduceMotion") private var prefersReduceMotion = false
    @AppStorage("accessibility.speakCoordinatesInLabels") private var speakCoordinatesInLabels = true

    init(viewModel: LocationsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    init() {
        _viewModel = StateObject(wrappedValue: LocationsViewModel())
    }

    var body: some View {
        NavigationStack {
            content
            .navigationTitle("ABN AMRO Places")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reload") {
                        Task {
                            await viewModel.loadLocations()
                        }
                    }
                    .accessibilityHint("Fetches locations again from the remote JSON endpoint.")
                    .accessibilityIdentifier("toolbar.reload")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Custom Coordinates") {
                        activeSheet = .customCoordinates
                    }
                    .accessibilityHint("Opens a form where you can enter latitude and longitude.")
                    .accessibilityIdentifier("toolbar.customCoordinates")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        activeSheet = .accessibility
                    } label: {
                        Image(systemName: "accessibility")
                    }
                    .accessibilityLabel("Accessibility settings")
                    .accessibilityHint("Adjust text size, contrast, and motion preferences for this app.")
                    .accessibilityIdentifier("toolbar.accessibility")
                }
            }
        }
        .searchable(
            text: searchQueryBinding,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search list or any place name"
        )
        .onSubmit(of: .search) {
            Task {
                _ = await viewModel.searchLocationByName()
            }
        }
        .transaction { transaction in
            if prefersReduceMotion {
                transaction.animation = nil
            }
        }
        .task {
            await viewModel.loadIfNeeded()
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .customCoordinates:
                CustomCoordinateView(viewModel: viewModel)
            case .accessibility:
                AccessibilitySettingsView()
            }
        }
        .alert(
            "Unable to Open Wikipedia",
            isPresented: Binding(
                get: { viewModel.alertMessage != nil },
                set: { shouldPresent in
                    if !shouldPresent {
                        viewModel.dismissAlert()
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                viewModel.dismissAlert()
            }
        } message: {
            Text(viewModel.alertMessage ?? "Unknown error.")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            ProgressView("Loading locations...")
                .accessibilityLabel("Loading locations")
        case .loaded:
            locationsList
        case .failed(let message):
            ContentUnavailableView(
                "Couldn’t Load Locations",
                systemImage: "wifi.slash",
                description: Text(message)
            )
        }
    }

    private var locationsList: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Location Access Is Optional", systemImage: "location.slash")
                        .font(prefersLargeText ? .headline : .subheadline)
                        .foregroundStyle(prefersHighContrast ? .primary : .secondary)

                    Text("Search by name and coordinate deep links work without location permission. Enable location only if you want to recenter on your current position in Wikipedia.")
                        .font(prefersLargeText ? .body : .footnote)
                        .foregroundStyle(prefersHighContrast ? .primary : .secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Location access is optional. Search and coordinate opening work without permission. Enable location only for recentering.")
                .accessibilityIdentifier("banner.locationOptional")
                .padding(.vertical, 4)
            }

            if !trimmedSearchQuery.isEmpty {
                Section("Search by Name (Geocoding)") {
                    geocodingActionButton
                    geocodingResultContent
                }
            }

            Section("Assignment Locations") {
                if filteredLocations.isEmpty {
                    Text("No assignment locations match this search.")
                        .font(prefersLargeText ? .body : .callout)
                        .foregroundStyle(prefersHighContrast ? .primary : .secondary)
                        .accessibilityLabel("No assignment locations match this search")
                } else {
                    ForEach(filteredLocations) { location in
                        locationRow(for: location)
                    }
                }
            }
        }
        .accessibilityLabel("List of assignment locations")
        .accessibilityIdentifier("list.locations")
    }

    private var geocodingActionButton: some View {
        Button {
            Task {
                _ = await viewModel.searchLocationByName()
            }
        } label: {
            if case .searching = viewModel.geocodingState {
                Label("Searching \"\(trimmedSearchQuery)\"...", systemImage: "hourglass")
            } else {
                Label("Find \"\(trimmedSearchQuery)\" Coordinates", systemImage: "magnifyingglass.circle")
            }
        }
        .disabled(trimmedSearchQuery.isEmpty || isGeocodingInFlight)
        .accessibilityHint("Uses geocoding to resolve the typed name into coordinates.")
        .accessibilityIdentifier("geocode.findButton")
    }

    @ViewBuilder
    private var geocodingResultContent: some View {
        switch viewModel.geocodingState {
        case .idle:
            Text("Type a place name above and run geocoding to open it in Wikipedia.")
                .font(prefersLargeText ? .body : .footnote)
                .foregroundStyle(prefersHighContrast ? .primary : .secondary)
        case .searching:
            ProgressView("Searching coordinates...")
        case .found(let location):
            VStack(alignment: .leading, spacing: 10) {
                Text(location.name)
                    .font(prefersLargeText ? .title3 : .headline)
                Text(location.coordinateDescription)
                    .font(prefersLargeText ? .body : .caption)
                    .foregroundStyle(prefersHighContrast ? .primary : .secondary)

                Button("Open Found Place in Wikipedia") {
                    Task {
                        _ = await viewModel.openGeocodedLocation()
                    }
                }
                .accessibilityHint("Opens the geocoded place in Wikipedia Places.")
                .accessibilityIdentifier("geocode.openFoundButton")
            }
            .padding(.vertical, 4)
        case .failed(let message):
            Text(message)
                .font(prefersLargeText ? .body : .footnote)
                .foregroundStyle(.red)
                .accessibilityLabel("Geocoding failed: \(message)")
        }
    }

    private func locationRow(for location: LocationItem) -> some View {
        Button {
            Task {
                _ = await viewModel.openWikipedia(for: location)
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(location.name)
                    .font(prefersLargeText ? .title3 : .headline)
                Text(location.coordinateDescription)
                    .font(prefersLargeText ? .body : .caption)
                    .foregroundStyle(prefersHighContrast ? .primary : .secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(for: location))
        .accessibilityHint("Opens this location in Wikipedia Places.")
        .accessibilityIdentifier("locationRow")
    }

    private var searchQueryBinding: Binding<String> {
        Binding(
            get: { viewModel.locationSearchQuery },
            set: { updatedValue in
                viewModel.updateLocationSearchQuery(updatedValue)
            }
        )
    }

    private var trimmedSearchQuery: String {
        viewModel.locationSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var filteredLocations: [LocationItem] {
        guard !trimmedSearchQuery.isEmpty else {
            return viewModel.locations
        }
        return viewModel.locations.filter { location in
            location.name.localizedCaseInsensitiveContains(trimmedSearchQuery)
        }
    }

    private var isGeocodingInFlight: Bool {
        if case .searching = viewModel.geocodingState {
            return true
        }
        return false
    }

    private func accessibilityLabel(for location: LocationItem) -> String {
        if speakCoordinatesInLabels {
            return "\(location.name), \(location.coordinateDescription)"
        }
        return location.name
    }
}

@MainActor
struct CustomCoordinateView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: LocationsViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("Coordinates") {
                    TextField("Latitude (e.g. 52.3676)", text: $viewModel.customLatitude)
                        .keyboardType(.numbersAndPunctuation)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .accessibilityLabel("Latitude")
                        .accessibilityIdentifier("customCoordinates.latitude")

                    TextField("Longitude (e.g. 4.9041)", text: $viewModel.customLongitude)
                        .keyboardType(.numbersAndPunctuation)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .accessibilityLabel("Longitude")
                        .accessibilityIdentifier("customCoordinates.longitude")
                }

                Section {
                    Button("Open in Wikipedia") {
                        Task {
                            if await viewModel.openCustomCoordinate() {
                                dismiss()
                            }
                        }
                    }
                    .disabled(isInputEmpty)
                    .accessibilityHint("Opens the entered coordinate in Wikipedia Places.")
                    .accessibilityIdentifier("customCoordinates.openButton")
                }
            }
            .navigationTitle("Custom Coordinates")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityIdentifier("customCoordinates.doneButton")
                }
            }
        }
    }

    private var isInputEmpty: Bool {
        viewModel.customLatitude.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            viewModel.customLongitude.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct AccessibilitySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("accessibility.prefersLargeText") private var prefersLargeText = false
    @AppStorage("accessibility.prefersHighContrast") private var prefersHighContrast = false
    @AppStorage("accessibility.prefersReduceMotion") private var prefersReduceMotion = false
    @AppStorage("accessibility.speakCoordinatesInLabels") private var speakCoordinatesInLabels = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Display") {
                    Toggle("Larger text in lists", isOn: $prefersLargeText)
                        .accessibilityIdentifier("accessibility.largerText")
                    Toggle("Higher contrast labels", isOn: $prefersHighContrast)
                        .accessibilityIdentifier("accessibility.higherContrast")
                    Toggle("Reduce motion", isOn: $prefersReduceMotion)
                        .accessibilityIdentifier("accessibility.reduceMotion")
                }

                Section("VoiceOver") {
                    Toggle("Read coordinates with location name", isOn: $speakCoordinatesInLabels)
                        .accessibilityIdentifier("accessibility.readCoordinates")
                }

                Section {
                    Text("These settings apply only inside PlacesLauncher.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Accessibility")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityIdentifier("accessibility.doneButton")
                }
            }
        }
    }
}

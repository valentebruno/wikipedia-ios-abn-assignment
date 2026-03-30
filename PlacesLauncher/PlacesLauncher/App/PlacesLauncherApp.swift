import SwiftUI

@main
struct PlacesLauncherApp: App {
    var body: some Scene {
        WindowGroup {
            rootView
        }
    }

    @MainActor
    @ViewBuilder
    private var rootView: some View {
        if ProcessInfo.processInfo.arguments.contains("-ui-test-mode") {
            LocationsListView(viewModel: makeUITestViewModel())
        } else {
            LocationsListView()
        }
    }

    @MainActor
    private func makeUITestViewModel() -> LocationsViewModel {
        LocationsViewModel(
            repository: UITestLocationsRepository(),
            appOpener: UITestExternalAppOpener(),
            geocoder: UITestLocationGeocoder()
        )
    }
}

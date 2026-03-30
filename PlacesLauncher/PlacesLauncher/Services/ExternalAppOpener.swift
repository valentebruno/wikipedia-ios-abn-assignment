import Foundation
import UIKit

protocol ExternalAppOpening {
    func open(_ url: URL) async throws
}

enum ExternalAppOpenError: Error, Equatable {
    case appUnavailable
    case openFailed
}

extension ExternalAppOpenError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .appUnavailable:
            return "Wikipedia is not installed or cannot be opened on this device."
        case .openFailed:
            return "Wikipedia could not be opened."
        }
    }
}

struct UIApplicationExternalAppOpener: ExternalAppOpening {
    func open(_ url: URL) async throws {
        guard await canOpen(url) else {
            throw ExternalAppOpenError.appUnavailable
        }

        let didOpen = await openOnMainActor(url)

        guard didOpen else {
            throw ExternalAppOpenError.openFailed
        }
    }

    @MainActor
    private func canOpen(_ url: URL) -> Bool {
        UIApplication.shared.canOpenURL(url)
    }

    @MainActor
    private func openOnMainActor(_ url: URL) async -> Bool {
        await withCheckedContinuation { continuation in
            UIApplication.shared.open(url, options: [:]) { success in
                continuation.resume(returning: success)
            }
        }
    }
}

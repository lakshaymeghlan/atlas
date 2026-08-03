import Foundation
import Observation
import os

/// Holds the current match queue and the accept/reject actions. Prototype only —
/// in-memory, seeded with samples; the backend feeds these later.
@MainActor
@Observable
final class JobsStore {
    var matches: [JobMatch] = JobMatch.samples

    private let log = Logger(subsystem: "ai.sofsuite.atlas", category: "jobs")

    func reject(_ id: UUID) {
        matches.removeAll { $0.id == id }
    }

    /// Accept a match. `note` is an optional message to the company.
    func accept(_ id: UUID, note: String?) {
        guard let match = matches.first(where: { $0.id == id }) else { return }
        matches.removeAll { $0.id == id }
        log.info("Accepted \(match.role, privacy: .public) @ \(match.company, privacy: .public); note: \(note != nil ? "yes" : "no", privacy: .public)")
    }
}

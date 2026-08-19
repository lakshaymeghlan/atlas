import Foundation
import Observation
import os

/// Holds the current match queue and the accept/reject actions. Prototype only —
/// in-memory, seeded with samples; the backend feeds these later.
@MainActor
@Observable
final class JobsStore {
    var matches: [JobMatch] = JobMatch.samples
    /// Bookmarked roles — independent of pass/accept.
    var saved: [JobMatch] = []
    /// Companies you're in the pipeline with — shown on the Journey tab.
    var applications: [Application] = Application.samples

    private let log = Logger(subsystem: "canopy.ai", category: "jobs")

    func isSaved(_ id: UUID) -> Bool { saved.contains { $0.id == id } }

    func toggleSave(_ match: JobMatch) {
        if let i = saved.firstIndex(where: { $0.id == match.id }) {
            saved.remove(at: i)
        } else {
            saved.append(match)
        }
    }

    func reject(_ id: UUID) {
        matches.removeAll { $0.id == id }
    }

    /// Accept a match. `note` is an optional message to the company. Adds the
    /// company to your Journey at the "Applied" stage.
    func accept(_ id: UUID, note: String?) {
        guard let match = matches.first(where: { $0.id == id }) else { return }
        matches.removeAll { $0.id == id }
        if !applications.contains(where: { $0.id == id }) {
            applications.insert(Application(match: match, stage: .applied, note: note), at: 0)
        }
        log.info("Accepted \(match.role, privacy: .public) @ \(match.company, privacy: .public); note: \(note != nil ? "yes" : "no", privacy: .public)")
    }

    /// Attach the note written on the accept sheet — the accept itself already
    /// happened, so this lands on the existing application.
    func setNote(_ note: String, for id: UUID) {
        guard let i = applications.firstIndex(where: { $0.id == id }) else { return }
        applications[i].note = note
        log.info("Note attached for \(applications[i].match.company, privacy: .public)")
    }
}

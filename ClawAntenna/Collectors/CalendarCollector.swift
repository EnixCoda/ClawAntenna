import Foundation
import EventKit
import SwiftData
import os

/// Monitors calendar — counts today's events and all-day events.
/// Samples hourly.
@Observable
final class CalendarCollector: DataCollector {
    let id = "calendar"
    let name = "Calendar"
    let icon = "calendar"
    let description = "Free/busy status, event count"

    private let logger = Logger(subsystem: "co.enix.ClawAntenna", category: "CalendarCollector")
    private let modelContainer: ModelContainer
    private let eventStore = EKEventStore()
    private var timer: Timer?
    private var pendingStart = false

    private(set) var isRunning = false
    var lastError: String?

    var isAvailable: Bool { true }

    private(set) var permissionStatus: CollectorPermissionStatus = .notDetermined

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        refreshPermissionStatus()
    }

    func refreshPermissionStatus() {
        permissionStatus = switch EKEventStore.authorizationStatus(for: .event) {
        case .notDetermined: .notDetermined
        case .restricted: .restricted
        case .denied: .denied
        case .fullAccess: .authorized
        case .writeOnly: .limited
        @unknown default: .notDetermined
        }
    }

    func requestPermission() {
        eventStore.requestFullAccessToEvents { [weak self] _, _ in
            guard let self else { return }
            Task { @MainActor in
                self.refreshPermissionStatus()
                if self.pendingStart { self.start() }
            }
        }
    }

    func start() {
        if permissionStatus == .notDetermined {
            pendingStart = true
            requestPermission()
            return
        }
        guard permissionStatus.isGranted else {
            logger.warning("Cannot start without Calendar permission")
            pendingStart = false
            return
        }
        pendingStart = false

        timer = Timer.scheduledTimer(withTimeInterval: 60 * 60, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.recordCalendar() }
        }

        recordCalendar()
        isRunning = true
        logger.info("Started calendar monitoring (hourly)")
    }

    func stop() {
        pendingStart = false
        timer?.invalidate()
        timer = nil
        isRunning = false
        logger.info("Stopped calendar monitoring")
    }

    private func recordCalendar() {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        let events = eventStore.events(matching: predicate)

        let allDayCount = events.filter(\.isAllDay).count

        let context = ModelContext(modelContainer)
        let record = CalendarRecord(eventCount: events.count, allDayCount: allDayCount)
        context.insert(record)
        do {
            try context.save()
        } catch {
            lastError = error.localizedDescription
            logger.error("Failed to save calendar record: \(error.localizedDescription)")
        }
    }
}

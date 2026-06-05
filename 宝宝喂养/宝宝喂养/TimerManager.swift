import SwiftUI

@Observable
class TimerManager {
    static let shared = TimerManager()

    var isFeedingRunning = false
    var feedingStartTime: Date?
    var feedingElapsed: TimeInterval = 0
    var feedingAccumulated: TimeInterval = 0
    var feedingSelectedSide = 0
    var feedingLeftDuration: TimeInterval = 0
    var feedingRightDuration: TimeInterval = 0
    var feedingHasRecordedLeft = false
    var feedingHasRecordedRight = false

    var isSleeping = false
    var sleepStartTime: Date?
    var sleepElapsed: TimeInterval = 0

    private var feedingTimer: Timer?
    private var sleepTimer: Timer?

    var hasFeedingDuration: Bool {
        feedingHasRecordedLeft || feedingHasRecordedRight || feedingAccumulated > 0 || feedingElapsed > 0
    }

    var feedingTotalDuration: TimeInterval {
        feedingLeftDuration + feedingRightDuration + (isFeedingRunning ? feedingElapsed : feedingAccumulated)
    }

    var feedingCurrentSideDuration: TimeInterval {
        isFeedingRunning ? feedingElapsed : feedingAccumulated
    }

    func startFeeding(side: Int) {
        if side != feedingSelectedSide && (feedingHasRecordedLeft || feedingHasRecordedRight || feedingAccumulated > 0) {
            commitFeedingSide()
        }
        feedingSelectedSide = side
        feedingStartTime = Date()
        feedingElapsed = feedingAccumulated
        isFeedingRunning = true
        startFeedingTimer()
    }

    func pauseFeeding() {
        stopFeedingTimer()
        isFeedingRunning = false
        if let start = feedingStartTime {
            feedingAccumulated += Date().timeIntervalSince(start)
        }
        feedingStartTime = nil
        feedingElapsed = feedingAccumulated
    }

    func switchFeedingSide(_ side: Int) {
        guard side != feedingSelectedSide else { return }
        let shouldContinue = isFeedingRunning
        if isFeedingRunning {
            stopFeedingTimer()
            if let start = feedingStartTime {
                feedingAccumulated += Date().timeIntervalSince(start)
            }
            feedingStartTime = nil
            isFeedingRunning = false
        }
        commitFeedingSide()
        feedingSelectedSide = side
        feedingAccumulated = 0
        feedingElapsed = 0

        if shouldContinue {
            startFeeding(side: side)
        }
    }

    func resetFeeding() {
        stopFeedingTimer()
        isFeedingRunning = false
        feedingStartTime = nil
        feedingElapsed = 0
        feedingAccumulated = 0
        feedingSelectedSide = 0
        feedingLeftDuration = 0
        feedingRightDuration = 0
        feedingHasRecordedLeft = false
        feedingHasRecordedRight = false
    }

    func saveFeedingManually(minutes: Int) {
        guard minutes > 0 else { return }
        stopFeedingTimer()
        isFeedingRunning = false
        feedingStartTime = nil

        let duration = TimeInterval(minutes * 60)
        if feedingSelectedSide == 0 {
            feedingLeftDuration += duration
            feedingHasRecordedLeft = true
        } else {
            feedingRightDuration += duration
            feedingHasRecordedRight = true
        }
        feedingAccumulated = 0
        feedingElapsed = feedingLeftDuration + feedingRightDuration
    }

    func finishFeeding() {
        pauseFeeding()
        commitFeedingSide()
        feedingElapsed = feedingLeftDuration + feedingRightDuration
    }

    private func commitFeedingSide() {
        let duration = feedingAccumulated
        guard duration > 0 else { return }
        if feedingSelectedSide == 0 {
            feedingLeftDuration += duration
            feedingHasRecordedLeft = true
        } else {
            feedingRightDuration += duration
            feedingHasRecordedRight = true
        }
        feedingAccumulated = 0
    }

    private func startFeedingTimer() {
        stopFeedingTimer()
        feedingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, let start = self.feedingStartTime else { return }
            self.feedingElapsed = self.feedingAccumulated + Date().timeIntervalSince(start)
        }
    }

    private func stopFeedingTimer() {
        feedingTimer?.invalidate()
        feedingTimer = nil
    }

    func startSleep(at startTime: Date = Date()) {
        sleepStartTime = startTime
        isSleeping = true
        sleepElapsed = max(0, Date().timeIntervalSince(startTime))
        startSleepTimer()
    }

    func stopSleep() {
        stopSleepTimer()
        if let start = sleepStartTime {
            sleepElapsed = Date().timeIntervalSince(start)
        }
        isSleeping = false
    }

    func resetSleep() {
        stopSleepTimer()
        isSleeping = false
        sleepStartTime = nil
        sleepElapsed = 0
    }

    private func startSleepTimer() {
        stopSleepTimer()
        sleepTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, let start = self.sleepStartTime else { return }
            self.sleepElapsed = Date().timeIntervalSince(start)
        }
    }

    private func stopSleepTimer() {
        sleepTimer?.invalidate()
        sleepTimer = nil
    }
}

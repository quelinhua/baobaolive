import Testing
import Foundation
@testable import 宝宝生活记录

extension Tag {
    @Tag static var model: Self
    @Tag static var timer: Self
}

// MARK: - RecordType Tests

struct RecordTypeTests {

    @Test(.tags(.model))
    func allCasesContains12Types() {
        #expect(RecordType.allCases.count == 12)
    }

    @Test(.tags(.model))
    func idMatchesRawValue() {
        for type in RecordType.allCases {
            #expect(type.id == type.rawValue)
        }
    }

    @Test(.tags(.model))
    func defaultHomePageContains6Types() {
        let defaults = RecordType.defaultHomePage
        #expect(defaults.count == 6)
        #expect(defaults.contains("feeding"))
        #expect(defaults.contains("sleep"))
        #expect(defaults.contains("diaper"))
        #expect(defaults.contains("formula"))
        #expect(defaults.contains("poop"))
        #expect(defaults.contains("growth"))
    }

    @Test(.tags(.model), arguments: RecordType.allCases)
    func displayNameIsNotEmpty(type: RecordType) {
        #expect(type.displayName.isEmpty == false)
    }

    @Test(.tags(.model), arguments: RecordType.allCases)
    func iconNameIsNotEmpty(type: RecordType) {
        #expect(type.iconName.isEmpty == false)
    }

    @Test(.tags(.model))
    func specificDisplayNames() {
        #expect(RecordType.feeding.displayName == "母乳喂养")
        #expect(RecordType.sleep.displayName == "睡眠记录")
        #expect(RecordType.diaper.displayName == "更换尿布")
        #expect(RecordType.formula.displayName == "配方奶粉")
    }
}

// MARK: - RecordModel Tests

struct RecordModelTests {

    @Test(.tags(.model))
    func initSetsTypeAndTimestamp() {
        let date = Date()
        let record = RecordModel(type: .feeding, timestamp: date)
        #expect(record.type == "feeding")
        #expect(record.timestamp == date)
        #expect(record.note == "")
    }

    @Test(.tags(.model))
    func initWithNote() {
        let record = RecordModel(type: .sleep, timestamp: Date(), note: "午睡")
        #expect(record.note == "午睡")
    }

    @Test(.tags(.model))
    func recordTypeReturnsCorrectEnum() {
        let feeding = RecordModel(type: .feeding, timestamp: Date())
        #expect(feeding.recordType == .feeding)

        let sleep = RecordModel(type: .sleep, timestamp: Date())
        #expect(sleep.recordType == .sleep)
    }

    @Test(.tags(.model))
    func recordTypeDefaultsToFeedingForInvalidRawValue() {
        let record = RecordModel(type: .feeding, timestamp: Date())
        record.type = "invalid_type"
        #expect(record.recordType == .feeding)
    }

    @Test(.tags(.model))
    func sleepDurationMinutesReturnsNilWhenNoEndTime() {
        let record = RecordModel(type: .sleep, timestamp: Date())
        #expect(record.sleepDurationMinutes == nil)
    }

    @Test(.tags(.model))
    func sleepDurationMinutesCalculatesCorrectly() {
        let start = Date()
        let end = start.addingTimeInterval(3600) // 1 hour
        let record = RecordModel(type: .sleep, timestamp: start)
        record.sleepEndTime = end
        #expect(record.sleepDurationMinutes == 60)
    }

    @Test(.tags(.model))
    func sleepDurationTextFormatsHoursAndMinutes() {
        let start = Date()
        let end = start.addingTimeInterval(5400) // 1h30m
        let record = RecordModel(type: .sleep, timestamp: start)
        record.sleepEndTime = end
        #expect(record.sleepDurationText == "1小时30分钟")
    }

    @Test(.tags(.model))
    func sleepDurationTextFormatsHoursOnly() {
        let start = Date()
        let end = start.addingTimeInterval(7200) // 2h
        let record = RecordModel(type: .sleep, timestamp: start)
        record.sleepEndTime = end
        #expect(record.sleepDurationText == "2小时")
    }

    @Test(.tags(.model))
    func sleepDurationTextFormatsMinutesOnly() {
        let start = Date()
        let end = start.addingTimeInterval(1800) // 30m
        let record = RecordModel(type: .sleep, timestamp: start)
        record.sleepEndTime = end
        #expect(record.sleepDurationText == "30分钟")
    }

    @Test(.tags(.model))
    func displaySummaryFeedingDefault() {
        let record = RecordModel(type: .feeding, timestamp: Date())
        #expect(record.displaySummary == "母乳喂养")
    }

    @Test(.tags(.model))
    func displaySummaryFeedingWithDetails() {
        let record = RecordModel(type: .feeding, timestamp: Date())
        record.breastSide = "左侧"
        record.feedingDurationMin = 15
        #expect(record.displaySummary == "左侧喂奶 15分钟")
    }

    @Test(.tags(.model))
    func displaySummaryFormulaWithDetails() {
        let record = RecordModel(type: .formula, timestamp: Date())
        record.formulaBrand = "美赞臣"
        record.formulaAmountML = 120
        #expect(record.displaySummary == "美赞臣 120ml")
    }

    @Test(.tags(.model))
    func displaySummaryGrowthWithDetails() {
        let record = RecordModel(type: .growth, timestamp: Date())
        record.heightCM = 75.5
        record.weightKG = 9.8
        #expect(record.displaySummary == "身高:75.5cm 体重:9.8kg")
    }

    @Test(.tags(.model))
    func displaySummaryDiaperDefault() {
        let record = RecordModel(type: .diaper, timestamp: Date())
        #expect(record.displaySummary == "更换尿布")
    }

    @Test(.tags(.model))
    func displaySummaryDiaperWithType() {
        let record = RecordModel(type: .diaper, timestamp: Date())
        record.diaperType = "湿尿布"
        #expect(record.displaySummary == "湿尿布")
    }
}

// MARK: - TimerManager Tests

struct TimerManagerTests {

    @Test(.tags(.timer))
    func initialState() {
        let manager = TimerManager()
        #expect(manager.isFeedingRunning == false)
        #expect(manager.isSleeping == false)
        #expect(manager.feedingElapsed == 0)
        #expect(manager.sleepElapsed == 0)
        #expect(manager.feedingSelectedSide == 0)
    }

    @Test(.tags(.timer))
    func resetFeedingClearsAllState() {
        let manager = TimerManager()
        manager.feedingElapsed = 100
        manager.feedingAccumulated = 50
        manager.feedingLeftDuration = 30
        manager.feedingRightDuration = 20
        manager.isFeedingRunning = true

        manager.resetFeeding()

        #expect(manager.isFeedingRunning == false)
        #expect(manager.feedingStartTime == nil)
        #expect(manager.feedingElapsed == 0)
        #expect(manager.feedingAccumulated == 0)
        #expect(manager.feedingSelectedSide == 0)
        #expect(manager.feedingLeftDuration == 0)
        #expect(manager.feedingRightDuration == 0)
        #expect(manager.feedingHasRecordedLeft == false)
        #expect(manager.feedingHasRecordedRight == false)
    }

    @Test(.tags(.timer))
    func resetSleepClearsAllState() {
        let manager = TimerManager()
        manager.isSleeping = true
        manager.sleepElapsed = 100
        manager.sleepStartTime = Date()

        manager.resetSleep()

        #expect(manager.isSleeping == false)
        #expect(manager.sleepStartTime == nil)
        #expect(manager.sleepElapsed == 0)
    }

    @Test(.tags(.timer))
    func saveFeedingManuallySetsLeftSide() {
        let manager = TimerManager()
        manager.feedingSelectedSide = 0

        manager.saveFeedingManually(minutes: 15)

        #expect(manager.feedingLeftDuration == 900) // 15 * 60
        #expect(manager.feedingHasRecordedLeft == true)
        #expect(manager.feedingElapsed == 900)
    }

    @Test(.tags(.timer))
    func saveFeedingManuallySetsRightSide() {
        let manager = TimerManager()
        manager.feedingSelectedSide = 1

        manager.saveFeedingManually(minutes: 10)

        #expect(manager.feedingRightDuration == 600) // 10 * 60
        #expect(manager.feedingHasRecordedRight == true)
    }

    @Test(.tags(.timer))
    func saveFeedingManuallyIgnoresZeroMinutes() {
        let manager = TimerManager()
        manager.saveFeedingManually(minutes: 0)
        #expect(manager.feedingLeftDuration == 0)
        #expect(manager.feedingHasRecordedLeft == false)
    }

    @Test(.tags(.timer))
    func switchFeedingSideWithoutDurationDoesNotRecordPreviousSide() {
        let manager = TimerManager()

        manager.switchFeedingSide(1)

        #expect(manager.feedingSelectedSide == 1)
        #expect(manager.feedingHasRecordedLeft == false)
        #expect(manager.feedingLeftDuration == 0)
    }

    @Test(.tags(.timer))
    func switchFeedingSideWhileRunningContinuesOnNewSide() {
        let manager = TimerManager()
        manager.startFeeding(side: 0)
        manager.feedingStartTime = Date().addingTimeInterval(-120)

        manager.switchFeedingSide(1)

        #expect(manager.feedingSelectedSide == 1)
        #expect(manager.isFeedingRunning == true)
        #expect(manager.feedingHasRecordedLeft == true)
        #expect(manager.feedingLeftDuration >= 120)
        #expect(manager.feedingStartTime != nil)
    }

    @Test(.tags(.timer))
    func finishFeedingCommitsPausedDurationToSelectedSide() {
        let manager = TimerManager()
        manager.feedingSelectedSide = 0
        manager.feedingAccumulated = 125
        manager.feedingElapsed = 125

        manager.finishFeeding()

        #expect(manager.feedingHasRecordedLeft == true)
        #expect(manager.feedingLeftDuration == 125)
        #expect(manager.feedingAccumulated == 0)
        #expect(manager.feedingElapsed == 125)
    }

    @Test(.tags(.timer))
    func startSleepSetsIsSleeping() {
        let manager = TimerManager()
        #expect(manager.isSleeping == false)

        manager.startSleep()
        #expect(manager.isSleeping == true)
        #expect(manager.sleepStartTime != nil)
    }

    @Test(.tags(.timer))
    func stopSleepClearsIsSleeping() {
        let manager = TimerManager()
        manager.startSleep()
        #expect(manager.isSleeping == true)

        manager.stopSleep()
        #expect(manager.isSleeping == false)
    }
}

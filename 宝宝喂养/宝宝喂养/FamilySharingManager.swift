import CloudKit
import Foundation
import SwiftData
import UIKit

@MainActor
@Observable
final class FamilySharingManager {
    static let shared = FamilySharingManager()

    static let containerIdentifier = "iCloud.com.mengbaoapp.MengBaoApp"

    private enum RecordTypes {
        static let baby = "BabyFamilyProfile"
        static let record = "BabyFamilyRecord"
    }

    private enum FieldKeys {
        static let familyID = "familyID"
        static let babyFamilyID = "babyFamilyID"
        static let name = "name"
        static let birthDate = "birthDate"
        static let gender = "gender"
        static let avatarImageAsset = "avatarImageAsset"
        static let type = "type"
        static let timestamp = "timestamp"
        static let note = "note"
        static let breastSide = "breastSide"
        static let feedingAmountML = "feedingAmountML"
        static let feedingDurationMin = "feedingDurationMin"
        static let sleepEndTime = "sleepEndTime"
        static let formulaAmountML = "formulaAmountML"
        static let formulaBrand = "formulaBrand"
        static let diaperType = "diaperType"
        static let poopColor = "poopColor"
        static let poopTexture = "poopTexture"
        static let heightCM = "heightCM"
        static let weightKG = "weightKG"
        static let vaccineName = "vaccineName"
        static let vaccineBatch = "vaccineBatch"
        static let vaccineSite = "vaccineSite"
        static let vaccineReaction = "vaccineReaction"
        static let babyFoodName = "babyFoodName"
        static let babyFoodAmount = "babyFoodAmount"
        static let babyFoodReaction = "babyFoodReaction"
        static let pumpingSide = "pumpingSide"
        static let pumpingDurationMin = "pumpingDurationMin"
        static let pumpingAmountML = "pumpingAmountML"
        static let symptomType = "symptomType"
        static let symptomSeverity = "symptomSeverity"
        static let temperature = "temperature"
        static let headCircumferenceCM = "headCircumferenceCM"
        static let toothName = "toothName"
    }

    enum ShareError: LocalizedError {
        case missingBaby
        case missingShareURL
        case iCloudUnavailable
        case iCloudRestricted
        case iCloudStatusUnknown

        var errorDescription: String? {
            switch self {
            case .missingBaby:
                return "请先创建宝宝资料"
            case .missingShareURL:
                return "无法生成家庭共享邀请链接，请稍后重试"
            case .iCloudUnavailable:
                return "请先在系统设置中登录 iCloud，并开启 iCloud Drive"
            case .iCloudRestricted:
                return "当前 iCloud 账号受限制，暂时无法使用家庭共享"
            case .iCloudStatusUnknown:
                return "暂时无法确认 iCloud 状态，请稍后再试"
            }
        }
    }

    var isWorking = false
    var statusMessage = ""
    var lastErrorMessage = ""

    private let container = CKContainer(identifier: FamilySharingManager.containerIdentifier)

    var privateDatabase: CKDatabase { container.privateCloudDatabase }
    var sharedDatabase: CKDatabase { container.sharedCloudDatabase }

    func createOrUpdateShare(for baby: BabyProfile, records: [RecordModel], context: ModelContext) async -> URL? {
        isWorking = true
        lastErrorMessage = ""
        statusMessage = "正在准备家庭共享..."
        defer { isWorking = false }

        do {
            try await ensureCloudKitAccountAvailable()
            ensureFamilyID(for: baby)
            let zoneID = zoneID(for: baby)
            try await saveZoneIfNeeded(zoneID, in: privateDatabase)

            let rootRecord = try await fetchOrCreateBabyRecord(for: baby, zoneID: zoneID, database: privateDatabase)
            apply(baby, to: rootRecord)
            let savedRootRecord = try await save(records: [rootRecord], in: privateDatabase).first ?? rootRecord

            let share = try await fetchOrCreateShare(for: baby, rootRecord: savedRootRecord)
            share.publicPermission = .readWrite
            share[CKShare.SystemFieldKey.title] = "\(baby.name)的家庭记录" as CKRecordValue
            share[CKShare.SystemFieldKey.shareType] = "com.mengbaoapp.MengBaoApp.family" as CKRecordValue

            let saved = try await save(records: [savedRootRecord, share], in: privateDatabase)
            let savedShare = saved.compactMap { $0 as? CKShare }.first ?? share
            guard let shareURL = savedShare.url else { throw ShareError.missingShareURL }

            baby.isFamilyShared = true
            baby.isFamilyOwner = true
            baby.cloudKitRootRecordName = savedRootRecord.recordID.recordName
            baby.cloudKitShareRecordName = savedShare.recordID.recordName
            baby.cloudKitZoneName = zoneID.zoneName
            baby.cloudKitOwnerName = CKCurrentUserDefaultName
            baby.cloudKitShareURLString = shareURL.absoluteString

            try? context.save()
            statusMessage = "正在同步现有记录..."
            try await upload(records: records, for: baby, context: context)
            statusMessage = "家庭共享已开启"
            return shareURL
        } catch {
            #if DEBUG
            print("Family sharing create failed: \(String(describing: error))")
            #endif
            lastErrorMessage = userMessage(for: error)
            statusMessage = ""
            return nil
        }
    }

    func syncAll(context: ModelContext) async {
        isWorking = true
        lastErrorMessage = ""
        statusMessage = "正在同步家庭记录..."
        defer { isWorking = false }

        do {
            let babies = try context.fetch(FetchDescriptor<BabyProfile>())
            let allRecords = try context.fetch(FetchDescriptor<RecordModel>())

            for baby in babies where baby.isFamilyShared {
                let records = allRecords.filter { $0.babyProfile?.persistentModelID == baby.persistentModelID }
                try await upload(records: records, for: baby, context: context)
                try await fetchRemoteRecords(for: baby, context: context)
            }

            try await fetchSharedBabies(context: context)
            statusMessage = "家庭记录已同步"
            UserDefaults.standard.set(false, forKey: "familySharingNeedsSync")
        } catch {
            lastErrorMessage = userMessage(for: error)
            statusMessage = ""
        }
    }

    func upload(record: RecordModel, context: ModelContext) async {
        guard let baby = record.babyProfile, baby.isFamilyShared else { return }
        do {
            try await upload(records: [record], for: baby, context: context)
        } catch {
            lastErrorMessage = userMessage(for: error)
        }
    }

    func acceptShare(metadata: CKShare.Metadata) async {
        isWorking = true
        lastErrorMessage = ""
        statusMessage = "正在接受家庭共享邀请..."
        defer { isWorking = false }

        do {
            _ = try await CKContainer(identifier: metadata.containerIdentifier).accept([metadata])
            UserDefaults.standard.set(true, forKey: "familySharingNeedsSync")
            statusMessage = "已接受邀请，打开 App 后会同步家庭记录"
        } catch {
            lastErrorMessage = userMessage(for: error)
            statusMessage = ""
        }
    }

    func ensureFamilyID(for baby: BabyProfile) {
        if baby.familyID == nil {
            baby.familyID = UUID().uuidString
        }
    }

    func ensureFamilyID(for record: RecordModel) {
        if record.familyID == nil {
            record.familyID = UUID().uuidString
        }
    }

    private func upload(records: [RecordModel], for baby: BabyProfile, context: ModelContext) async throws {
        guard baby.isFamilyShared else { return }
        ensureFamilyID(for: baby)

        let zoneID = zoneID(for: baby)
        let database = baby.isFamilyOwner ? privateDatabase : sharedDatabase
        if baby.isFamilyOwner {
            try await saveZoneIfNeeded(zoneID, in: database)
        }

        let rootRecord = try await fetchOrCreateBabyRecord(for: baby, zoneID: zoneID, database: database)
        apply(baby, to: rootRecord)

        var recordsToSave: [CKRecord] = [rootRecord]
        for record in records {
            ensureFamilyID(for: record)
            let cloudRecord = try await fetchOrCreateRecord(for: record, baby: baby, rootRecordID: rootRecord.recordID, database: database)
            apply(record, baby: baby, rootRecordID: rootRecord.recordID, to: cloudRecord)
            recordsToSave.append(cloudRecord)
        }

        let savedRecords = try await save(records: recordsToSave, in: database)
        applySavedMetadata(savedRecords, baby: baby, records: records)
        try? context.save()
    }

    private func fetchRemoteRecords(for baby: BabyProfile, context: ModelContext) async throws {
        guard let zoneName = baby.cloudKitZoneName else { return }
        let ownerName = baby.cloudKitOwnerName ?? CKCurrentUserDefaultName
        let zoneID = CKRecordZone.ID(zoneName: zoneName, ownerName: ownerName)
        let database = baby.isFamilyOwner ? privateDatabase : sharedDatabase

        let babyRecords = try await query(recordType: RecordTypes.baby, zoneID: zoneID, database: database)
        if let root = babyRecords.first {
            apply(root, to: baby)
        }

        let remoteRecords = try await query(recordType: RecordTypes.record, zoneID: zoneID, database: database)
        let localRecords = try context.fetch(FetchDescriptor<RecordModel>())
        for remote in remoteRecords {
            upsert(remoteRecord: remote, baby: baby, localRecords: localRecords, context: context)
        }
        try? context.save()
    }

    private func fetchSharedBabies(context: ModelContext) async throws {
        let zones = try await fetchAllZones(in: sharedDatabase)
        let existingBabies = try context.fetch(FetchDescriptor<BabyProfile>())

        for zone in zones {
            let roots = try await query(recordType: RecordTypes.baby, zoneID: zone.zoneID, database: sharedDatabase)
            for root in roots {
                let familyID = root[FieldKeys.familyID] as? String ?? root.recordID.recordName
                let baby = existingBabies.first {
                    $0.familyID == familyID || ($0.cloudKitRootRecordName == root.recordID.recordName && $0.cloudKitZoneName == root.recordID.zoneID.zoneName)
                } ?? BabyProfile(
                    name: root[FieldKeys.name] as? String ?? "共享宝宝",
                    birthDate: root[FieldKeys.birthDate] as? Date ?? Date(),
                    gender: root[FieldKeys.gender] as? String ?? "女"
                )

                if baby.familyID == nil && !existingBabies.contains(where: { $0.persistentModelID == baby.persistentModelID }) {
                    context.insert(baby)
                }

                apply(root, to: baby)
                baby.isFamilyShared = true
                baby.isFamilyOwner = false
                baby.cloudKitRootRecordName = root.recordID.recordName
                baby.cloudKitZoneName = root.recordID.zoneID.zoneName
                baby.cloudKitOwnerName = root.recordID.zoneID.ownerName

                let remoteRecords = try await query(recordType: RecordTypes.record, zoneID: zone.zoneID, database: sharedDatabase)
                let localRecords = try context.fetch(FetchDescriptor<RecordModel>())
                for remoteRecord in remoteRecords {
                    upsert(remoteRecord: remoteRecord, baby: baby, localRecords: localRecords, context: context)
                }
            }
        }

        try? context.save()
    }

    private func fetchOrCreateBabyRecord(for baby: BabyProfile, zoneID: CKRecordZone.ID, database: CKDatabase) async throws -> CKRecord {
        ensureFamilyID(for: baby)
        let recordName = baby.cloudKitRootRecordName ?? "baby-\(baby.familyID ?? UUID().uuidString)"
        let recordID = CKRecord.ID(recordName: recordName, zoneID: zoneID)
        if let record = try? await fetch(recordID: recordID, database: database) {
            return record
        }
        return CKRecord(recordType: RecordTypes.baby, recordID: recordID)
    }

    private func fetchOrCreateShare(for baby: BabyProfile, rootRecord: CKRecord) async throws -> CKShare {
        if let shareRecordName = baby.cloudKitShareRecordName {
            let shareID = CKRecord.ID(recordName: shareRecordName, zoneID: rootRecord.recordID.zoneID)
            if let existingShare = try? await fetch(recordID: shareID, database: privateDatabase) as? CKShare {
                return existingShare
            }
        }

        let share = CKShare(rootRecord: rootRecord)
        baby.cloudKitShareRecordName = share.recordID.recordName
        return share
    }

    private func fetchOrCreateRecord(for record: RecordModel, baby: BabyProfile, rootRecordID: CKRecord.ID, database: CKDatabase) async throws -> CKRecord {
        ensureFamilyID(for: record)
        let zoneID = rootRecordID.zoneID
        let recordName = record.cloudKitRecordName ?? "record-\(record.familyID ?? UUID().uuidString)"
        let recordID = CKRecord.ID(recordName: recordName, zoneID: zoneID)
        if let remote = try? await fetch(recordID: recordID, database: database) {
            return remote
        }

        let remote = CKRecord(recordType: RecordTypes.record, recordID: recordID)
        remote.parent = CKRecord.Reference(recordID: rootRecordID, action: .deleteSelf)
        return remote
    }

    private func apply(_ baby: BabyProfile, to record: CKRecord) {
        ensureFamilyID(for: baby)
        record[FieldKeys.familyID] = baby.familyID as CKRecordValue?
        record[FieldKeys.name] = baby.name as CKRecordValue
        record[FieldKeys.birthDate] = baby.birthDate as CKRecordValue
        record[FieldKeys.gender] = baby.gender as CKRecordValue
        record[FieldKeys.avatarImageAsset] = avatarAsset(from: baby.avatarImageData)
    }

    private func apply(_ record: CKRecord, to baby: BabyProfile) {
        baby.familyID = record[FieldKeys.familyID] as? String ?? baby.familyID
        baby.name = record[FieldKeys.name] as? String ?? baby.name
        baby.birthDate = record[FieldKeys.birthDate] as? Date ?? baby.birthDate
        baby.gender = record[FieldKeys.gender] as? String ?? baby.gender
        if let asset = record[FieldKeys.avatarImageAsset] as? CKAsset,
           let fileURL = asset.fileURL,
           let data = try? Data(contentsOf: fileURL) {
            baby.avatarImageData = data
        } else {
            baby.avatarImageData = nil
        }
        baby.isFamilyShared = true
        baby.cloudKitRootRecordName = record.recordID.recordName
        baby.cloudKitZoneName = record.recordID.zoneID.zoneName
        baby.cloudKitOwnerName = record.recordID.zoneID.ownerName
    }

    private func avatarAsset(from data: Data?) -> CKAsset? {
        guard let data, !data.isEmpty else { return nil }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("baby-avatar-\(UUID().uuidString)")
            .appendingPathExtension("jpg")
        do {
            try data.write(to: url, options: .atomic)
            return CKAsset(fileURL: url)
        } catch {
            return nil
        }
    }

    private func apply(_ local: RecordModel, baby: BabyProfile, rootRecordID: CKRecord.ID, to record: CKRecord) {
        ensureFamilyID(for: local)
        record.parent = CKRecord.Reference(recordID: rootRecordID, action: .deleteSelf)
        record[FieldKeys.familyID] = local.familyID as CKRecordValue?
        record[FieldKeys.babyFamilyID] = baby.familyID as CKRecordValue?
        record[FieldKeys.type] = local.type as CKRecordValue
        record[FieldKeys.timestamp] = local.timestamp as CKRecordValue
        record[FieldKeys.note] = local.note as CKRecordValue
        set(local.breastSide, for: FieldKeys.breastSide, in: record)
        set(local.feedingAmountML, for: FieldKeys.feedingAmountML, in: record)
        set(local.feedingDurationMin, for: FieldKeys.feedingDurationMin, in: record)
        set(local.sleepEndTime, for: FieldKeys.sleepEndTime, in: record)
        set(local.formulaAmountML, for: FieldKeys.formulaAmountML, in: record)
        set(local.formulaBrand, for: FieldKeys.formulaBrand, in: record)
        set(local.diaperType, for: FieldKeys.diaperType, in: record)
        set(local.poopColor, for: FieldKeys.poopColor, in: record)
        set(local.poopTexture, for: FieldKeys.poopTexture, in: record)
        set(local.heightCM, for: FieldKeys.heightCM, in: record)
        set(local.weightKG, for: FieldKeys.weightKG, in: record)
        set(local.vaccineName, for: FieldKeys.vaccineName, in: record)
        set(local.vaccineBatch, for: FieldKeys.vaccineBatch, in: record)
        set(local.vaccineSite, for: FieldKeys.vaccineSite, in: record)
        set(local.vaccineReaction, for: FieldKeys.vaccineReaction, in: record)
        set(local.babyFoodName, for: FieldKeys.babyFoodName, in: record)
        set(local.babyFoodAmount, for: FieldKeys.babyFoodAmount, in: record)
        set(local.babyFoodReaction, for: FieldKeys.babyFoodReaction, in: record)
        set(local.pumpingSide, for: FieldKeys.pumpingSide, in: record)
        set(local.pumpingDurationMin, for: FieldKeys.pumpingDurationMin, in: record)
        set(local.pumpingAmountML, for: FieldKeys.pumpingAmountML, in: record)
        set(local.symptomType, for: FieldKeys.symptomType, in: record)
        set(local.symptomSeverity, for: FieldKeys.symptomSeverity, in: record)
        set(local.temperature, for: FieldKeys.temperature, in: record)
        set(local.headCircumferenceCM, for: FieldKeys.headCircumferenceCM, in: record)
        set(local.toothName, for: FieldKeys.toothName, in: record)
    }

    private func upsert(remoteRecord: CKRecord, baby: BabyProfile, localRecords: [RecordModel], context: ModelContext) {
        let familyID = remoteRecord[FieldKeys.familyID] as? String
        let local = localRecords.first {
            $0.cloudKitRecordName == remoteRecord.recordID.recordName || (familyID != nil && $0.familyID == familyID)
        } ?? RecordModel(
            type: RecordType(rawValue: remoteRecord[FieldKeys.type] as? String ?? "") ?? .feeding,
            timestamp: remoteRecord[FieldKeys.timestamp] as? Date ?? Date(),
            note: remoteRecord[FieldKeys.note] as? String ?? ""
        )

        if local.familyID == nil && !localRecords.contains(where: { $0.persistentModelID == local.persistentModelID }) {
            context.insert(local)
        }

        local.familyID = familyID ?? local.familyID
        local.cloudKitRecordName = remoteRecord.recordID.recordName
        local.cloudKitZoneName = remoteRecord.recordID.zoneID.zoneName
        local.cloudKitOwnerName = remoteRecord.recordID.zoneID.ownerName
        local.cloudKitSyncedAt = Date()
        local.babyProfile = baby
        local.type = remoteRecord[FieldKeys.type] as? String ?? local.type
        local.timestamp = remoteRecord[FieldKeys.timestamp] as? Date ?? local.timestamp
        local.note = remoteRecord[FieldKeys.note] as? String ?? local.note
        local.breastSide = remoteRecord[FieldKeys.breastSide] as? String
        local.feedingAmountML = (remoteRecord[FieldKeys.feedingAmountML] as? NSNumber)?.intValue
        local.feedingDurationMin = (remoteRecord[FieldKeys.feedingDurationMin] as? NSNumber)?.intValue
        local.sleepEndTime = remoteRecord[FieldKeys.sleepEndTime] as? Date
        local.formulaAmountML = (remoteRecord[FieldKeys.formulaAmountML] as? NSNumber)?.intValue
        local.formulaBrand = remoteRecord[FieldKeys.formulaBrand] as? String
        local.diaperType = remoteRecord[FieldKeys.diaperType] as? String
        local.poopColor = remoteRecord[FieldKeys.poopColor] as? String
        local.poopTexture = remoteRecord[FieldKeys.poopTexture] as? String
        local.heightCM = (remoteRecord[FieldKeys.heightCM] as? NSNumber)?.doubleValue
        local.weightKG = (remoteRecord[FieldKeys.weightKG] as? NSNumber)?.doubleValue
        local.vaccineName = remoteRecord[FieldKeys.vaccineName] as? String
        local.vaccineBatch = remoteRecord[FieldKeys.vaccineBatch] as? String
        local.vaccineSite = remoteRecord[FieldKeys.vaccineSite] as? String
        local.vaccineReaction = remoteRecord[FieldKeys.vaccineReaction] as? String
        local.babyFoodName = remoteRecord[FieldKeys.babyFoodName] as? String
        local.babyFoodAmount = remoteRecord[FieldKeys.babyFoodAmount] as? String
        local.babyFoodReaction = remoteRecord[FieldKeys.babyFoodReaction] as? String
        local.pumpingSide = remoteRecord[FieldKeys.pumpingSide] as? String
        local.pumpingDurationMin = (remoteRecord[FieldKeys.pumpingDurationMin] as? NSNumber)?.intValue
        local.pumpingAmountML = (remoteRecord[FieldKeys.pumpingAmountML] as? NSNumber)?.intValue
        local.symptomType = remoteRecord[FieldKeys.symptomType] as? String
        local.symptomSeverity = remoteRecord[FieldKeys.symptomSeverity] as? String
        local.temperature = (remoteRecord[FieldKeys.temperature] as? NSNumber)?.doubleValue
        local.headCircumferenceCM = (remoteRecord[FieldKeys.headCircumferenceCM] as? NSNumber)?.doubleValue
        local.toothName = remoteRecord[FieldKeys.toothName] as? String
    }

    private func applySavedMetadata(_ savedRecords: [CKRecord], baby: BabyProfile, records: [RecordModel]) {
        for saved in savedRecords where saved.recordType == RecordTypes.baby {
            baby.cloudKitRootRecordName = saved.recordID.recordName
            baby.cloudKitZoneName = saved.recordID.zoneID.zoneName
            baby.cloudKitOwnerName = saved.recordID.zoneID.ownerName
        }

        for record in records {
            guard let familyID = record.familyID else { continue }
            if let saved = savedRecords.first(where: { $0.recordID.recordName == "record-\(familyID)" || $0[FieldKeys.familyID] as? String == familyID }) {
                record.cloudKitRecordName = saved.recordID.recordName
                record.cloudKitZoneName = saved.recordID.zoneID.zoneName
                record.cloudKitOwnerName = saved.recordID.zoneID.ownerName
                record.cloudKitSyncedAt = Date()
            }
        }
    }

    private func zoneID(for baby: BabyProfile) -> CKRecordZone.ID {
        let zoneName = baby.cloudKitZoneName ?? "baby-family-\(baby.familyID ?? UUID().uuidString)"
        let ownerName = baby.isFamilyOwner ? CKCurrentUserDefaultName : (baby.cloudKitOwnerName ?? CKCurrentUserDefaultName)
        return CKRecordZone.ID(zoneName: zoneName, ownerName: ownerName)
    }

    private func set(_ value: String?, for key: String, in record: CKRecord) {
        record[key] = value as CKRecordValue?
    }

    private func set(_ value: Int?, for key: String, in record: CKRecord) {
        record[key] = value.map { NSNumber(value: $0) }
    }

    private func set(_ value: Double?, for key: String, in record: CKRecord) {
        record[key] = value.map { NSNumber(value: $0) }
    }

    private func set(_ value: Date?, for key: String, in record: CKRecord) {
        record[key] = value as CKRecordValue?
    }

    private func saveZoneIfNeeded(_ zoneID: CKRecordZone.ID, in database: CKDatabase) async throws {
        if (try? await fetch(zoneID: zoneID, database: database)) != nil {
            return
        }

        _ = try await save(zone: CKRecordZone(zoneID: zoneID), in: database)
    }

    private func save(zone: CKRecordZone, in database: CKDatabase) async throws -> CKRecordZone {
        try await withCheckedThrowingContinuation { continuation in
            database.save(zone) { savedZone, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let savedZone {
                    continuation.resume(returning: savedZone)
                } else {
                    continuation.resume(throwing: ShareError.missingBaby)
                }
            }
        }
    }

    private func ensureCloudKitAccountAvailable() async throws {
        let status = try await accountStatus()
        switch status {
        case .available:
            return
        case .noAccount:
            throw ShareError.iCloudUnavailable
        case .restricted:
            throw ShareError.iCloudRestricted
        case .couldNotDetermine:
            throw ShareError.iCloudStatusUnknown
        case .temporarilyUnavailable:
            throw CKError(.networkUnavailable)
        @unknown default:
            throw ShareError.iCloudStatusUnknown
        }
    }

    private func accountStatus() async throws -> CKAccountStatus {
        try await withCheckedThrowingContinuation { continuation in
            container.accountStatus { status, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: status)
                }
            }
        }
    }

    private func fetch(recordID: CKRecord.ID, database: CKDatabase) async throws -> CKRecord {
        try await withCheckedThrowingContinuation { continuation in
            database.fetch(withRecordID: recordID) { record, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let record {
                    continuation.resume(returning: record)
                } else {
                    continuation.resume(throwing: CKError(.unknownItem))
                }
            }
        }
    }

    private func fetch(zoneID: CKRecordZone.ID, database: CKDatabase) async throws -> CKRecordZone {
        try await withCheckedThrowingContinuation { continuation in
            database.fetch(withRecordZoneID: zoneID) { zone, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let zone {
                    continuation.resume(returning: zone)
                } else {
                    continuation.resume(throwing: ShareError.missingBaby)
                }
            }
        }
    }

    private func save(records: [CKRecord], in database: CKDatabase) async throws -> [CKRecord] {
        try await withCheckedThrowingContinuation { continuation in
            let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
            operation.savePolicy = .changedKeys
            operation.modifyRecordsCompletionBlock = { savedRecords, _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: savedRecords ?? [])
                }
            }
            database.add(operation)
        }
    }

    private func fetchAllZones(in database: CKDatabase) async throws -> [CKRecordZone] {
        try await withCheckedThrowingContinuation { continuation in
            database.fetchAllRecordZones { zones, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: zones ?? [])
                }
            }
        }
    }

    private func query(recordType: String, zoneID: CKRecordZone.ID, database: CKDatabase) async throws -> [CKRecord] {
        try await withCheckedThrowingContinuation { continuation in
            let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
            database.perform(query, inZoneWith: zoneID) { records, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: records ?? [])
                }
            }
        }
    }

    private func userMessage(for error: Error) -> String {
        if let ckError = error as? CKError {
            switch ckError.code {
            case .partialFailure:
                let messages = ckError.partialErrorsByItemID?.values.map { userMessage(for: $0) } ?? []
                return messages.first ?? "CloudKit 部分保存失败，请稍后再试"
            case .notAuthenticated:
                return "请先在系统设置中登录 iCloud"
            case .networkUnavailable, .networkFailure:
                return "网络暂时不可用，请稍后再试"
            case .quotaExceeded:
                return "iCloud 储存空间不足，暂时无法开启家庭共享。本地记录不受影响，可清理或升级 iCloud 后重试"
            case .permissionFailure:
                return "没有权限访问这个家庭共享"
            case .serverRejectedRequest:
                return "CloudKit 拒绝了本次共享请求，请确认后台已开启 CloudKit，并稍后重试"
            case .invalidArguments:
                return "家庭共享参数无效，请重新生成邀请"
            default:
                return ckError.localizedDescription
            }
        }
        return error.localizedDescription
    }
}

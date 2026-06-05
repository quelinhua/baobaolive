import Foundation
import SwiftData
import SwiftUI

@Observable
class BabyManager {
    static let shared = BabyManager()

    var selectedBaby: BabyProfile?

    func selectBaby(_ baby: BabyProfile) {
        selectedBaby = baby
        baby.isSelected = true
    }

    func selectBaby(_ baby: BabyProfile, from babies: [BabyProfile]) {
        for item in babies {
            item.isSelected = item.persistentModelID == baby.persistentModelID
        }
        selectedBaby = baby
    }

    func getSelectedBaby(from babies: [BabyProfile]) -> BabyProfile? {
        if let selected = selectedBaby, babies.contains(where: { $0.persistentModelID == selected.persistentModelID }) {
            return selected
        }
        if let selected = babies.first(where: { $0.isSelected }) {
            selectedBaby = selected
            return selected
        }
        return babies.first
    }

    func filterRecords(_ records: [RecordModel], for baby: BabyProfile?) -> [RecordModel] {
        guard let baby = baby else { return records }
        return records.filter { record in
            guard let recordBaby = record.babyProfile else { return false }
            return recordBaby.persistentModelID == baby.persistentModelID
        }
    }
}

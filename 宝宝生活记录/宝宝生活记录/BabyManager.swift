import Foundation
import SwiftData
import SwiftUI

@Observable
class BabyManager {
    static let shared = BabyManager()

    var selectedBaby: BabyProfile?

    func selectBaby(_ baby: BabyProfile) {
        selectedBaby = baby
    }

    func getSelectedBaby(from babies: [BabyProfile]) -> BabyProfile? {
        if let selected = selectedBaby, babies.contains(where: { $0.persistentModelID == selected.persistentModelID }) {
            return selected
        }
        return babies.first
    }

    func filterRecords(_ records: [RecordModel], for baby: BabyProfile?) -> [RecordModel] {
        guard let baby = baby else { return records }
        return records.filter { $0.babyProfile?.persistentModelID == baby.persistentModelID }
    }
}
import SwiftUI
import SwiftData
import CloudKit
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        Task {
            await FamilySharingManager.shared.acceptShare(metadata: cloudKitShareMetadata)
        }
    }
}

@main
struct ______App: App {
    private static let cloudKitContainerIdentifier = "iCloud.com.mengbaoapp.MengBaoApp"
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    private static var isRunningTests: Bool {
        let environment = ProcessInfo.processInfo.environment
        let arguments = ProcessInfo.processInfo.arguments

        return environment["XCTestConfigurationFilePath"] != nil
            || environment["XCTestBundlePath"] != nil
            || environment["XCInjectBundleInto"] != nil
            || arguments.contains { $0.localizedCaseInsensitiveContains("XCTest") }
            || NSClassFromString("XCTestCase") != nil
    }

    private static func makeLocalModelContainer(for schema: Schema, inMemory: Bool = false) throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([
            RecordModel.self,
            BabyProfile.self
        ])

        if isRunningTests {
            do {
                return try makeLocalModelContainer(for: schema, inMemory: true)
            } catch {
                fatalError("无法创建 SwiftData 测试容器: \(error)")
            }
        }

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private(Self.cloudKitContainerIdentifier)
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            #if DEBUG
            print("SwiftData iCloud container ready: \(Self.cloudKitContainerIdentifier)")
            #endif
            return container
        } catch {
            #if DEBUG
            print("SwiftData iCloud container failed: \(error.localizedDescription)")
            print("SwiftData iCloud container error detail: \(String(describing: error))")
            #endif

            do {
                let container = try makeLocalModelContainer(for: schema)
                #if DEBUG
                print("SwiftData local container fallback ready")
                #endif
                return container
            } catch {
                fatalError("无法创建 SwiftData 本地容器: \(error)")
            }
        }
    }

    private let sharedModelContainer: ModelContainer = Self.makeModelContainer()

    private let appLocale = Locale(identifier: "zh_Hans_CN")

    private var appCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = appLocale
        calendar.timeZone = .current
        return calendar
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, appLocale)
                .environment(\.calendar, appCalendar)
        }
        .modelContainer(sharedModelContainer)
    }
}

import SwiftUI
import StoreKit

enum SubscriptionProduct: String, CaseIterable {
    case monthly = "com.mengbaoapp.MengBaoApp.pro.monthly1"
    case lifetime = "com.mengbaoapp.MengBaoApp.pro.lifetime"

    var displayName: String {
        switch self {
        case .monthly: return "月度订阅"
        case .lifetime: return "永久会员"
        }
    }
}

@Observable
class SubscriptionManager {
    static let shared = SubscriptionManager()

    private enum StorageKey {
        static let isProUser = "isProUser"
        static let isLifetimeUser = "isLifetimeUser"
        static let subscriptionExpiry = "subscriptionExpiry"
    }

    var isProUser: Bool {
        didSet { UserDefaults.standard.set(isProUser, forKey: StorageKey.isProUser) }
    }

    var isLifetimeUser: Bool {
        didSet { UserDefaults.standard.set(isLifetimeUser, forKey: StorageKey.isLifetimeUser) }
    }

    var subscriptionExpiry: Double {
        didSet { UserDefaults.standard.set(subscriptionExpiry, forKey: StorageKey.subscriptionExpiry) }
    }

    var products: [Product] = []
    var purchasedProductID: String?
    var isLoading = false
    var errorMessage: String?

    var lifetimeProduct: Product? {
        products.first { $0.id == SubscriptionProduct.lifetime.rawValue }
    }

    var monthlyProduct: Product? {
        products.first { $0.id == SubscriptionProduct.monthly.rawValue }
    }

    private init() {
        isProUser = UserDefaults.standard.bool(forKey: StorageKey.isProUser)
        isLifetimeUser = UserDefaults.standard.bool(forKey: StorageKey.isLifetimeUser)
        subscriptionExpiry = UserDefaults.standard.double(forKey: StorageKey.subscriptionExpiry)
        Task { await listenForTransactions() }
    }

    private func listenForTransactions() async {
        for await result in StoreKit.Transaction.updates {
            switch result {
            case .verified(let transaction):
                await updateSubscriptionStatus(transaction: transaction)
                await transaction.finish()
            case .unverified(_, _):
                break
            }
        }
    }

    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let productIDs = SubscriptionProduct.allCases.map { $0.rawValue }
            products = try await Product.products(for: productIDs)
            isLoading = false
        } catch {
            errorMessage = "无法加载产品信息"
            isLoading = false
        }
    }

    func purchase(_ product: Product) async throws {
        isLoading = true
        errorMessage = nil

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                await updateSubscriptionStatus(transaction: transaction)
                await transaction.finish()
            case .unverified(_, let error):
                errorMessage = "购买验证失败: \(error.localizedDescription)"
            }
        case .userCancelled:
            isLoading = false
            return
        case .pending:
            errorMessage = "购买正在处理中"
        @unknown default:
            break
        }

        isLoading = false
    }

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await AppStore.sync()
        } catch {
            errorMessage = "恢复购买失败: \(error.localizedDescription)"
        }

        var restoredPurchase = false
        for await result in StoreKit.Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if transaction.productID == SubscriptionProduct.monthly.rawValue ||
                   transaction.productID == SubscriptionProduct.lifetime.rawValue {
                    await updateSubscriptionStatus(transaction: transaction)
                    restoredPurchase = true
                }
            case .unverified(_, _):
                break
            }
        }

        if !restoredPurchase && errorMessage == nil {
            errorMessage = "未找到可恢复的购买"
        }
    }

    private func updateSubscriptionStatus(transaction: StoreKit.Transaction) async {
        if transaction.productID == SubscriptionProduct.lifetime.rawValue {
            isProUser = true
            isLifetimeUser = true
            purchasedProductID = transaction.productID
            subscriptionExpiry = 0
        } else if transaction.productID == SubscriptionProduct.monthly.rawValue {
            isProUser = true
            purchasedProductID = transaction.productID

            if let expirationDate = transaction.expirationDate {
                subscriptionExpiry = expirationDate.timeIntervalSince1970
            }
        }
    }

    func checkSubscriptionStatus() async {
        #if DEBUG
        if isProUser && !isLifetimeUser && subscriptionExpiry == 0 && purchasedProductID == nil {
            return
        }
        #endif

        var hasActiveSubscription = false
        var hasLifetimePurchase = false
        var activeProductID: String?
        var activeExpiry: Date?

        for await result in StoreKit.Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if transaction.productID == SubscriptionProduct.monthly.rawValue {
                    if transaction.expirationDate.map({ $0 > Date() }) ?? true {
                        hasActiveSubscription = true
                        activeProductID = transaction.productID
                        activeExpiry = transaction.expirationDate
                    }
                } else if transaction.productID == SubscriptionProduct.lifetime.rawValue {
                    hasActiveSubscription = true
                    hasLifetimePurchase = true
                    activeProductID = transaction.productID
                }
            case .unverified(_, _):
                break
            }
        }

        isProUser = hasActiveSubscription
        isLifetimeUser = hasLifetimePurchase
        purchasedProductID = activeProductID

        if hasLifetimePurchase {
            subscriptionExpiry = 0
        } else if let activeExpiry {
            subscriptionExpiry = activeExpiry.timeIntervalSince1970
        } else if !hasActiveSubscription {
            purchasedProductID = nil
            subscriptionExpiry = 0
        }
    }

    var expiryDateString: String {
        if isLifetimeUser { return "永久有效" }
        guard subscriptionExpiry > 0 else { return "未知" }
        let date = Date(timeIntervalSince1970: subscriptionExpiry)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: date)
    }
}

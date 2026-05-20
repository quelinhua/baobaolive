import SwiftUI
import StoreKit

enum SubscriptionProduct: String, CaseIterable {
    case monthly = "com.baobaolive.pro.monthly"
    case yearly = "com.baobaolive.pro.yearly"
    
    var displayName: String {
        switch self {
        case .monthly: return "月度订阅"
        case .yearly: return "年度订阅"
        }
    }
    
    var price: String {
        switch self {
        case .monthly: return "¥12/月"
        case .yearly: return "¥98/年"
        }
    }
}

@Observable
class SubscriptionManager {
    static let shared = SubscriptionManager()
    
    @ObservationIgnored
    @AppStorage("isProUser") var isProUser: Bool = false
    
    @ObservationIgnored
    @AppStorage("subscriptionExpiry") var subscriptionExpiry: Double = 0
    
    var products: [Product] = []
    var purchasedProductID: String?
    var isLoading = false
    var errorMessage: String?
    
    private init() {}
    
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
            break
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

        for await result in StoreKit.Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if transaction.productID == SubscriptionProduct.monthly.rawValue ||
                   transaction.productID == SubscriptionProduct.yearly.rawValue {
                    await updateSubscriptionStatus(transaction: transaction)
                }
            case .unverified(_, _):
                break
            }
        }

        isLoading = false
    }

    private func updateSubscriptionStatus(transaction: StoreKit.Transaction) async {
        if transaction.productID == SubscriptionProduct.monthly.rawValue ||
           transaction.productID == SubscriptionProduct.yearly.rawValue {
            isProUser = true
            purchasedProductID = transaction.productID

            if let expirationDate = transaction.expirationDate {
                subscriptionExpiry = expirationDate.timeIntervalSince1970
            }
        }
    }
    
    func checkSubscriptionStatus() {
        guard isProUser else { return }
        
        if subscriptionExpiry > 0 {
            let expiryDate = Date(timeIntervalSince1970: subscriptionExpiry)
            if expiryDate < Date() {
                isProUser = false
                purchasedProductID = nil
            }
        }
    }
    
    var expiryDateString: String {
        guard subscriptionExpiry > 0 else { return "未知" }
        let date = Date(timeIntervalSince1970: subscriptionExpiry)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: date)
    }
}

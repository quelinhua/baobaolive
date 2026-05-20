import SwiftUI
import StoreKit

struct ProView: View {
    @State private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProduct: Product?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 28) {
                    headerSection
                    featuresSection
                    comparisonSection
                    subscriptionOptionsSection
                    purchaseButtonSection
                    footerSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color.background)
            .navigationTitle("升级到 Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") { dismiss() }
                }
            }
            .task {
                await subscriptionManager.loadProducts()
                if let firstProduct = subscriptionManager.products.first {
                    selectedProduct = firstProduct
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                Image(systemName: "crown.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }
            .shadow(color: Color(hex: "FFD700").opacity(0.4), radius: 12, y: 4)
            
            Text("解锁全部高级功能")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color.onSurface)
            
            Text("记录宝宝成长的每一刻")
                .font(.system(size: 15))
                .foregroundColor(Color.outline)
        }
        .padding(.top, 20)
    }
    
    private var featuresSection: some View {
        VStack(spacing: 16) {
            featureRow(icon: "person.2.fill", title: "多宝宝管理", description: "支持记录多个宝宝的成长数据")
            featureRow(icon: "chart.line.uptrend.xyaxis", title: "成长曲线图表", description: "可视化查看宝宝成长趋势")
            featureRow(icon: "square.and.arrow.up", title: "数据导出", description: "导出CSV/JSON格式数据备份")
            featureRow(icon: "bell.badge.fill", title: "自定义提醒", description: "自由设置提醒间隔时间")
            featureRow(icon: "paintpalette.fill", title: "更多主题", description: "9种精美主题+自定义颜色")
        }
    }
    
    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.primary.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(Color.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.onSurface)
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(Color.outline)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(Color(hex: "4ECDC4"))
        }
        .padding(14)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.03), radius: 4, y: 1)
    }
    
    private var comparisonSection: some View {
        VStack(spacing: 12) {
            Text("功能对比")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color.onSurface)
            
            VStack(spacing: 0) {
                comparisonHeaderRow
                comparisonRow(feature: "宝宝数量", free: "1个", pro: "无限")
                comparisonRow(feature: "数据导出", free: "✗", pro: "✓")
                comparisonRow(feature: "成长图表", free: "✗", pro: "✓")
                comparisonRow(feature: "自定义提醒", free: "✗", pro: "✓")
                comparisonRow(feature: "主题数量", free: "3种", pro: "9种+")
            }
            .background(Color.surfaceContainerLowest)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color.black.opacity(0.03), radius: 4, y: 1)
        }
    }
    
    private var comparisonHeaderRow: some View {
        HStack {
            Text("功能")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.outline)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("普通版")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.outline)
                .frame(width: 70)
            Text("Pro")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.primary)
                .frame(width: 70)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.surfaceContainerHigh)
    }
    
    private func comparisonRow(feature: String, free: String, pro: String) -> some View {
        HStack {
            Text(feature)
                .font(.system(size: 14))
                .foregroundColor(Color.onSurface)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(free)
                .font(.system(size: 14))
                .foregroundColor(free == "✗" ? Color.error : Color.outline)
                .frame(width: 70)
            Text(pro)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "4ECDC4"))
                .frame(width: 70)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .overlay(
            Divider().padding(.horizontal, 16),
            alignment: .bottom
        )
    }
    
    private var subscriptionOptionsSection: some View {
        VStack(spacing: 12) {
            Text("选择订阅方案")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color.onSurface)
            
            HStack(spacing: 12) {
                ForEach(subscriptionManager.products, id: \.id) { product in
                    subscriptionOptionCard(product: product)
                }
            }
        }
    }
    
    private func subscriptionOptionCard(product: Product) -> some View {
        let isSelected = selectedProduct?.id == product.id
        let isYearly = product.id == SubscriptionProduct.yearly.rawValue
        
        return Button(action: { selectedProduct = product }) {
            VStack(spacing: 8) {
                if isYearly {
                    Text("省30%")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(hex: "FF6B6B"))
                        .clipShape(Capsule())
                }
                
                Text(isYearly ? "年度" : "月度")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : Color.onSurface)
                
                Text(product.displayPrice)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(isSelected ? .white : Color.onSurface)
                
                Text(isYearly ? "约¥8.2/月" : "")
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : Color.outline)
                    .frame(height: 16)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isSelected ?
                LinearGradient(
                    colors: [Color.primary, Color.primary.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ) :
                LinearGradient(
                    colors: [Color.surfaceContainerLowest, Color.surfaceContainerLowest],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.clear : Color.outlineVariant, lineWidth: 1)
            )
            .shadow(color: isSelected ? Color.primary.opacity(0.3) : Color.clear, radius: 8, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var purchaseButtonSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                guard let product = selectedProduct else { return }
                Task {
                    try await subscriptionManager.purchase(product)
                    if subscriptionManager.isProUser {
                        dismiss()
                    }
                }
            }) {
                HStack {
                    if subscriptionManager.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("7天免费试用，之后\(selectedProduct?.displayPrice ?? "")")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.primary, Color.primary.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.primary.opacity(0.4), radius: 8, y: 3)
            }
            .disabled(subscriptionManager.isLoading || selectedProduct == nil)
            
            HStack(spacing: 20) {
                Button("恢复购买") {
                    Task {
                        await subscriptionManager.restorePurchases()
                    }
                }
                .font(.system(size: 13))
                .foregroundColor(Color.outline)
                
                Button("服务条款") {
                    // TODO: 显示服务条款
                }
                .font(.system(size: 13))
                .foregroundColor(Color.outline)
                
                Button("隐私政策") {
                    // TODO: 显示隐私政策
                }
                .font(.system(size: 13))
                .foregroundColor(Color.outline)
            }
        }
    }
    
    private var footerSection: some View {
        VStack(spacing: 8) {
            Text("订阅将自动续期，可随时在设置中取消")
                .font(.system(size: 12))
                .foregroundColor(Color.outline)
                .multilineTextAlignment(.center)
            
            if let errorMessage = subscriptionManager.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13))
                    .foregroundColor(Color.error)
                    .padding(.top, 4)
            }
        }
    }
}

#Preview {
    ProView()
}

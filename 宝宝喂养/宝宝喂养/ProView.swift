import SwiftUI
import StoreKit
import SwiftData

// MARK: - Haptic Manager
@Observable
class HapticManager {
    static let shared = HapticManager()

    func light() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }

    func medium() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }

    func heavy() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }

    func success() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
}

// MARK: - Design Tokens
private enum DesignTokens {
    // Spacing (8pt grid)
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 12
    static let spacingLG: CGFloat = 16
    static let spacingXL: CGFloat = 20
    static let spacing2XL: CGFloat = 24

    // Corner Radius
    static let radiusSM: CGFloat = 8
    static let radiusMD: CGFloat = 12
    static let radiusLG: CGFloat = 16
    static let radiusXL: CGFloat = 20

    // Colors
    static let accentGold = Color(hex: "D4A574")
    static let accentGoldLight = Color(hex: "F5E6D3")
    static let accentRose = Color(hex: "E8A0BF")
    static let accentRoseLight = Color(hex: "FDE8F0")
    static let textPrimary = Color(hex: "1A1A2E")
    static let textSecondary = Color(hex: "6B7280")
    static let textTertiary = Color(hex: "9CA3AF")
    static let surfaceElevated = Color(hex: "F9FAFB")
    static let divider = Color(hex: "E5E7EB")
}

// MARK: - Pro View
struct ProView: View {
    @Query(sort: \RecordModel.timestamp, order: .reverse) private var allRecords: [RecordModel]
    @Query private var babyProfiles: [BabyProfile]
    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var hapticManager = HapticManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var animationPhase = 0
    @State private var isLifetimeSelected = true
    @State private var showPurchaseSuccess = false
    @State private var activeLegalDocument: LegalDocument?

    private var babyProfile: BabyProfile? {
        BabyManager.shared.getSelectedBaby(from: babyProfiles)
    }

    private var babyRecords: [RecordModel] {
        BabyManager.shared.filterRecords(allRecords, for: babyProfile)
    }

    private var recentRecords: [RecordModel] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -6, to: today) else {
            return babyRecords
        }

        return babyRecords.filter { $0.timestamp >= startDate }
    }

    private var reportRecordCount: Int {
        recentRecords.count
    }

    private var reportSubtitle: String {
        reportRecordCount > 0
            ? "近 7 天已整理 \(reportRecordCount) 条记录"
            : "开始记录后，这里会自动生成周报预览"
    }

    private var lifetimePriceText: String {
        priceText(for: subscriptionManager.lifetimeProduct)
    }

    private var monthlyPriceText: String {
        priceText(for: subscriptionManager.monthlyProduct, includesSubscriptionPeriod: true)
    }

    private var purchaseButtonTitle: String {
        guard let selectedProduct else { return "正在加载商品..." }

        if selectedProduct.id == SubscriptionProduct.lifetime.rawValue {
            return "开通PRO版本 · \(selectedProduct.displayPrice)"
        }

        return "开通PRO版本 · \(priceText(for: selectedProduct, includesSubscriptionPeriod: true))"
    }

    private var purchaseFootnote: String {
        if isLifetimeSelected {
            return "一次性购买 · 长期解锁成长报告、趋势和数据导出"
        }

        return "自动续订 · 可随时在 App Store 账户设置中取消"
    }

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Header
                    headerSection

                    // Scrollable Content
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: DesignTokens.spacingLG) {
                            // Report Preview
                            reportPreviewSection

                            // Conversion Reasons
                            featuresSection

                            // Fit Section
                            fitSection

                            // Comparison Table
                            comparisonSection

                            // Subscription Cards
                            subscriptionSection
                        }
                        .padding(.horizontal, DesignTokens.spacingXL)
                        .padding(.top, DesignTokens.spacingMD)
                        .padding(.bottom, DesignTokens.spacingXS)
                    }

                    // Purchase CTA
                    purchaseSection
                }
                .background(Color.white)
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        closeButton
                    }
                }
                .task {
                    await subscriptionManager.loadProducts()
                    if let lifetimeProduct = subscriptionManager.lifetimeProduct {
                        isLifetimeSelected = true
                        selectedProduct = lifetimeProduct
                    } else {
                        isLifetimeSelected = false
                        selectedProduct = subscriptionManager.monthlyProduct
                    }

                    // Staggered entrance animation
                    withAnimation(.easeOut(duration: 0.5).delay(0.1)) { animationPhase = 1 }
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.25)) { animationPhase = 2 }
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4)) { animationPhase = 3 }
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.55)) { animationPhase = 4 }
                }

                // Purchase Success Overlay
                if showPurchaseSuccess {
                    purchaseSuccessOverlay
                }
            }
        }
        .sheet(item: $activeLegalDocument) { document in
            LegalDocumentView(document: document)
        }
    }

    private func priceText(for product: Product?, includesSubscriptionPeriod: Bool = false) -> String {
        guard let product else { return "加载价格" }

        if includesSubscriptionPeriod {
            return "\(product.displayPrice)\(subscriptionPeriodSuffix(for: product))"
        }

        return product.displayPrice
    }

    private func subscriptionPeriodSuffix(for product: Product) -> String {
        guard let period = product.subscription?.subscriptionPeriod else { return "/月" }

        return "/\(localizedPeriod(period))"
    }

    private func localizedPeriod(_ period: Product.SubscriptionPeriod) -> String {
        let unit: String

        switch period.unit {
        case .day:
            unit = "天"
        case .week:
            unit = "周"
        case .month:
            unit = "月"
        case .year:
            unit = "年"
        @unknown default:
            unit = "周期"
        }

        return period.value == 1 ? unit : "\(period.value)\(unit)"
    }

    // MARK: - Close Button
    private var closeButton: some View {
        Button(action: {
            hapticManager.light()
            dismiss()
        }) {
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(DesignTokens.textSecondary)
                .frame(width: 32, height: 32)
                .background(DesignTokens.surfaceElevated)
                .clipShape(Circle())
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: DesignTokens.spacingMD) {
            // Crown Icon with enhanced glow
            ZStack {
                // Outer glow ring
                Circle()
                    .stroke(DesignTokens.accentGold.opacity(0.15), lineWidth: 2)
                    .frame(width: 72, height: 72)

                // Inner glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                DesignTokens.accentGold.opacity(0.25),
                                DesignTokens.accentGold.opacity(0)
                            ],
                            center: .center,
                            startRadius: 8,
                            endRadius: 36
                        )
                    )
                    .frame(width: 72, height: 72)

                // Crown background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [DesignTokens.accentGold, DesignTokens.accentGold.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .shadow(color: DesignTokens.accentGold.opacity(0.4), radius: 12, y: 4)

                Image(systemName: "crown.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.1), radius: 1, y: 1)
            }
            .scaleEffect(animationPhase >= 1 ? 1 : 0.5)
            .opacity(animationPhase >= 1 ? 1 : 0)

            // Title with gradient
            VStack(spacing: DesignTokens.spacingXS) {
                Text("升级为PRO版本")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(DesignTokens.textPrimary)

                Text("把每天的记录，整理成清晰的成长趋势")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(DesignTokens.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .opacity(animationPhase >= 2 ? 1 : 0)
            .offset(y: animationPhase >= 2 ? 0 : 12)
        }
        .padding(.vertical, DesignTokens.spacingMD)
    }

    // MARK: - Report Preview Section
    private var reportPreviewSection: some View {
        let feeding = recentRecords.filter { $0.recordType == .feeding || $0.recordType == .formula }.count
        let sleep = recentRecords.filter { $0.recordType == .sleep }.count
        let diaper = recentRecords.filter { $0.recordType == .diaper || $0.recordType == .poop }.count
        let growth = recentRecords.filter { $0.recordType == .growth || $0.recordType == .headCircumference }.count

        return VStack(alignment: .leading, spacing: DesignTokens.spacingMD) {
            HStack(alignment: .top, spacing: DesignTokens.spacingMD) {
                VStack(alignment: .leading, spacing: DesignTokens.spacingXS) {
                    Text("本周报告预览")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(DesignTokens.textPrimary)

                    Text(reportSubtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignTokens.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text("完整报告")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(DesignTokens.accentGold)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(DesignTokens.accentGoldLight.opacity(0.55))
                .clipShape(Capsule())
            }

            HStack(spacing: DesignTokens.spacingSM) {
                ReportMetricCard(title: "喂养", value: "\(feeding)", icon: RecordType.formula.iconName, color: RecordType.formula.iconColor)
                ReportMetricCard(title: "睡眠", value: "\(sleep)", icon: RecordType.sleep.iconName, color: RecordType.sleep.iconColor)
                ReportMetricCard(title: "尿布", value: "\(diaper)", icon: RecordType.diaper.iconName, color: RecordType.diaper.iconColor)
                ReportMetricCard(title: "成长", value: "\(growth)", icon: RecordType.growth.iconName, color: DesignTokens.accentGold)
            }

            HStack(spacing: DesignTokens.spacingSM) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DesignTokens.accentGold)
                    .frame(width: 26, height: 26)
                    .background(DesignTokens.accentGoldLight.opacity(0.55))
                    .clipShape(Circle())

                Text("升级后查看完整周报、月报、长期趋势和导出文件")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DesignTokens.textSecondary)
                    .lineLimit(2)
            }
            .padding(DesignTokens.spacingMD)
            .background(DesignTokens.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMD, style: .continuous))
        }
        .padding(DesignTokens.spacingLG)
        .background(
            LinearGradient(
                colors: [Color.white, DesignTokens.accentGoldLight.opacity(0.34)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusLG, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusLG, style: .continuous)
                .stroke(DesignTokens.accentGold.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: DesignTokens.accentGold.opacity(0.12), radius: 10, y: 4)
        .opacity(animationPhase >= 2 ? 1 : 0)
        .offset(y: animationPhase >= 2 ? 0 : 16)
    }

    // MARK: - Features Section
    private var featuresSection: some View {
        VStack(spacing: DesignTokens.spacingSM) {
            HStack(spacing: DesignTokens.spacingSM) {
                FeaturePill(icon: "doc.text.magnifyingglass", title: "周报月报", color: DesignTokens.accentGold)
                FeaturePill(icon: "chart.line.uptrend.xyaxis", title: "长期趋势", color: .green)
            }

            HStack(spacing: DesignTokens.spacingSM) {
                FeaturePill(icon: "externaldrive.fill", title: "备份导出", color: .orange)
                FeaturePill(icon: "person.2.fill", title: "多宝宝", color: .blue)
            }
        }
        .opacity(animationPhase >= 2 ? 1 : 0)
    }

    // MARK: - Fit Section
    private var fitSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingMD) {
            Text("适合这些家庭")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(DesignTokens.textPrimary)

            VStack(spacing: DesignTokens.spacingSM) {
                ValueReasonRow(icon: "calendar.badge.clock", title: "想长期记录成长", subtitle: "周报、月报和趋势帮你持续复盘")
                ValueReasonRow(icon: "cross.case.fill", title: "需要就医沟通记录", subtitle: "喂养、睡眠、尿布数据可导出备份")
                ValueReasonRow(icon: "person.2.fill", title: "二胎或多胎家庭", subtitle: "每个宝宝独立记录，统计不混在一起")
            }
        }
        .padding(DesignTokens.spacingLG)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusLG, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusLG, style: .continuous)
                .stroke(DesignTokens.divider, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.035), radius: 8, y: 2)
        .opacity(animationPhase >= 3 ? 1 : 0)
        .offset(y: animationPhase >= 3 ? 0 : 18)
    }

    // MARK: - Comparison Section
    private var comparisonSection: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("你会获得")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DesignTokens.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("免费")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DesignTokens.textTertiary)
                    .frame(width: 50)

                Text("Pro")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(DesignTokens.accentGold)
                    .frame(width: 50)
            }
            .padding(.horizontal, DesignTokens.spacingLG)
            .padding(.vertical, DesignTokens.spacingMD)
            .background(DesignTokens.accentGoldLight.opacity(0.3))

            // Rows
            ComparisonRow(icon: "pencil.circle.fill", feature: "基础记录", free: "可用", pro: "可用", isFirst: true)
            ComparisonRow(icon: "chart.bar.fill", feature: "近7天概览", free: "可用", pro: "可用")
            ComparisonRow(icon: "doc.text.magnifyingglass", feature: "周报/月报", free: "预览", pro: "完整")
            ComparisonRow(icon: "chart.line.uptrend.xyaxis", feature: "长期趋势分析", free: "近7天", pro: "全部")
            ComparisonRow(icon: "externaldrive.fill", feature: "数据备份导出", free: "—", pro: "CSV/JSON")
            ComparisonRow(icon: "person.2.fill", feature: "多宝宝管理", free: "1个", pro: "多个")
            ComparisonRow(icon: "bell.badge.fill", feature: "自定义提醒", free: "基础", pro: "完整")
            ComparisonRow(icon: "paintpalette.fill", feature: "更多主题", free: "基础", pro: "全部", isLast: true)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusLG, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusLG, style: .continuous)
                .stroke(DesignTokens.divider, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        .opacity(animationPhase >= 3 ? 1 : 0)
        .offset(y: animationPhase >= 3 ? 0 : 20)
    }

    // MARK: - Subscription Section
    private var subscriptionSection: some View {
        HStack(spacing: DesignTokens.spacingMD) {
            LifetimeCard(
                isSelected: isLifetimeSelected,
                price: lifetimePriceText,
                onTap: {
                    hapticManager.medium()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isLifetimeSelected = true
                        selectedProduct = subscriptionManager.lifetimeProduct
                    }
                }
            )

            MonthlyCard(
                isSelected: !isLifetimeSelected,
                price: monthlyPriceText,
                onTap: {
                    hapticManager.light()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isLifetimeSelected = false
                        selectedProduct = subscriptionManager.monthlyProduct
                    }
                }
            )
        }
        .opacity(animationPhase >= 3 ? 1 : 0)
        .offset(y: animationPhase >= 3 ? 0 : 24)
    }

    // MARK: - Purchase Section
    private var purchaseSection: some View {
        VStack(spacing: DesignTokens.spacingMD) {
            Divider()
                .padding(.horizontal, DesignTokens.spacing2XL)

            // Purchase Button
            Button(action: {
                guard let product = selectedProduct else { return }
                hapticManager.heavy()
                isPurchasing = true
                Task {
                    try await subscriptionManager.purchase(product)
                    isPurchasing = false
                    if subscriptionManager.isProUser {
                        hapticManager.success()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showPurchaseSuccess = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            dismiss()
                        }
                    }
                }
            }) {
                HStack(spacing: DesignTokens.spacingSM) {
                    if subscriptionManager.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(purchaseButtonTitle)
                            .font(.system(size: 16, weight: .bold))

                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(
                        colors: isLifetimeSelected
                            ? [DesignTokens.accentGold, DesignTokens.accentGold.opacity(0.85)]
                            : [DesignTokens.accentRose, DesignTokens.accentRose.opacity(0.85)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMD, style: .continuous))
                .shadow(
                    color: (isLifetimeSelected
                            ? DesignTokens.accentGold
                            : DesignTokens.accentRose).opacity(0.4),
                    radius: 10,
                    y: 5
                )
                .scaleEffect(isPurchasing ? 0.96 : 1)
            }
            .disabled(subscriptionManager.isLoading || selectedProduct == nil)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPurchasing)
            .padding(.horizontal, DesignTokens.spacingXL)

            // Footer
            HStack(spacing: DesignTokens.spacingXL) {
                FooterLink(title: "恢复购买") {
                    hapticManager.light()
                    Task { await subscriptionManager.restorePurchases() }
                }
                FooterLink(title: "服务条款") {
                    hapticManager.light()
                    activeLegalDocument = .terms
                }
                FooterLink(title: "隐私政策") {
                    hapticManager.light()
                    activeLegalDocument = .privacy
                }
            }

            Text(purchaseFootnote)
                .font(.system(size: 11))
                .foregroundColor(DesignTokens.textTertiary)
        }
        .padding(.bottom, DesignTokens.spacingLG)
        .opacity(animationPhase >= 4 ? 1 : 0)
        .offset(y: animationPhase >= 4 ? 0 : 20)
    }

    // MARK: - Purchase Success Overlay
    private var purchaseSuccessOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: DesignTokens.spacingLG) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                    .symbolEffect(.bounce, value: showPurchaseSuccess)

                Text("开通成功！")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(DesignTokens.textPrimary)

                Text("已解锁成长报告、长期趋势和数据导出")
                    .font(.system(size: 14))
                    .foregroundColor(DesignTokens.textSecondary)
            }
            .padding(DesignTokens.spacing2XL)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusXL, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
        }
        .transition(.opacity)
    }
}

// MARK: - Report Metric Card
struct ReportMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(DesignTokens.textPrimary)
                .lineLimit(1)

            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(DesignTokens.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMD, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusMD, style: .continuous)
                .stroke(color.opacity(0.12), lineWidth: 1)
        )
    }
}

// MARK: - Value Reason Row
struct ValueReasonRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: DesignTokens.spacingMD) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(DesignTokens.accentGold)
                .frame(width: 32, height: 32)
                .background(DesignTokens.accentGoldLight.opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DesignTokens.textPrimary)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignTokens.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Feature Pill
struct FeaturePill: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: DesignTokens.spacingXS) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(DesignTokens.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.spacingMD)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMD, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusMD, style: .continuous)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Comparison Row
struct ComparisonRow: View {
    let icon: String
    let feature: String
    let free: String
    let pro: String
    var isFirst: Bool = false
    var isLast: Bool = false

    var body: some View {
        HStack(spacing: DesignTokens.spacingMD) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(DesignTokens.accentGold.opacity(0.7))
                .frame(width: 20)

            Text(feature)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(DesignTokens.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(free)
                .font(.system(size: 13))
                .foregroundColor(free == "✗" ? DesignTokens.accentRose.opacity(0.7) : DesignTokens.textTertiary)
                .frame(width: 50)

            Text(pro)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(DesignTokens.accentGold)
                .frame(width: 50)
        }
        .padding(.horizontal, DesignTokens.spacingLG)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            if !isLast {
                Divider()
                    .padding(.horizontal, DesignTokens.spacingLG)
            }
        }
    }
}

// MARK: - Lifetime Card
struct LifetimeCard: View {
    let isSelected: Bool
    let price: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 5) {
                    // Checkmark
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isSelected ? .white : DesignTokens.textTertiary)
                        .symbolEffect(.bounce, value: isSelected)

                    // Title
                    HStack(spacing: 3) {
                        Text("永久会员")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(isSelected ? .white : DesignTokens.textPrimary)

                        Image(systemName: "crown.fill")
                            .font(.system(size: 8))
                            .foregroundColor(isSelected ? .white : DesignTokens.accentGold)
                    }

                    // Price
                    Text(price)
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundColor(isSelected ? .white : DesignTokens.accentRose)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    // Subtitle
                    Text("一次开通\n长期更划算")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(isSelected ? .white.opacity(0.85) : DesignTokens.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .padding(.horizontal, 5)

                // Badge
                Text("推荐")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        LinearGradient(
                            colors: [DesignTokens.accentRose, DesignTokens.accentRose.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .offset(x: -6, y: 6)
            }
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.radiusMD, style: .continuous)
                    .fill(
                        isSelected
                            ? AnyShapeStyle(LinearGradient(
                                colors: [DesignTokens.accentGold, DesignTokens.accentGold.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            : AnyShapeStyle(Color.white)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.radiusMD, style: .continuous)
                    .stroke(isSelected ? Color.clear : DesignTokens.accentGold.opacity(0.3), lineWidth: 1)
            )
            .shadow(
                color: isSelected ? DesignTokens.accentGold.opacity(0.25) : .black.opacity(0.05),
                radius: isSelected ? 8 : 5,
                y: isSelected ? 3 : 2
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Monthly Card
struct MonthlyCard: View {
    let isSelected: Bool
    let price: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 5) {
                // Checkmark
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : DesignTokens.textTertiary)
                    .symbolEffect(.bounce, value: isSelected)

                // Title
                Text("月度订阅")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isSelected ? .white : DesignTokens.textPrimary)

                // Price
                Text(price)
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundColor(isSelected ? .white : DesignTokens.accentRose)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                // Subtitle
                Text("先体验\n随时取消")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(isSelected ? .white.opacity(0.85) : DesignTokens.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 5)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.radiusMD, style: .continuous)
                    .fill(
                        isSelected
                            ? AnyShapeStyle(LinearGradient(
                                colors: [DesignTokens.accentRose, DesignTokens.accentRose.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            : AnyShapeStyle(Color.white)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.radiusMD, style: .continuous)
                    .stroke(isSelected ? Color.clear : DesignTokens.divider, lineWidth: 1)
            )
            .shadow(
                color: isSelected ? DesignTokens.accentRose.opacity(0.25) : .black.opacity(0.05),
                radius: isSelected ? 8 : 5,
                y: isSelected ? 3 : 2
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Footer Link
struct FooterLink: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(DesignTokens.textSecondary)
        }
    }
}

// MARK: - Legal Documents
private enum LegalDocument: String, Identifiable {
    case terms
    case privacy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .terms:
            return "服务条款"
        case .privacy:
            return "隐私政策"
        }
    }

    var sections: [(title: String, body: String)] {
        switch self {
        case .terms:
            return [
                (
                    "Pro 功能",
                    "Pro 功能用于解锁宝宝成长报告、长期趋势、多宝宝记录、数据导出、自定义提醒和更多主题等能力。功能内容可能随版本优化调整。"
                ),
                (
                    "购买与订阅",
                    "月度订阅为自动续订项目，价格、周期和扣费规则以 App Store 购买确认页显示为准。订阅会在当前周期结束前自动续订，除非你在 App Store 账户设置中取消。"
                ),
                (
                    "永久会员",
                    "永久会员为一次性购买项目，付款成功后可长期解锁当前 App 内的 Pro 功能，不属于自动续订订阅。"
                ),
                (
                    "恢复购买",
                    "更换设备、重新安装或已购买但未解锁时，可以在本页面使用“恢复购买”同步 App Store 购买记录。"
                ),
                (
                    "使用限制",
                    "本 App 仅用于家庭日常记录和提醒，不构成医疗建议。涉及宝宝健康、疫苗、症状或体温异常时，请咨询专业医生。"
                )
            ]
        case .privacy:
            return [
                (
                    "数据存储",
                    "宝宝资料、喂养、睡眠、尿布、成长、疫苗和症状等记录会保存在你的设备本地，用于展示统计、提醒和历史记录。"
                ),
                (
                    "iCloud 同步与家庭共享",
                    "当你的设备登录 iCloud 并可用时，记录可通过 Apple iCloud/CloudKit 同步到你的私人数据库。你主动生成家庭共享邀请后，受邀家人可以查看并新增共享宝宝的记录。"
                ),
                (
                    "数据导出",
                    "当你主动使用数据导出功能时，App 会在本机生成导出文件。导出后的保存、分享或发送由你自行决定。"
                ),
                (
                    "通知提醒",
                    "如果你开启提醒，App 会使用本地通知提醒喂养、睡眠或尿布等事项。你可以在 App 设置或系统设置中关闭通知。"
                ),
                (
                    "追踪与第三方",
                    "当前版本不包含广告追踪或第三方分析 SDK。iCloud 同步和家庭共享由 Apple CloudKit 提供，仅在你使用相关系统服务或主动开启共享时生效。"
                ),
                (
                    "删除数据",
                    "你可以在 App 内删除记录；卸载 App 通常会移除本机保存的数据。已同步到 iCloud 的数据会按 Apple iCloud 和 CloudKit 的同步机制处理。"
                )
            ]
        }
    }
}

private struct LegalDocumentView: View {
    let document: LegalDocument
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.spacingXL) {
                    ForEach(Array(document.sections.enumerated()), id: \.offset) { _, section in
                        VStack(alignment: .leading, spacing: DesignTokens.spacingSM) {
                            Text(section.title)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(DesignTokens.textPrimary)

                            Text(section.body)
                                .font(.system(size: 14))
                                .foregroundColor(DesignTokens.textSecondary)
                                .lineSpacing(4)
                        }
                    }
                }
                .padding(DesignTokens.spacingXL)
            }
            .navigationTitle(document.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .semibold))
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ProView()
}

import SwiftUI

struct BottomNavBar: View {
    @Binding var selectedTab: Int
    @Namespace private var namespace

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.surfaceVariant.opacity(0.2))

            HStack(spacing: 0) {
                NavBarItem(
                    icon: "house.fill",
                    title: "首页",
                    isSelected: selectedTab == 0,
                    namespace: namespace
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 0
                    }
                }

                NavBarItem(
                    icon: "book.fill",
                    title: "记录",
                    isSelected: selectedTab == 1,
                    namespace: namespace
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 1
                    }
                }

                NavBarItem(
                    icon: "person.fill",
                    title: "我的",
                    isSelected: selectedTab == 2,
                    namespace: namespace
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 2
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.surfaceContainerLowest.opacity(0.95))
        }
        .shadow(color: Color.black.opacity(0.04), radius: 12, y: -4)
    }
}

struct NavBarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let namespace: Namespace.ID

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: isSelected ? 22 : 20))
                .foregroundColor(isSelected ? Color.primary : Color.outline)
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .symbolEffect(.bounce, value: isSelected)

            Text(title)
                .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? Color.primary : Color.outline)

            if isSelected {
                Circle()
                    .fill(Color.primary)
                    .frame(width: 5, height: 5)
                    .matchedGeometryEffect(id: "tabIndicator", in: namespace)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 5, height: 5)
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
}

#Preview {
    BottomNavBar(selectedTab: .constant(0))
}

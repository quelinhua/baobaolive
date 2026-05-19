import SwiftUI

struct BottomNavBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.surfaceVariant.opacity(0.2))

            HStack(spacing: 0) {
                NavBarItem(icon: "house.fill", title: "首页", isSelected: selectedTab == 0)
                    .onTapGesture { selectedTab = 0 }

                NavBarItem(icon: "book.fill", title: "记录", isSelected: selectedTab == 1)
                    .onTapGesture { selectedTab = 1 }

                NavBarItem(icon: "person.fill", title: "我的", isSelected: selectedTab == 2)
                    .onTapGesture { selectedTab = 2 }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.surfaceContainerLowest.opacity(0.95))
        }
        .shadow(color: Color.black.opacity(0.02), radius: 12, y: -4)
    }
}

struct NavBarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(isSelected ? Color.primary : Color.outline)

            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(isSelected ? Color.primary : Color.outline)
        }
        .frame(maxWidth: .infinity)
    }
}

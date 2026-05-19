import SwiftUI

struct CategoriesManageView: View {
    @Binding var homePageCategories: [String]
    @Environment(\.dismiss) var dismiss
    @State private var isEditing = false
    @State private var selectedType: RecordType? = nil
    @State private var showAddRecord = false

    let allTypes = RecordType.allCases
    let minHomePageCount = 3
    let maxHomePageCount = 10

    var homeTypes: [RecordType] {
        homePageCategories.compactMap { RecordType(rawValue: $0) }
    }

    var otherTypes: [RecordType] {
        allTypes.filter { !homePageCategories.contains($0.rawValue) }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                List {
                    Section {
                        ForEach(homeTypes) { type in
                            HStack(spacing: 14) {
                                if isEditing {
                                    Image(systemName: "line.3.horizontal")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color.outline)
                                }

                                Image(systemName: type.iconName)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(Color.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                Text(type.displayName)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color.onSurface)

                                Spacer()

                                Text("首页")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color.primary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.primaryContainer.opacity(0.5))
                                    .clipShape(Capsule())

                                if isEditing && homeTypes.count > minHomePageCount {
                                    Button(action: { removeFromHome(type) }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(Color.error)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .onMove { from, to in
                            homePageCategories.move(fromOffsets: from, toOffset: to)
                        }
                    } header: {
                        Text("已在首页 (\(homeTypes.count)/\(maxHomePageCount))")
                    }

                    if !otherTypes.isEmpty {
                        Section {
                            ForEach(otherTypes) { type in
                                HStack(spacing: 14) {
                                    Image(systemName: type.iconName)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color.outline)
                                        .frame(width: 32, height: 32)
                                        .background(Color.surfaceVariant.opacity(0.5))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))

                                    Text(type.displayName)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color.outline)

                                    Spacer()

                                    Button(action: { addToHome(type) }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 22))
                                            .foregroundColor(homeTypes.count >= maxHomePageCount ? Color.outlineVariant : Color.primary)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .disabled(homeTypes.count >= maxHomePageCount)
                                }
                                .padding(.vertical, 4)
                            }
                        } header: {
                            Text("更多项目")
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("所有记录项目")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(isEditing ? "完成" : "编辑") {
                        withAnimation { isEditing.toggle() }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }

    func addToHome(_ type: RecordType) {
        guard homeTypes.count < maxHomePageCount else { return }
        withAnimation {
            homePageCategories.append(type.rawValue)
        }
    }

    func removeFromHome(_ type: RecordType) {
        guard homeTypes.count > minHomePageCount else { return }
        withAnimation {
            homePageCategories.removeAll { $0 == type.rawValue }
        }
    }
}

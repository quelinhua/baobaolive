import SwiftUI
import SwiftData

struct BabyProfileEditView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    @State private var name: String
    @State private var birthDate: Date
    @State private var gender: String

    let isNew: Bool
    let editingProfile: BabyProfile?

    init(profile: BabyProfile?, isNew: Bool = false) {
        self.editingProfile = profile
        self.isNew = isNew
        if let profile = profile {
            _name = State(initialValue: profile.name)
            _birthDate = State(initialValue: profile.birthDate)
            _gender = State(initialValue: profile.gender)
        } else {
            _name = State(initialValue: "")
            _birthDate = State(initialValue: Date())
            _gender = State(initialValue: "女")
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section("基本信息") {
                    HStack(spacing: 12) {
                        Image(systemName: "face.smiling.inverse")
                            .font(.system(size: 16))
                            .foregroundColor(Color.primary)
                            .frame(width: 28)
                        TextField("宝宝姓名", text: $name)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "calendar")
                            .font(.system(size: 16))
                            .foregroundColor(Color.primary)
                            .frame(width: 28)
                        DatePicker("出生日期", selection: $birthDate, displayedComponents: .date)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "person")
                            .font(.system(size: 16))
                            .foregroundColor(Color.primary)
                            .frame(width: 28)
                        Picker("性别", selection: $gender) {
                            Text("女").tag("女")
                            Text("男").tag("男")
                        }
                    }
                }

                Section {
                    Button(action: save) {
                        HStack {
                            Spacer()
                            Text(isNew ? "创建宝宝资料" : "保存修改")
                                .font(.system(size: 16, weight: .semibold))
                            Spacer()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .navigationTitle(isNew ? "新建宝宝资料" : "编辑宝宝资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }

    func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        if isNew {
            let profile = BabyProfile(name: trimmedName, birthDate: birthDate, gender: gender)
            modelContext.insert(profile)
            BabyManager.shared.selectBaby(profile)
        } else if let existing = editingProfile {
            existing.name = trimmedName
            existing.birthDate = birthDate
            existing.gender = gender
        }
        dismiss()
    }
}

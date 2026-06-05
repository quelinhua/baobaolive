import SwiftUI
import SwiftData

struct BabyProfileEditView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    @State private var name: String
    @State private var birthDate: Date
    @State private var gender: String
    @State private var avatarImageData: Data?

    let isNew: Bool
    let editingProfile: BabyProfile?

    init(profile: BabyProfile?, isNew: Bool = false) {
        self.editingProfile = profile
        self.isNew = isNew || profile == nil
        if let profile = profile {
            _name = State(initialValue: profile.name)
            _birthDate = State(initialValue: profile.birthDate)
            _gender = State(initialValue: profile.gender)
            _avatarImageData = State(initialValue: profile.avatarImageData)
        } else {
            _name = State(initialValue: "")
            _birthDate = State(initialValue: Date())
            _gender = State(initialValue: "女")
            _avatarImageData = State(initialValue: nil)
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section("宝宝头像") {
                    HStack {
                        Spacer()
                        EditableBabyAvatarView(imageData: $avatarImageData, size: 104)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }

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
            profile.avatarImageData = avatarImageData
            let existingProfiles = (try? modelContext.fetch(FetchDescriptor<BabyProfile>())) ?? []
            for item in existingProfiles {
                item.isSelected = false
            }
            profile.isSelected = true
            modelContext.insert(profile)
            BabyManager.shared.selectBaby(profile)
            if existingProfiles.isEmpty {
                RecordWorkflow.assignUnassignedRecords(to: profile, in: modelContext)
            }
        } else if let existing = editingProfile {
            existing.name = trimmedName
            existing.birthDate = birthDate
            existing.gender = gender
            existing.avatarImageData = avatarImageData
            if existing.isFamilyShared {
                Task {
                    await FamilySharingManager.shared.syncAll(context: modelContext)
                }
            }
        }
        try? modelContext.save()
        dismiss()
    }
}

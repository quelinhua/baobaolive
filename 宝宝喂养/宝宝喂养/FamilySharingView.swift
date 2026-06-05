import CoreImage.CIFilterBuiltins
import SwiftData
import SwiftUI
import UIKit

struct FamilySharingView: View {
    let baby: BabyProfile?
    let records: [RecordModel]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var sharingManager = FamilySharingManager.shared
    @State private var inviteURL: URL?
    @State private var copied = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    headerCard

                    if let baby {
                        if baby.isFamilyOwner {
                            ownerContent(baby)
                        } else {
                            participantContent(baby)
                        }
                    } else {
                        emptyContent
                    }

                    statusContent
                }
                .padding(20)
            }
            .background(Color.background.ignoresSafeArea())
            .navigationTitle("家庭共享")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
            .onAppear {
                if let urlString = baby?.cloudKitShareURLString {
                    inviteURL = URL(string: urlString)
                }
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.primaryContainer.opacity(0.48))
                        .frame(width: 50, height: 50)
                    Image(systemName: "person.2.badge.plus.fill")
                        .font(.system(size: 23, weight: .semibold))
                        .foregroundColor(Color.primary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("邀请家人一起记录")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color.onSurface)
                    Text("家人接受邀请后，可以查看并新增宝宝记录")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.outline)
                }
            }

            HStack(spacing: 8) {
                Label("二维码邀请", systemImage: "qrcode")
                Label("链接分享", systemImage: "link")
                Label("新增记录同步", systemImage: "icloud.fill")
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(Color.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.025), radius: 6, y: 2)
    }

    private func ownerContent(_ baby: BabyProfile) -> some View {
        VStack(spacing: 14) {
            if let inviteURL {
                QRInviteCard(url: inviteURL, babyName: baby.name)

                HStack(spacing: 12) {
                    ShareLink(item: inviteURL) {
                        actionButton(title: "分享邀请", icon: "square.and.arrow.up.fill", filled: true)
                    }
                    .buttonStyle(.plain)

                    Button {
                        UIPasteboard.general.string = inviteURL.absoluteString
                        copied = true
                    } label: {
                        actionButton(title: copied ? "已复制" : "复制链接", icon: copied ? "checkmark.circle.fill" : "link", filled: false)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 46))
                        .foregroundColor(Color.primary)
                        .padding(.top, 6)
                    Text("生成二维码邀请")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.onSurface)
                    Text("生成后，家人可用系统相机或微信扫码加入")
                        .font(.system(size: 13))
                        .foregroundColor(Color.outline)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(Color.surfaceContainerLowest)
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }

            Button {
                Task {
                    inviteURL = await sharingManager.createOrUpdateShare(for: baby, records: records, context: modelContext)
                }
            } label: {
                actionButton(title: inviteURL == nil ? "生成邀请二维码" : "重新同步邀请", icon: "person.crop.circle.badge.plus", filled: true)
            }
            .buttonStyle(.plain)
            .disabled(sharingManager.isWorking)

            syncButton
        }
    }

    private func participantContent(_ baby: BabyProfile) -> some View {
        VStack(spacing: 14) {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.icloud.fill")
                    .font(.system(size: 44))
                    .foregroundColor(Color.primary)
                Text("已加入\(baby.name)的家庭记录")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.onSurface)
                    .multilineTextAlignment(.center)
                Text("你可以查看记录，也可以新增喂奶、睡眠、尿布等记录")
                    .font(.system(size: 13))
                    .foregroundColor(Color.outline)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(Color.surfaceContainerLowest)
            .clipShape(RoundedRectangle(cornerRadius: 18))

            syncButton
        }
    }

    private var emptyContent: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 44))
                .foregroundColor(Color.outline)
            Text("请先创建宝宝资料")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color.onSurface)
            Text("创建资料后，就可以邀请家人一起记录")
                .font(.system(size: 13))
                .foregroundColor(Color.outline)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var syncButton: some View {
        Button {
            Task {
                await sharingManager.syncAll(context: modelContext)
            }
        } label: {
            actionButton(title: "同步家庭记录", icon: "arrow.clockwise.icloud.fill", filled: false)
        }
        .buttonStyle(.plain)
        .disabled(sharingManager.isWorking)
    }

    private var statusContent: some View {
        VStack(spacing: 10) {
            if sharingManager.isWorking {
                ProgressView()
                    .tint(Color.primary)
                Text(sharingManager.statusMessage.isEmpty ? "正在处理..." : sharingManager.statusMessage)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.outline)
            } else if !sharingManager.lastErrorMessage.isEmpty {
                Label(sharingManager.lastErrorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.error)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.error.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            } else if !sharingManager.statusMessage.isEmpty {
                Label(sharingManager.statusMessage, systemImage: "checkmark.circle.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.primary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func actionButton(title: String, icon: String, filled: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .foregroundColor(filled ? Color.onPrimary : Color.primary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(filled ? Color.primary : Color.primaryContainer.opacity(0.34))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

private struct QRInviteCard: View {
    let url: URL
    let babyName: String

    var body: some View {
        VStack(spacing: 14) {
            Text("\(babyName)的家庭邀请")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color.onSurface)

            if let image = QRCodeGenerator.image(from: url.absoluteString) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 210, height: 210)
                    .padding(14)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
            }

            Text("家人用系统相机或微信扫码，即可打开邀请并加入共同记录")
                .font(.system(size: 13))
                .foregroundColor(Color.outline)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.025), radius: 6, y: 2)
    }
}

private enum QRCodeGenerator {
    static func image(from string: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else { return nil }
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)
        let context = CIContext()

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

import PhotosUI
import SwiftUI
import UIKit

struct BabyAvatarView: View {
    let imageData: Data?
    var size: CGFloat = 72
    var iconSize: CGFloat? = nil
    var backgroundColor: Color = Color.primaryContainer
    var foregroundColor: Color = Color.primary
    var borderColor: Color = Color.clear
    var borderWidth: CGFloat = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)

            if let uiImage = imageData.flatMap(UIImage.init(data:)) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Image(systemName: "face.smiling.inverse")
                    .font(.system(size: iconSize ?? size * 0.48))
                    .foregroundColor(foregroundColor)
            }
        }
        .frame(width: size, height: size)
        .overlay(
            Circle()
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .contentShape(Circle())
        .accessibilityHidden(true)
    }
}

struct EditableBabyAvatarView: View {
    @Binding var imageData: Data?
    var size: CGFloat = 108
    var tint: Color = Color.primary
    var foregroundColor: Color = Color.primary
    var backgroundColor: Color = Color.primaryContainer

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isLoading = false
    @State private var hasLoadError = false

    var body: some View {
        VStack(spacing: 10) {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    BabyAvatarView(
                        imageData: imageData,
                        size: size,
                        backgroundColor: backgroundColor,
                        foregroundColor: foregroundColor,
                        borderColor: Color.white.opacity(0.9),
                        borderWidth: 3
                    )
                    .shadow(color: tint.opacity(0.18), radius: 10, y: 4)

                    ZStack {
                        Circle()
                            .fill(tint)
                            .frame(width: 34, height: 34)
                        if isLoading {
                            ProgressView()
                                .tint(Color.onPrimary)
                                .scaleEffect(0.72)
                        } else {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color.onPrimary)
                        }
                    }
                    .overlay(Circle().stroke(Color.surface, lineWidth: 2))
                    .offset(x: 1, y: 1)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isLoading)
            .accessibilityLabel("选择宝宝头像")
            .onChange(of: selectedPhotoItem) { _, newItem in
                loadPhoto(from: newItem)
            }

            Text(imageData == nil ? "点击添加宝宝头像" : "点击更换宝宝头像")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.outline)

            if imageData != nil {
                Button("恢复默认头像") {
                    imageData = nil
                    hasLoadError = false
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(tint)
            }

            if hasLoadError {
                Text("照片处理失败，请换一张试试")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.error)
            }
        }
    }

    private func loadPhoto(from item: PhotosPickerItem?) {
        guard let item else { return }
        isLoading = true
        hasLoadError = false

        Task {
            let data = try? await item.loadTransferable(type: Data.self)
            let avatarData = data.flatMap { BabyAvatarImageProcessor.compressedJPEGData(from: $0) }

            await MainActor.run {
                if let avatarData {
                    imageData = avatarData
                } else {
                    hasLoadError = true
                }
                selectedPhotoItem = nil
                isLoading = false
            }
        }
    }
}

enum BabyAvatarImageProcessor {
    static func compressedJPEGData(from data: Data, maxPixel: CGFloat = 512, quality: CGFloat = 0.82) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let largestSide = max(image.size.width, image.size.height)
        guard largestSide > 0 else { return nil }

        let scale = min(maxPixel / largestSide, 1)
        let targetSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return resizedImage.jpegData(compressionQuality: quality)
    }
}

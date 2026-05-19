import SwiftUI

struct WheelPicker: View {
    let items: [Int]
    @Binding var selectedIndex: Int
    let displayTransform: (Int) -> String

    private let itemHeight: CGFloat = 44
    private let visibleCount = 5

    @State private var lastHapticIndex: Int = -1
    @State private var didInitialScroll = false
    private let haptic = UIImpactFeedbackGenerator(style: .light)

    init(items: [Int], selectedIndex: Binding<Int>, displayTransform: @escaping (Int) -> String = { String(format: "%02d", $0) }) {
        self.items = items
        self._selectedIndex = selectedIndex
        self.displayTransform = displayTransform
    }

    var body: some View {
        let totalHeight = itemHeight * CGFloat(visibleCount)

        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, value in
                        Text(displayTransform(value))
                            .font(.system(size: selectedIndex == index ? 28 : 20, weight: selectedIndex == index ? .bold : .medium, design: .rounded))
                            .foregroundColor(selectedIndex == index ? Color.primary : Color.outline.opacity(0.4))
                            .frame(height: itemHeight)
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                            .id(index)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedIndex = index
                                    proxy.scrollTo(index, anchor: .center)
                                }
                                haptic.impactOccurred()
                            }
                    }
                }
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .preference(
                                key: ScrollOffsetKey.self,
                                value: geo.frame(in: .named("scroll")).minY
                            )
                    }
                )
                .padding(.vertical, totalHeight / 2 - itemHeight / 2)
            }
            .frame(height: totalHeight)
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetKey.self) { minY in
                let centerY = totalHeight / 2
                let rawIndex = Int(round((centerY - minY - itemHeight / 2) / itemHeight))
                let newIndex = max(0, min(items.count - 1, rawIndex))

                if newIndex != selectedIndex {
                    selectedIndex = newIndex
                    if newIndex != lastHapticIndex {
                        lastHapticIndex = newIndex
                        haptic.impactOccurred()
                    }
                }
            }
            .onAppear {
                haptic.prepare()
                didInitialScroll = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    proxy.scrollTo(selectedIndex, anchor: .center)
                    didInitialScroll = true
                }
            }
            .mask(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black.opacity(0.3), location: 0.2),
                        .init(color: .black, location: 0.4),
                        .init(color: .black, location: 0.6),
                        .init(color: .black.opacity(0.3), location: 0.8),
                        .init(color: .clear, location: 1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.primary.opacity(0.08))
                    .frame(height: itemHeight)
                    .allowsHitTesting(false),
                alignment: .center
            )
        }
    }
}

private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

import SwiftUI

struct ContentView: View {
    @State private var selectedIndex: Int = 5

    // 10 个 icon（用你的 Figma 资源名替换）
    private let icons: [String] = [
        "icon_sun", "icon_grid", "icon_mountain", "icon_moon",
        "icon_arrows", "icon_hz", "icon_8", "icon_dots",
        "icon_leaf", "icon_square"
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                Spacer()

                IconScrollBar(
                    icons: icons,
                    selectedIndex: $selectedIndex
                )
                .padding(.bottom, 24)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Scroll Bar (10 items, ~5 visible, with fade masks)
struct IconScrollBar: View {

    let icons: [String]
    @Binding var selectedIndex: Int

    // 让“一屏大概显示 5 个”
    private let itemSize: CGFloat = 44
    private let itemSpacing: CGFloat = 14

    // 左右遮罩宽度（越大越“虚化提示明显”）
    private let fadeWidth: CGFloat = 36

    var body: some View {
        ZStack {
            // 可滚动区域
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: itemSpacing) {

                        // 这里用 padding 让第一/最后也能滚到“舒服位置”
                        Spacer().frame(width: 8)

                        ForEach(icons.indices, id: \.self) { index in
                            Button {
                                withAnimation(.easeOut(duration: 0.18)) {
                                    selectedIndex = index
                                }
                                // 点击后把选中项滚动到可见/接近居中
                                withAnimation(.easeOut(duration: 0.25)) {
                                    proxy.scrollTo(index, anchor: .center)
                                }
                            } label: {
                                IconCircle(
                                    isSelected: index == selectedIndex,
                                    assetName: icons[index],
                                    size: itemSize
                                )
                            }
                            .buttonStyle(.plain)
                            .id(index)
                        }

                        Spacer().frame(width: 8)
                    }
                    // 关键：限制宽度，让视觉上只露出约 5 个
                    .frame(maxWidth: barWidthForFiveItems())
                    .padding(.vertical, 8)
                }
                // 进入界面时，自动滚到当前选中项附近
                .onAppear {
                    DispatchQueue.main.async {
                        proxy.scrollTo(selectedIndex, anchor: .center)
                    }
                }
                .onChange(of: selectedIndex) { _, newValue in
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }

            // 左右“黑色虚化遮罩”（渐变）
            HStack {
                fadeMaskLeft
                Spacer()
                fadeMaskRight
            }
            .allowsHitTesting(false) // 避免遮罩挡住滚动/点击
        }
    }

    /// 让 bar 的可视宽度大约容纳 5 个 item
    private func barWidthForFiveItems() -> CGFloat {
        // 5 个 item + 4 个间距
        (itemSize * 5) + (itemSpacing * 4)
    }

    private var fadeMaskLeft: some View {
        LinearGradient(
            colors: [
                .black.opacity(0.95),
                .black.opacity(0.55),
                .black.opacity(0.0)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: fadeWidth)
    }

    private var fadeMaskRight: some View {
        LinearGradient(
            colors: [
                .black.opacity(0.0),
                .black.opacity(0.55),
                .black.opacity(0.95)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: fadeWidth)
    }
}

// MARK: - Icon Circle (tint gray -> white)
struct IconCircle: View {

    let isSelected: Bool
    let assetName: String
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(isSelected ? 0.18 : 0.08))
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(isSelected ? 0.18 : 0.10), lineWidth: 1)
                )

            Image(assetName)
                .renderingMode(.template)
                .foregroundColor(isSelected ? .white : .white.opacity(0.35))
                .frame(width: size * 0.52, height: size * 0.52)
        }
        .frame(width: size, height: size)
        .animation(.easeOut(duration: 0.18), value: isSelected)
    }
}

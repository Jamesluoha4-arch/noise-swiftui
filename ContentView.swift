import SwiftUI

// MARK: - Your Main Screen
struct ContentView: View {
    @State private var selectedIndex: Int = 0

    // 用你的 Assets 名称替换这 10 个
    private let icons: [String] = [
        "icon_sun", "icon_grid", "icon_mountain", "icon_moon", "icon_arrows",
        "icon_hz", "icon_8", "icon_dots", "icon_leaf", "icon_square"
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                Spacer()

                IconScrollBar(icons: icons, selectedIndex: $selectedIndex)
                    .padding(.bottom, 24)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Scroll Bar (10 items, ~5 prominent, full width with fade masks)
struct IconScrollBar: View {

    let icons: [String]
    @Binding var selectedIndex: Int

    // ===== 版式参数（按参考图调过）=====
    private let circleSize: CGFloat = 60          // 圆圈视觉尺寸
    private let hitSize: CGFloat = 44             // 触摸命中区域
    private let spacing: CGFloat = 23             // 圆圈之间间距
    private let verticalPadding: CGFloat = 15      // bar 上下留白
    private let sideInset: CGFloat = 18           // 左右内边距

    private let fadeWidth: CGFloat = 32
    private let fadeStrong: Double = 1.0
    private let fadeMid: Double = 0.65
    private let fadeClear: Double = 0.0

    var body: some View {
        ZStack {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: spacing) {
                        Spacer().frame(width: sideInset)

                        ForEach(icons.indices, id: \.self) { index in
                            Button {
                                withAnimation(.easeOut(duration: 0.18)) {
                                    selectedIndex = index
                                }
                                withAnimation(.easeOut(duration: 0.25)) {
                                    proxy.scrollTo(index, anchor: .center)
                                }
                            } label: {
                                IconCircle(
                                    isSelected: index == selectedIndex,
                                    assetName: icons[index],
                                    circleSize: circleSize,
                                    hitSize: hitSize
                                )
                            }
                            .buttonStyle(.plain)
                            .id(index)
                        }

                        Spacer().frame(width: sideInset)
                    }
                    .padding(.vertical, verticalPadding)
                }
                .frame(maxWidth: .infinity)
                .background(Color.black)
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

            // 左右渐隐遮罩（暗示可滑动）
            HStack {
                fadeMaskLeft
                Spacer()
                fadeMaskRight
            }
            .allowsHitTesting(false)
        }
    }

    private var fadeMaskLeft: some View {
        LinearGradient(
            colors: [
                .black.opacity(fadeStrong),
                .black.opacity(fadeMid),
                .black.opacity(fadeClear)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: fadeWidth)
    }

    private var fadeMaskRight: some View {
        LinearGradient(
            colors: [
                .black.opacity(fadeClear),
                .black.opacity(fadeMid),
                .black.opacity(fadeStrong)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: fadeWidth)
    }
}

// MARK: - Icon Circle (tint gray -> white, thin ring)
struct IconCircle: View {

    let isSelected: Bool
    let assetName: String
    let circleSize: CGFloat
    let hitSize: CGFloat

    private var iconColor: Color {
        isSelected ? .white : .white.opacity(0.33)
    }
    private var fillOpacity: Double {
        isSelected ? 0.14 : 0.06
    }
    private var strokeOpacity: Double {
        isSelected ? 0.22 : 0.12
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(fillOpacity))
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(strokeOpacity), lineWidth: 1)
                )
                .frame(width: circleSize, height: circleSize)

            Image(assetName)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .foregroundColor(iconColor)
                .frame(width: circleSize * 0.60, height: circleSize * 0.60)
        }
        .frame(width: hitSize, height: hitSize)
        .contentShape(Rectangle())
        .animation(.easeOut(duration: 0.16), value: isSelected)
    }
}

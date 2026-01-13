import SwiftUI

// MARK: - Your Main Screen
struct ContentView: View {
    @State private var selectedIndex: Int = 0

    // 用你的 Assets 名称替换这 10 个
    private let icons: [String] = [
        "icon_0", "icon_1", "icon_2", "icon_3", "icon_4",
        "icon_5", "icon_6", "icon_7", "icon_8", "icon_9"
    ]

    // ✅ 你的菜单 icon（你自己导入到 Assets，名字填这里）
    private let menuIconName: String = "icon_menu"

    // ✅ bar 整体向下移动：数值越大越靠下
    private let barBottomOffset: CGFloat = 56

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                Spacer()

                // ✅ bar + 右侧固定菜单（菜单不随滚动，置顶层）
                ZStack(alignment: .trailing) {

                    IconScrollBar(icons: icons, selectedIndex: $selectedIndex)
                        // ✅ 给右侧留空间，避免最后一个 icon 被菜单遮住
                        .padding(.trailing, 52)

                    MenuButton(assetName: menuIconName) {
                        print("menu tapped")
                    }
                    .padding(.trailing, 16)
                    // ✅ 如果你想菜单比 bar 略高/略低，调这个：
                    .offset(y: 0)
                }
                // ✅ bar 整体向下移动
                .padding(.bottom, barBottomOffset)
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
    private let circleSize: CGFloat = 38          // 圆圈视觉尺寸
    private let hitSize: CGFloat = 44             // 触摸命中区域
    private let spacing: CGFloat = 12             // 圆圈之间间距
    private let verticalPadding: CGFloat = 6      // bar 上下留白
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

// MARK: - Fixed Menu Button (top layer, not scroll)
struct MenuButton: View {
    let assetName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )

                Image(assetName)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .foregroundColor(.white.opacity(0.65))
                    .frame(width: 18, height: 18)
            }
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
    }
}

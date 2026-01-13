import SwiftUI

// MARK: - Scroll Bar (10 items, ~5 prominent, full width with fade masks)
struct IconScrollBar: View {

    let icons: [String]
    @Binding var selectedIndex: Int

    // ===== 版式参数（按参考图调过）=====
    private let circleSize: CGFloat = 38          // 圆圈视觉尺寸（参考图更小）
    private let hitSize: CGFloat = 44             // 触摸命中区域（保持 iOS 标准）
    private let spacing: CGFloat = 12             // 圆圈之间间距（更紧）
    private let verticalPadding: CGFloat = 6      // bar 上下留白（更薄）
    private let sideInset: CGFloat = 18           // 左右内边距（避免贴边太近）

    private let fadeWidth: CGFloat = 32           // 渐隐遮罩宽度（贴近参考图）
    private let fadeStrong: Double = 1.0          // 最黑处强度
    private let fadeMid: Double = 0.65            // 中间过渡
    private let fadeClear: Double = 0.0           // 透明

    var body: some View {
        ZStack {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: spacing) {
                        // 让首尾 item 也能滚到“舒服位置”
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
                .frame(maxWidth: .infinity)              // ✅ 关键：bar 容器全屏
                .background(Color.black)                 // ✅ 防止 ScrollView 默认底色干扰
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

    // 参考图的“灰白层级”
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
                .resizable()                 // ✅ 保险：即便你导出的是大图也能按比例缩放
                .renderingMode(.template)    // ✅ 允许用 foregroundColor 染色
                .scaledToFit()
                .foregroundColor(iconColor)
                .frame(width: circleSize * 0.60, height: circleSize * 0.60) // 图形占比更大
        }
        // ✅ 命中区域保持 44×44，手感好
        .frame(width: hitSize, height: hitSize)
        .contentShape(Rectangle())
        .animation(.easeOut(duration: 0.16), value: isSelected)
    }
}

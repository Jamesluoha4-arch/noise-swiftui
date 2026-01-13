import SwiftUI

// MARK: - 你的主界面
struct ContentView: View {
    @State private var selectedIndex: Int = 0
    @State private var selectedControlIndex: Int = 0
    @State private var clickParticles: [ClickParticleData] = []

    private let icons: [String] = [
        "icon_sun", "icon_grid", "icon_mountain", "icon_moon", "icon_arrows",
        "icon_hz", "icon_8", "icon_dots", "icon_leaf", "icon_square"
    ]

    // ✅ 你导入四个矩形按钮的 icon 名（用你自己的替换）
    private let controlIcons: [String] = [
        "control_feedback",   // 反馈
        "control_noise",      // 调节噪音
        "control_focus",      // Focus Timer
        "control_block"       // 拦截应用
    ]

    private let menuIconName: String = "icon_menu"
    private let infoIconName: String = "icon_info"

    private let barBottomOffset: CGFloat = -320
    private let menuReserveWidth: CGFloat = 60

    // 彩色粒子颜色
    private let particleColors: [Color] = [
        .red, .blue, .green, .yellow, .purple,
        .orange, .pink, .cyan, .mint, .teal
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // 添加粒子层（在背景之上，界面之下）
            ParticleLayer()
                .opacity(0.6)
                .allowsHitTesting(false)
                .ignoresSafeArea()

            // 点击粒子层（在最上层）
            ZStack {
                ForEach(clickParticles) { particle in
                    ClickParticleView(particle: particle)
                }
            }
            .allowsHitTesting(false)
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部标题区域
                HeaderView(infoIconName: infoIconName)
                    .padding(.top, 40)
                    .padding(.horizontal, 20)

                Spacer()

                // ✅ 底部区域：滚动栏 + 菜单按钮 + 四矩形按钮
                VStack(spacing: 14) {

                    // 滚动栏 + 固定菜单
                    ZStack(alignment: .trailing) {
                        IconScrollBar(icons: icons, selectedIndex: $selectedIndex)
                            .padding(.trailing, menuReserveWidth)

                        PlainIconButton(assetName: menuIconName, size: 18) {
                            print("menu tapped")
                        }
                        .padding(.trailing, 16)
                    }

                    // ✅ 新增：滚动栏下方四个矩形按钮
                    ControlBar(
                        icons: controlIcons,
                        selectedIndex: $selectedControlIndex
                    )
                    .padding(.horizontal, 18)
                }
                .padding(.bottom, barBottomOffset)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { location in
            // 创建点击粒子
            createClickParticle(at: location)
        }
        .preferredColorScheme(.dark)
    }

    private func createClickParticle(at location: CGPoint) {
        let newParticle = ClickParticleData(
            id: UUID(),
            position: location,
            color: particleColors.randomElement() ?? .white,
            startTime: Date()
        )

        clickParticles.append(newParticle)

        // 1.5秒后移除粒子
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                if let index = clickParticles.firstIndex(where: { $0.id == newParticle.id }) {
                    clickParticles.remove(at: index)
                }
            }
        }
    }
}

// MARK: - 点击粒子数据模型
struct ClickParticleData: Identifiable {
    let id: UUID
    let position: CGPoint
    let color: Color
    let startTime: Date
}

// MARK: - 点击粒子视图
struct ClickParticleView: View {
    let particle: ClickParticleData

    @State private var size: CGFloat = 60
    @State private var opacity: Double = 1.0

    var body: some View {
        ZStack {
            Circle()
                .fill(particle.color.opacity(opacity * 0.2))
                .frame(width: size * 1.5, height: size * 1.5)
                .blur(radius: 5)

            Circle()
                .fill(particle.color.opacity(opacity))
                .frame(width: size, height: size)

            Circle()
                .fill(Color.white.opacity(opacity * 0.3))
                .frame(width: size * 0.4, height: size * 0.4)
        }
        .position(particle.position)
        .onAppear { startAnimation() }
    }

    private func startAnimation() {
        withAnimation(.easeOut(duration: 0.3)) { size = 80 }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.linear(duration: 1.2)) {
                size = 10
                opacity = 0.1
            }
        }
    }
}

// MARK: - 粒子层（背景）
struct ParticleLayer: View {
    let particleCount = 40

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<particleCount, id: \.self) { index in
                    let isColored = index < 20
                    let color = isColored ? randomColor() : .white
                    let size = isColored ? CGFloat.random(in: 6...12) : CGFloat.random(in: 4...8)

                    ParticleView(
                        id: index,
                        color: color,
                        size: size,
                        screenSize: geometry.size,
                        fromLeft: isColored
                    )
                }
            }
        }
    }

    private func randomColor() -> Color {
        let colors: [Color] = [
            .red, .blue, .green, .yellow, .purple,
            .orange, .pink, .cyan, .mint, .teal
        ]
        return colors.randomElement() ?? .white
    }
}

struct ParticleView: View {
    let id: Int
    let color: Color
    let size: CGFloat
    let screenSize: CGSize
    let fromLeft: Bool

    @State private var x: CGFloat = 0
    @State private var y: CGFloat = 0

    var body: some View {
        Circle()
            .fill(color.opacity(0.5))
            .frame(width: size, height: size)
            .position(x: x, y: y)
            .onAppear {
                let startX = fromLeft ? -size : screenSize.width + size
                let startY = CGFloat.random(in: 100...screenSize.height - 200)

                x = startX
                y = startY

                let delay = Double(id) * 0.05
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    startAnimation()
                }
            }
    }

    private func startAnimation() {
        let flyInX = fromLeft ?
            CGFloat.random(in: 50...screenSize.width * 0.4) :
            CGFloat.random(in: screenSize.width * 0.6...screenSize.width - 50)
        let flyInY = CGFloat.random(in: 100...screenSize.height - 200)

        withAnimation(.easeOut(duration: 1.5)) {
            x = flyInX
            y = flyInY
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            randomMove()
        }
    }

    private func randomMove() {
        let targetX = CGFloat.random(in: 30...screenSize.width - 30)
        let targetY = CGFloat.random(in: 80...screenSize.height - 250)
        let duration = Double.random(in: 5.0...10.0)

        withAnimation(.linear(duration: duration)) {
            x = targetX
            y = targetY
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            randomMove()
        }
    }
}

// MARK: - 顶部标题
struct HeaderView: View {
    let infoIconName: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            PlainIconView(assetName: infoIconName, size: 20)
                .opacity(0)

            Spacer()

            VStack(alignment: .center, spacing: 4) {
                Text("Colored Noise")
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .foregroundColor(.white)
                    .kerning(0.5)

                Text("下午能量上升")
                    .font(.system(size: 14, weight: .medium, design: .default))
                    .foregroundColor(.white.opacity(0.7))
                    .kerning(0.3)
            }

            Spacer()

            PlainIconView(assetName: infoIconName, size: 30)
        }
        .frame(height: 40)
    }
}

// MARK: - 通用 icon view / button
struct PlainIconView: View {
    let assetName: String
    let size: CGFloat

    var body: some View {
        Image(assetName)
            .resizable()
            .renderingMode(.template)
            .scaledToFit()
            .foregroundColor(.white.opacity(0.7))
            .frame(width: size, height: size)
            .frame(width: 44, height: 44)
    }
}

struct PlainIconButton: View {
    let assetName: String
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(assetName)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .foregroundColor(.white.opacity(0.65))
                .frame(width: size, height: size)
                .contentShape(Rectangle())
        }
        .frame(width: 44, height: 44)
        .buttonStyle(.plain)
    }
}

// MARK: - 横向滚动 icon bar
struct IconScrollBar: View {
    let icons: [String]
    @Binding var selectedIndex: Int

    private let hitSize: CGFloat = 60
    private let spacing: CGFloat = 23
    private let verticalPadding: CGFloat = 15
    private let sideInset: CGFloat = 18

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
                                PlainScrollIcon(
                                    isSelected: index == selectedIndex,
                                    assetName: icons[index]
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

struct PlainScrollIcon: View {
    let isSelected: Bool
    let assetName: String

    private var iconColor: Color { isSelected ? .white : .white.opacity(0.33) }
    private let iconSize: CGFloat = 55

    var body: some View {
        Image(assetName)
            .resizable()
            .renderingMode(.template)
            .scaledToFit()
            .foregroundColor(iconColor)
            .frame(width: iconSize, height: iconSize)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
            .animation(.easeOut(duration: 0.16), value: isSelected)
    }
}

// MARK: - ✅ 新增：滚动栏下方四个矩形按钮（你自己导入 icon）
struct ControlBar: View {
    let icons: [String]
    @Binding var selectedIndex: Int

    private let height: CGFloat = 42
    private let corner: CGFloat = 14
    private let spacing: CGFloat = 12

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(icons.indices, id: \.self) { i in
                Button {
                    withAnimation(.easeOut(duration: 0.18)) {
                        selectedIndex = i
                    }
                    print("control \(i) tapped")
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: corner)
                            .fill(Color.white.opacity(selectedIndex == i ? 0.14 : 0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: corner)
                                    .stroke(Color.white.opacity(selectedIndex == i ? 0.24 : 0.12), lineWidth: 1)
                            )

                        Image(icons[i])
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .foregroundColor(selectedIndex == i ? .white : .white.opacity(0.60))
                            .frame(height: 18)
                    }
                    .frame(height: height)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

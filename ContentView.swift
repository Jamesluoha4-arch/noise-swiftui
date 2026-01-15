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

    // ✅ 你的硬摆放：保留 -320
    private let barBottomOffset: CGFloat = -320
    private let menuReserveWidth: CGFloat = 60

    // ✅ 用 padding 贴合（你要更贴就改小/改负）
    private let controlTopPadding: CGFloat = 8

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

                // ✅✅ 硬解底部组件：不要再对整体做 .padding(.bottom, -320)
                // 只对 ScrollBar 和 ControlBar 分别 offset，同一个偏移量，永远贴在一起
                VStack(spacing: 0) {

                    // ===== ScrollBar + Menu =====
                    ZStack(alignment: .trailing) {
                        IconScrollBar(icons: icons, selectedIndex: $selectedIndex)
                            .padding(.trailing, menuReserveWidth)

                        PlainIconButton(assetName: menuIconName, size: 18) {
                            print("menu tapped")
                        }
                        .padding(.trailing, 16)
                    }
                    .offset(y: barBottomOffset)   // ✅ 只把 scroll bar 硬摆到 -320

                    // ===== ControlBar（贴住 ScrollBar）=====
                    ControlBar(
                        icons: controlIcons,
                        selectedIndex: $selectedControlIndex
                    )
                    .padding(.horizontal, 18)
                    .padding(.top, controlTopPadding) // ✅ 用 padding 控制贴合距离
                    .offset(y: barBottomOffset)        // ✅ 同样 -320，保证永远跟着 scroll bar
                }
                .padding(.bottom, 16) // 给底部一点呼吸（可改 0）
            }
        }
        .contentShape(Rectangle())
        // ✅ 用 DragGesture(minimumDistance:0) 稳定获取点击坐标
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onEnded { value in
                    createClickParticle(at: value.location)
                }
        )
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

// MARK: - ✅ 滚动栏下方四个矩形按钮（你自己导入 icon）
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


import SwiftUI
struct IPhone16ProMax2: View {
	var body: some View {
		VStack(alignment: .leading){
			ScrollView(){
				VStack(alignment: .leading, spacing: 0) {
					VStack(alignment: .leading){
						HStack(spacing: 0){
							VStack(alignment: .leading){
								Text("logo")
									.foregroundColor(Color(hex: "#D9D9D9"))
									.font(.system(size: 8))
							}
							.padding(.vertical,10)
							.padding(.horizontal,7)
							.background(URLImageView(url: "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/PAN0XomBrb/k76s37wx_expires_30_days.png"))
							.padding(.trailing,20)
							Text("Brand Name")
								.foregroundColor(Color(hex: "#D9D9D9"))
								.font(.system(size: 19))
							VStack(alignment: .leading){
							}
							.frame(maxWidth: .infinity, alignment: .leading)
							URLImageView(url: "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/PAN0XomBrb/jlxhyzia_expires_30_days.png")
								.frame(width : 27, height: 27, alignment: .leading)
								.padding(.trailing,24)
							VStack(alignment: .leading){
								Text("AI助手")
									.foregroundColor(Color(hex: "#D9D9D9"))
									.font(.system(size: 8))
							}
							.padding(.vertical,10)
							.padding(.horizontal,4)
							.background(URLImageView(url: "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/PAN0XomBrb/5bp2o9zl_expires_30_days.png"))
						}
						.frame(height: 27)
						.frame(maxWidth: .infinity)
						.background(Color(hex: "#000000"))
						.padding(.bottom,21)
					}
					.padding(.top,59)
					.padding(.horizontal,24)
					.frame(maxWidth: .infinity, alignment: .leading)
					.background(Color(hex: "#000000"))
					.padding(.bottom,15)
					VStack(alignment: .leading){
						VStack(alignment: .leading){
							Text("分享并邀请")
								.foregroundColor(Color(hex: "#FFFFFF"))
								.font(.system(size: 19))
								.fontWeight(.bold)
								.padding(.bottom,14)
						}
						.padding(.top,191)
						.padding(.leading,24)
						.frame(maxWidth: .infinity, alignment: .leading)
						.background(LinearGradient(gradient: Gradient(colors: [Color(hex: "#FFFFFF66"), Color(hex: "#00000012")]), startPoint: .init(x: 0, y: 0), endPoint: .init(x: 0, y: 1)))
					}
					.padding(.bottom,13)
					.padding(.horizontal,25)
					.frame(maxWidth: .infinity, alignment: .leading)
					.overlay(
						VStack(alignment: .leading){
						}
						.frame(height: 27)
						.frame(maxWidth: .infinity, alignment: .leading)
						.background(Color(hex: "#000000"))
						.padding(.bottom, 0)
						.padding(.horizontal, 0), alignment: .bottomLeading
					)
					.padding(.bottom,36)
					.padding(.horizontal,9)
					HStack(spacing: 0){
						Text("场景")
							.foregroundColor(Color(hex: "#D9D9D9"))
							.font(.system(size: 25))
							.fontWeight(.bold)
						Spacer()
						Text("显示全部")
							.foregroundColor(Color(hex: "#D9D9D9"))
							.font(.system(size: 12))
					}
					.frame(maxWidth: .infinity)
					.padding(.bottom,26)
					.padding(.horizontal,31)
					HStack(spacing: 35){
						VStack(alignment: .leading, spacing: 34){
							VStack(alignment: .leading, spacing: 0){
								Text("专注")
									.foregroundColor(Color(hex: "#D9D9D9"))
									.font(.system(size: 15))
									.fontWeight(.bold)
									.padding(.leading,23)
								URLImageView(url: "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/PAN0XomBrb/07mwkwxg_expires_30_days.png")
									.cornerRadius(31)
									.frame(width : 166, height: 185, alignment: .leading)
							}
							.padding(.top,15)
							.padding(.bottom,3)
							.padding(.horizontal,2)
							.frame(maxWidth: .infinity, alignment: .leading)
							.background(LinearGradient(gradient: Gradient(colors: [Color(hex: "#FFFFFF12"), Color(hex: "#4B4B4B12")]), startPoint: .init(x: 0, y: 0), endPoint: .init(x: 0, y: 1)))
							VStack(alignment: .leading){
								URLImageView(url: "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/PAN0XomBrb/04pfgv76_expires_30_days.png")
									.cornerRadius(31)
									.frame(width : 146, height: 99, alignment: .leading)
							}
							.padding(.vertical,9)
							.padding(.leading,19)
							.frame(maxWidth: .infinity, alignment: .leading)
							.background(LinearGradient(gradient: Gradient(colors: [Color(hex: "#FFFFFF12"), Color(hex: "#4B4B4B12")]), startPoint: .init(x: 0, y: 0), endPoint: .init(x: 0, y: 1)))
							.overlay(
								Text("创造")
									.foregroundColor(Color(hex: "#D9D9D9"))
									.font(.system(size: 15))
									.fontWeight(.bold)
									.padding(.bottom, 8)
									.padding(.leading, 19)
								, alignment: .bottomLeading
							)
						}
						.frame(maxWidth: .infinity, alignment: .leading)
						VStack(alignment: .leading, spacing: 33){
							VStack(alignment: .leading, spacing: 0){
								VStack(alignment: .trailing){
									Text("休息")
										.foregroundColor(Color(hex: "#D9D9D9"))
										.font(.system(size: 15))
										.fontWeight(.bold)
										.padding(.trailing,26)
								}
								.frame(maxWidth: .infinity, alignment: .trailing)
								URLImageView(url: "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/PAN0XomBrb/eess6dzf_expires_30_days.png")
									.cornerRadius(31)
									.frame(width : 171, height: 87, alignment: .leading)
							}
							.padding(.top,15)
							.padding(.bottom,2)
							.frame(maxWidth: .infinity, alignment: .leading)
							.background(LinearGradient(gradient: Gradient(colors: [Color(hex: "#FFFFFF12"), Color(hex: "#4B4B4B12")]), startPoint: .init(x: 0, y: 0), endPoint: .init(x: 0, y: 1)))
							VStack(alignment: .leading, spacing: 6){
								URLImageView(url: "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/PAN0XomBrb/jxu2ogpb_expires_30_days.png")
									.cornerRadius(31)
									.frame(width : 139, height: 173, alignment: .leading)
									.padding(.leading,23)
								VStack(alignment: .trailing){
									Text("冥想")
										.foregroundColor(Color(hex: "#D9D9D9"))
										.font(.system(size: 15))
										.fontWeight(.bold)
										.padding(.trailing,26)
								}
								.frame(maxWidth: .infinity, alignment: .trailing)
							}
							.padding(.vertical,9)
							.frame(maxWidth: .infinity, alignment: .leading)
							.background(LinearGradient(gradient: Gradient(colors: [Color(hex: "#FFFFFF12"), Color(hex: "#4B4B4B12")]), startPoint: .init(x: 0, y: 0), endPoint: .init(x: 0, y: 1)))
						}
						.frame(maxWidth: .infinity, alignment: .leading)
					}
					.frame(maxWidth: .infinity)
					.padding(.bottom,16)
					.padding(.horizontal,34)
					VStack(alignment: .leading){
						VStack(alignment: .leading, spacing: 0){
							HStack(spacing: 0){
								VStack(alignment: .leading){
									URLImageView(url: "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/PAN0XomBrb/jqifzifd_expires_30_days.png")
										.cornerRadius(31)
										.frame(width : 69, height: 69, alignment: .leading)
								}
								.overlay(
									Text("声音")
										.foregroundColor(Color(hex: "#D9D9D9"))
										.font(.system(size: 25))
										.fontWeight(.bold)
										.padding(.bottom, 4)
										.padding(.leading, -15)
									, alignment: .bottomLeading
								)
								.padding(.leading,19)
								.padding(.trailing,6)
								VStack(alignment: .leading, spacing: 7){
									Text("正在播放")
										.foregroundColor(Color(hex: "#B6B6B6"))
										.font(.system(size: 10))
									Text("白噪音")
										.foregroundColor(Color(hex: "#FFFFFF"))
										.font(.system(size: 14))
								}
								Spacer()
							}
							.padding(.vertical,3)
							.frame(maxWidth: .infinity)
							.background(LinearGradient(gradient: Gradient(colors: [Color(hex: "#FFFFFF12"), Color(hex: "#4B4B4B12")]), startPoint: .init(x: 0, y: 0), endPoint: .init(x: 0, y: 1)))
							.padding(.bottom,27)
							.padding(.trailing,28)
							Text("晚上好")
								.foregroundColor(Color(hex: "#FFFFFF"))
								.font(.system(size: 15))
								.padding(.bottom,74)
								.padding(.leading,8)
							VStack(alignment: .trailing){
								VStack(alignment: .leading){
									VStack(alignment: .leading, spacing: 0){
										VStack(alignment: .leading){
											URLImageView(url: "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/PAN0XomBrb/kxfmlxf2_expires_30_days.png")
												.frame(width : 96, height: 28, alignment: .leading)
										}
										.padding(.top,3)
										.overlay(
											URLImageView(url: "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/PAN0XomBrb/jeww833e_expires_30_days.png")
												.frame(height: 28, alignment: .leading)
												.padding(.top, 0)
												.padding(.horizontal, 0)
											, alignment: .topLeading
										)
										.padding(.bottom,91)
										.padding(.leading,64)
										.padding(.trailing,154)
										VStack(alignment: .leading){
											Text("自然之声")
												.foregroundColor(Color(hex: "#D9D9D9"))
												.font(.system(size: 15))
												.fontWeight(.bold)
										}
										.padding(.vertical,22)
										.padding(.horizontal,19)
										.background(LinearGradient(gradient: Gradient(colors: [Color(hex: "#FFFFFF12"), Color(hex: "#4B4B4B12")]), startPoint: .init(x: 0, y: 0), endPoint: .init(x: 0, y: 1)))
										.padding(.bottom,184)
										.padding(.leading,38)
									}
									.padding(.top,127)
									.background(URLImageView(url: "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/PAN0XomBrb/t0krw9de_expires_30_days.png"))
								}
								.overlay(
									VStack(alignment: .leading){
										Text("白噪音")
											.foregroundColor(Color(hex: "#D9D9D9"))
											.font(.system(size: 15))
											.fontWeight(.bold)
									}
									.padding(.vertical,22)
									.padding(.horizontal,25)
									.background(LinearGradient(gradient: Gradient(colors: [Color(hex: "#FFFFFF12"), Color(hex: "#4B4B4B12")]), startPoint: .init(x: 0, y: 0), endPoint: .init(x: 0, y: 1)))
									.padding(.top, 196)
									.padding(.leading, -76), alignment: .topLeading
								)
								.overlay(
									VStack(alignment: .leading){
										Text("节奏")
											.foregroundColor(Color(hex: "#D9D9D9"))
											.font(.system(size: 15))
											.fontWeight(.bold)
									}
									.padding(.vertical,22)
									.padding(.horizontal,28)
									.background(LinearGradient(gradient: Gradient(colors: [Color(hex: "#FFFFFF12"), Color(hex: "#4B4B4B12")]), startPoint: .init(x: 0, y: 0), endPoint: .init(x: 0, y: 1)))
									.padding(.bottom, 127)
									.padding(.leading, -74), alignment: .bottomLeading
								)
							}
							.frame(maxWidth: .infinity, alignment: .trailing)
						}
						.frame(maxWidth: .infinity, alignment: .leading)
					}
					.frame(maxWidth: .infinity, alignment: .leading)
					.overlay(
						VStack(alignment: .leading){
							Text("用户昵称")
								.foregroundColor(Color(hex: "#FFFFFF"))
								.font(.system(size: 20))
								.fontWeight(.bold)
						}
						.padding(.vertical,15)
						.padding(.horizontal,29)
						.background(LinearGradient(gradient: Gradient(colors: [Color(hex: "#FFFFFF12"), Color(hex: "#4B4B4B12")]), startPoint: .init(x: 0, y: 0), endPoint: .init(x: 0, y: 1)))
						.padding(.top, 132)
						.padding(.leading, 7), alignment: .topLeading
					)
					.overlay(
						Text("现在是2026年1月14日夜间，一起开启好梦")
							.foregroundColor(Color(hex: "#FFFFFF"))
							.font(.system(size: 15))
							.padding(.top, 211)
							.padding(.leading, 11)
						, alignment: .topLeading
					)
					.overlay(
						URLImageView(url: "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/PAN0XomBrb/2r046d0l_expires_30_days.png")
							.frame(width : 238, height: 236, alignment: .leading)
							.padding(.top, 10)
							.padding(.trailing, 46)
						, alignment: .topTrailing
					)
					.padding(.leading,27)
				}
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
			.background(Color(hex: "#000000"))
		}
		.padding(.top,0.1)
		.padding(.bottom,0.1)
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
		.background(Color(hex: "#FFFFFF"))
	}
}

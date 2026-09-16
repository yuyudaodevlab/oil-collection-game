import SwiftUI

struct ContentView: View {
    @StateObject private var session = GameSession()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isLuminanceReduced) private var dimmed
    @State private var showSettings = false
    @State private var showKeepsakes = false
    @State private var crown = 0.0
    @State private var previousCrown = 0.0

    var body: some View {
        ZStack {
            background
            #if os(watchOS)
            watchLayout
            #else
            GeometryReader { geometry in
                if geometry.size.width > 740 && geometry.size.height > 420 {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 32) {
                            heading(alignment: .leading)
                            Text("お箸で、そっと。\n油がくっつく。\nこころがほどける。")
                                .font(.system(size: 19, weight: .regular, design: .serif)).lineSpacing(10).foregroundStyle(Color.quiet)
                            controls
                        }
                        .frame(width: min(300, geometry.size.width * 0.32))
                        VStack(spacing: 12) {
                            BowlView(session: session)
                            caption
                        }.frame(maxWidth: 850)
                    }
                    .padding(.horizontal, max(28, geometry.size.width * 0.045))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 0) {
                        topBar.padding(.horizontal, 24)
                        Spacer(minLength: 10)
                        heading(alignment: .center)
                        Spacer(minLength: 6)
                        BowlView(session: session)
                            .frame(maxWidth: 570)
                            .layoutPriority(-1)
                            .padding(.horizontal, 6)
                        caption.padding(.top, 10)
                        Spacer(minLength: 14)
                        controls.frame(maxWidth: 420).padding(.horizontal, 28)
                        Spacer(minLength: 18)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            #endif
        }
        .foregroundStyle(Color.paper)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSettings) { settings }
        .sheet(isPresented: $showKeepsakes) { keepsakes }
        .task(id: isRunning) {
            guard isRunning else { session.end(); return }
            // Only the active scene animates. Watch always-on and sheets suspend updates.
            let interval: UInt64 = reducedFrameRate ? 50_000_000 : 33_333_333
            while !Task.isCancelled {
                do { try await Task.sleep(nanoseconds: interval) } catch { break }
                guard !Task.isCancelled else { break }
                session.tick(Double(interval) / 1_000_000_000, reducedMotion: reduceMotion)
            }
        }
        .onChange(of: scenePhase) { _, phase in if phase != .active { session.end() } }
    }
    private var isRunning: Bool { scenePhase == .active && !dimmed && !showSettings && !showKeepsakes }
    private var reducedFrameRate: Bool {
        #if os(watchOS)
        return true
        #else
        return reduceMotion
        #endif
    }
    private var background: some View {
        ZStack {
            Color.garden
            RadialGradient(colors: [Color(hex: 0x365145).opacity(0.55), .clear], center: .init(x: 0.55, y: 0.4), startRadius: 10, endRadius: 560)
            Canvas { c, size in
                for i in 0..<180 {
                    let x = Double((i * 137) % 997) / 997 * size.width
                    let y = Double((i * 283) % 991) / 991 * size.height
                    c.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)), with: .color(Color.paper.opacity(0.08)))
                }
            }.accessibilityHidden(true)
        }.ignoresSafeArea()
    }
    private var topBar: some View {
        HStack {
            Text("RAMEN / SLOW TIME").font(.system(size: 9, weight: .medium, design: .monospaced)).tracking(2.3)
            Spacer()
            settingsButton
        }.foregroundStyle(Color.quiet).padding(.top, 8)
    }
    private func heading(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 12) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 1).fill(Color.gold).frame(width: 14, height: 1)
                Text("手のひらの、ひと休み").font(.system(size: 11)).tracking(3)
            }.foregroundStyle(Color.gold)
            HStack(alignment: .center, spacing: 14) {
                Text("油あつめ").font(.system(size: 43, weight: .regular, design: .serif)).tracking(7)
                Text("のんびり\n仕込み").font(.system(size: 9, weight: .medium, design: .serif)).lineSpacing(3)
                    .padding(7).foregroundStyle(Color(hex: 0xDEA38A))
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color(hex: 0xB87960), lineWidth: 1))
                    .rotationEffect(.degrees(6)).accessibilityHidden(true)
            }
            Text(session.broth.subtitle).font(.system(size: 13, design: .serif)).tracking(2).foregroundStyle(Color.quiet)
        }.fixedSize(horizontal: false, vertical: true)
    }
    private var caption: some View {
        VStack(spacing: 7) {
            Text(session.message).font(.system(size: 13, design: .serif)).foregroundStyle(Color.paper.opacity(0.86))
                .multilineTextAlignment(.center)
            #if os(macOS)
            Text("ドラッグで、ぷるん。スペースで、ひとよせ。").font(.system(size: 10)).foregroundStyle(Color.quiet)
            #else
            Text("なぞるだけ。時間も、ゴールも、ありません。").font(.system(size: 10)).foregroundStyle(Color.quiet)
            #endif
        }.padding(.horizontal, 12)
    }
    private var controls: some View {
        VStack(spacing: 19) {
            HStack(spacing: 5) {
                ForEach(Broth.allCases) { broth in
                    Button { session.broth = broth } label: {
                        HStack(spacing: 7) {
                            Circle().fill(broth.light).frame(width: 7, height: 7)
                            Text(broth.name).font(.system(size: 13, weight: session.broth == broth ? .semibold : .regular))
                        }
                        .frame(maxWidth: .infinity).frame(minHeight: 44)
                        .background(session.broth == broth ? Color.paper.opacity(0.12) : .clear, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(broth.name)スープ")
                    .accessibilityAddTraits(session.broth == broth ? [.isSelected] : [])
                }
            }.padding(5).background(Color.black.opacity(0.15), in: Capsule())
                .overlay(Capsule().stroke(Color.paper.opacity(0.09)))
            Button(action: session.gather) {
                HStack(spacing: 11) {
                    Image(systemName: "drop.circle")
                    Text("ひとよせ").tracking(4)
                    Image(systemName: "arrow.up.left").font(.system(size: 11))
                }.font(.system(size: 15, weight: .medium)).frame(maxWidth: .infinity).frame(height: 54)
                    .background(Color.paper, in: Capsule()).foregroundStyle(Color.garden)
            }.buttonStyle(.plain)
                #if os(macOS)
                .keyboardShortcut(.space, modifiers: [])
                #endif
                .accessibilityHint("一度押すと、油がゆっくり真ん中へ集まります")
            HStack {
                Button { showKeepsakes = true } label: {
                    Label("あつめた余韻", systemImage: "square.grid.2x2")
                        .font(.system(size: 11)).frame(minHeight: 44)
                }.buttonStyle(.plain)
                Spacer()
                settingsButton
            }.foregroundStyle(Color.quiet)
        }
    }
    private var settingsButton: some View {
        Button { showSettings = true } label: {
            Image(systemName: "slider.horizontal.3").font(.system(size: 17)).frame(width: 44, height: 44)
        }.buttonStyle(.plain).accessibilityLabel("遊び方と設定")
    }

    #if os(watchOS)
    private var watchLayout: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                HStack {
                    Text("油あつめ").font(.system(size: 15, design: .serif))
                    Spacer()
                    Button { showSettings = true } label: { Image(systemName: "ellipsis").frame(width: 38, height: 32) }
                        .buttonStyle(.plain).accessibilityLabel("遊び方と設定")
                }.padding(.horizontal, 12)
                BowlView(session: session).frame(maxHeight: .infinity)
                Button(action: session.gather) {
                    Label("ひとよせ", systemImage: "drop.circle").font(.system(size: 12)).frame(maxWidth: .infinity, minHeight: 35)
                }.buttonStyle(.plain).background(Color.paper.opacity(0.12), in: Capsule()).padding(.horizontal, 22)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .focusable()
        .digitalCrownRotation($crown, from: -1000, through: 1000, by: 0.08, sensitivity: .medium, isContinuous: true, isHapticFeedbackEnabled: false)
        .onChange(of: crown) { _, value in
            let delta = value - previousCrown
            previousCrown = value
            if abs(delta) < 10 { session.crown(delta) }
        }
    }
    #endif

    private var settings: some View {
        NavigationStack {
            Form {
                Section("気の向くままに") {
                    Text("油の上をゆっくりなぞると、お箸がついてきます。油どうしが出会うと、ぷるんとひとつに。")
                    Text("「ひとよせ」は、押すだけ。大きくなった油はスープにとけ、小さな油がまた浮かびます。")
                    #if os(watchOS)
                    Text("Digital Crownを回しても、お箸を動かせます。")
                    #elseif os(macOS)
                    Text("マウス・トラックパッドでドラッグ。スペースキーでも、ひとよせできます。")
                    #endif
                }
                Section("お好み") {
                    Picker("スープ", selection: $session.broth) { ForEach(Broth.allCases) { Text($0.name).tag($0) } }
                    Toggle("やさしい触覚", isOn: $session.haptics)
                    #if !os(watchOS)
                    Toggle("小さな水音", isOn: $session.sound)
                    #endif
                }
                Section {
                    Text("時間制限も、失敗も、広告もありません。続きはこの端末に自動で保存されます。")
                    #if os(watchOS)
                    NavigationLink("あつめた余韻") { keepsakeList }
                    #endif
                }
            }
            .formStyle(.grouped)
            .navigationTitle("ひと休みの支度")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("できあがり") { showSettings = false } } }
        }
        #if os(macOS)
        .frame(width: 460, height: 570)
        #endif
    }
    private var keepsakes: some View {
        NavigationStack {
            keepsakeList.navigationTitle("あつめた余韻")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("閉じる") { showKeepsakes = false } } }
        }
        #if os(macOS)
        .frame(width: 440, height: 540)
        #endif
    }
    private var keepsakeList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("なんでもない時間の、小さな思い出。\n遊んでいるうちに、そっと増えていきます。")
                    .font(.system(size: 13, design: .serif)).foregroundStyle(Color.quiet).lineSpacing(5)
                ForEach(Keepsake.all) { item in
                    let unlocked = session.merges >= item.needed
                    HStack(spacing: 17) {
                        Image(systemName: unlocked ? item.symbol : "circle.dotted")
                            .font(.system(size: 28, weight: .light)).foregroundStyle(unlocked ? Color.gold : Color.quiet.opacity(0.4)).frame(width: 43)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(unlocked ? item.name : "まだ、これから").font(.system(size: 16, design: .serif))
                            Text(unlocked ? item.note : "いつか、ふとしたときに。")
                                .font(.system(size: 11)).foregroundStyle(Color.quiet)
                        }
                    }.padding(17).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.paper.opacity(0.06), in: RoundedRectangle(cornerRadius: 18))
                }
                if session.blooms > 0 {
                    Text("まあるくとけた油、\(session.blooms) つ。")
                        .font(.system(size: 12, design: .serif)).foregroundStyle(Color.quiet)
                }
            }.padding(22)
        }.background(Color.garden).foregroundStyle(Color.paper)
    }
}

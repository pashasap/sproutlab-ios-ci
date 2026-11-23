import SwiftUI
import Core

/// Thin renderer of `TerrariumViewModel`: layers shift by offset x parallax; every value comes from Core.
struct TerrariumView: View {
    let model: TerrariumViewModel
    var onBack: () -> Void = {}
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    @State private var phase = DayPhase.current(clock: SystemClock(), calendar: .current)
    @State private var visible = true
    @State private var start = Date()
    @State private var showJournal = false

    private var flags: FrameFlags {
        FrameFlags(reduceMotion: reduceMotion, lowPower: ProcessInfo.processInfo.isLowPowerModeEnabled)
    }

    private var scheme: ColourScheme { colorScheme == .dark ? .dark : .light }

    private func frame(at date: Date) -> TerrariumFrame {
        TerrariumFrame.make(model, phase: phase, time: date.timeIntervalSince(start), flags: flags)
    }

    var body: some View {
        Group {
            if showJournal {
                JournalView(model: model) { showJournal = false }
            } else if reduceMotion {
                garden(frame(at: start))
            } else {
                let interval = FramePolicy.frameInterval(lowPower: flags.lowPower)
                TimelineView(.animation(minimumInterval: interval,
                                        paused: FramePolicy.timelinePaused(visible: visible && scenePhase == .active))) { context in
                    garden(frame(at: context.date))
                }
            }
        }
        .onAppear { visible = true; model.reduceMotion = reduceMotion; if phase == .night { model.viewGardenAtNight() } }
        .onChange(of: phase) { _, now in if now == .night { model.viewGardenAtNight() } }
        .onDisappear { visible = false }
    }

    private func garden(_ frame: TerrariumFrame) -> some View {
        GeometryReader { proxy in
            gardenStack(frame, proxy)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
                .clipped()
        }
        .gesture(DragGesture(minimumDistance: 40).onEnded { drag in
            if drag.translation.width < 0 { model.panRight() } else { model.panLeft() }
        })
        .accessibilityIdentifier(model.accessibilityId)
    }

    @ViewBuilder
    private func layerView(_ layer: GardenLayer, _ frame: TerrariumFrame, size: CGSize) -> some View {
        if layer.id == "stage" {
            let screen = ScreenMetrics(width: Double(size.width), height: Double(size.height),
                                       insets: SafeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            let ids = model.habitats.flatMap(\.residentIds)
            ZStack(alignment: .topLeading) {
                ForEach(Array(ids.enumerated()), id: \.element) { index, id in
                    if let resident = model.resident(id) {
                        let slot = LayoutPolicy.terrariumResidentPosition(index: index, total: ids.count, screen: screen)
                        ResidentView(model: model, resident: resident,
                                     centre: CGPoint(x: slot.x + slot.width / 2, y: slot.y + slot.height / 2),
                                     pose: frame.poses[id] ?? PoseScheduler.stillPose(id),
                                     animates: !reduceMotion && !ProcessInfo.processInfo.arguments.contains("-auditStop"))
                    }
                }
            }
            .frame(width: size.width, height: size.height, alignment: .topLeading)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(model.habitats.first?.accessibilityId ?? "")
        } else {
            Color.clear.frame(width: size.width, height: size.height)
        }
    }

    /// Green hills, meadow grass and soil bands from Palette tokens.
    private func backdrop(_ size: CGSize) -> some View {
        VStack(spacing: 0) {
            Palette.token("colour.green").opacity(0.35).frame(height: size.height * 0.30)
            Palette.accent.opacity(0.45).frame(height: size.height * 0.40)
            Palette.token("colour.review").opacity(0.30).frame(height: size.height * 0.18)
            Palette.locked.opacity(0.35).frame(height: size.height * 0.12)
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
    }

    private func centre(_ rect: LayoutRect) -> CGPoint {
        CGPoint(x: rect.x + rect.width / 2, y: rect.y + rect.height / 2)
    }

    private func gardenStack(_ frame: TerrariumFrame, _ proxy: GeometryProxy) -> some View {
        ZStack(alignment: .topLeading) {
            TerrariumSkyView(frame: frame, scheme: scheme)
            backdrop(proxy.size)
            ForEach(model.scene.layers, id: \.id) { layer in
                layerView(layer, frame, size: proxy.size)
                    .offset(x: -model.panOffset * layer.parallax)
            }
            controls(frame, proxy)
        }
    }

    /// Controls are placed inside the viewport (the view's own width), never from the 1000 pt canvas.
    private func controls(_ frame: TerrariumFrame, _ proxy: GeometryProxy) -> some View {
        let screen = ScreenMetrics(width: Double(proxy.size.width), height: Double(proxy.size.height),
                                   insets: SafeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        let frames = LayoutPolicy.terrariumControls(screen, sceneWidth: model.scene.width)
        return ZStack(alignment: .topLeading) {
            controlButton(model.closeControl, action: onBack)
                .position(centre(frames.close))
            controlButton(model.journalControl) { showJournal = true }
                .position(centre(frames.journal))
            controlButton(model.panLeftControl) { model.panLeft() }
                .position(centre(frames.panLeft))
            controlButton(model.panRightControl) { model.panRight() }
                .position(centre(frames.panRight))
            TerrariumDialView(frame: frame, scheme: scheme, language: model.language) { phase = $0 }
                .position(centre(frames.dial))
        }
    }

    private func controlButton(_ control: TerrariumControl, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: TextTable.string(control.iconKey, .en)).font(.title)
                .scaleEffect(x: control.mirrorsIcon ? -1 : 1, y: 1)
                .foregroundStyle(Palette.ink)
        }
        .frame(width: control.width, height: control.height)
        .background(Circle().fill(Palette.card.opacity(0.9)))
        .accessibilityLabel(control.label(model.language))
        .accessibilityIdentifier(control.accessibilityId)
    }
}

private struct ResidentView: View {
    let model: TerrariumViewModel
    let resident: TerrariumResident
    let centre: CGPoint
    let pose: Pose
    let animates: Bool
    @State private var tilt = false

    var body: some View {
        let area = resident.tapArea
        VStack(spacing: 4) {
            if let bubble = resident.bubble { bubbleView(bubble) }
            Button { model.tap(resident.id) } label: {
                creature
                    .saturation(resident.isSilhouette ? 0 : 1)
                    .rotationEffect(.degrees(angle + pose.rotation))
                    .scaleEffect(pose.scale)
                    .offset(x: pose.offset.x, y: pose.offset.y)
            }
            .accessibilityLabel(resident.accessibilityLabel)
            if let welcome = resident.welcome {
                Button { acknowledge(model.welcome(resident.id)) } label: {
                    Image(systemName: TextTable.string(welcome.iconKey, .en))
                }
                .frame(width: welcome.width, height: welcome.height)
                .accessibilityLabel(welcome.label(model.language))
            }
        }
        .frame(width: area.width, height: area.height)
        .position(centre)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(resident.accessibilityId)
        .onAppear { if animates, !model.reduceMotion, resident.wobble == .animated { withAnimation(.easeInOut(duration: wobbleSeconds).repeatForever()) { tilt = true } } }
    }

    /// Creature colours come from the light tokens in both appearances.
    @ViewBuilder
    private var creature: some View {
        if let recipe = Recipe.table.first(where: { $0.id == resident.id }) {
            RecipeRenderer(recipe: recipe, scheme: .light)
                .frame(width: resident.tapArea.width, height: resident.tapArea.height)
        } else {
            Color.clear.frame(width: resident.tapArea.width, height: resident.tapArea.height)
        }
    }

    /// The tilt follows the resident's first idle behaviour from the Core table.
    private var wobbleSeconds: Double {
        BehaviourTable.entry(for: resident.id)?.idle.first?.cycleSeconds ?? 0.6
    }

    private var angle: Double {
        switch resident.wobble {
        case .none: return 0
        case .staticTilt: return 6
        case .animated: return tilt ? 6 : -6
        }
    }

    private func bubbleView(_ bubble: NameBubble) -> some View {
        HStack {
            Text(bubble.text)
            Button { model.speakName(resident.id) } label: {
                Image(systemName: TextTable.string(bubble.ear.iconKey, .en))
            }
            .frame(width: bubble.ear.width, height: bubble.ear.height)
            .accessibilityLabel(bubble.ear.label(model.language))
        }
    }

    private func acknowledge(_ welcomed: Bool) {
        guard welcomed, let text = model.acknowledgement(of: resident.id) else { return }
        AccessibilityNotification.Announcement(text).post()
    }
}

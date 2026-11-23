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
        let scene = model.scene
        return ZStack(alignment: .topLeading) {
            TerrariumSkyView(frame: frame, scheme: scheme)
            ForEach(scene.layers, id: \.id) { layer in
                layerView(layer, frame)
                    .offset(x: -model.panOffset * layer.parallax)
            }
            controls
            TerrariumDialView(frame: frame, scheme: scheme, language: model.language) { phase = $0 }
                .position(x: scene.screenWidth / 2, y: model.backPosition.y)
        }
        .frame(width: scene.screenWidth, height: scene.height)
        .clipped()
        .gesture(DragGesture(minimumDistance: 40).onEnded { drag in
            if drag.translation.width < 0 { model.panRight() } else { model.panLeft() }
        })
        .accessibilityIdentifier(model.accessibilityId)
    }

    @ViewBuilder
    private func layerView(_ layer: GardenLayer, _ frame: TerrariumFrame) -> some View {
        if layer.id == "stage" {
            ZStack(alignment: .topLeading) {
                ForEach(model.habitats, id: \.id) { habitat in
                    ForEach(habitat.residentIds, id: \.self) { id in
                        if let resident = model.resident(id) {
                            ResidentView(model: model, resident: resident,
                                         pose: frame.poses[id] ?? PoseScheduler.stillPose(id))
                        }
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(model.habitats.first?.accessibilityId ?? "")
        } else {
            Color.clear.frame(width: model.scene.width, height: model.scene.height)
        }
    }

    private func centre(_ rect: LayoutRect) -> CGPoint {
        CGPoint(x: rect.x + rect.width / 2, y: rect.y + rect.height / 2)
    }

    /// Controls are placed inside the viewport (the view's own width), never from the 1000 pt canvas.
    private var controls: some View {
        GeometryReader { proxy in
            let screen = ScreenMetrics(width: Double(proxy.size.width), height: Double(proxy.size.height),
                                       insets: SafeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            let frames = LayoutPolicy.terrariumControls(screen, sceneWidth: model.scene.width)
            ZStack(alignment: .topLeading) {
                controlButton(model.closeControl, action: onBack)
                    .position(centre(frames.close))
                controlButton(model.journalControl) { showJournal = true }
                    .position(x: proxy.size.width - 16 - model.journalControl.width / 2, y: centre(frames.close).y)
                controlButton(model.panLeftControl) { model.panLeft() }
                    .position(centre(frames.panLeft))
                controlButton(model.panRightControl) { model.panRight() }
                    .position(centre(frames.panRight))
            }
        }
    }

    private func controlButton(_ control: TerrariumControl, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: TextTable.string(control.iconKey, .en)).font(.title)
                .scaleEffect(x: control.mirrorsIcon ? -1 : 1, y: 1)
        }
        .frame(width: control.width, height: control.height)
        .accessibilityLabel(control.label(model.language))
        .accessibilityIdentifier(control.accessibilityId)
    }
}

private struct ResidentView: View {
    let model: TerrariumViewModel
    let resident: TerrariumResident
    let pose: Pose
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
            if let welcome = resident.welcome {
                Button { acknowledge(model.welcome(resident.id)) } label: {
                    Image(systemName: TextTable.string(welcome.iconKey, .en))
                }
                .frame(width: welcome.width, height: welcome.height)
                .accessibilityLabel(welcome.label(model.language))
            }
        }
        .frame(width: area.width, height: area.height)
        .position(x: resident.position.x, y: resident.position.y)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(resident.accessibilityLabel)
        .accessibilityIdentifier(resident.accessibilityId)
        .onAppear { if resident.wobble == .animated { withAnimation(.easeInOut(duration: wobbleSeconds).repeatForever()) { tilt = true } } }
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

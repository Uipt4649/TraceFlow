//
//  ContentView.swift
//  TraceFlow
//
//  Created by 渡邉羽唯 on 2026/04/28.
//

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var viewModel = TraceTimelineViewModel()
    @StateObject private var bubbleField = TraceBubbleFieldEngine()
    @State private var draftText = ""
    @State private var isComposerPresented = false

    var body: some View {
        NavigationStack {
            ZStack {
                TraceBackgroundView()

                GeometryReader { proxy in
                    ZStack {
                        ForEach(viewModel.posts) { post in
                            let state = bubbleField.state(for: post)
                            TraceBubbleView(post: post, diameter: state.diameter)
                                .position(state.position)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .onAppear {
                        bubbleField.configure(posts: viewModel.posts, in: proxy.size)
                    }
                    .onChange(of: proxy.size) { newSize in
                        bubbleField.updateBounds(newSize)
                    }
                    .onChange(of: viewModel.posts) { posts in
                        bubbleField.configure(posts: posts, in: proxy.size)
                    }
                }
            }
            .navigationTitle("TraceFlow")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("anon: \(viewModel.anonymousUserID)")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isComposerPresented = true
                    } label: {
                        Label("投稿", systemImage: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $isComposerPresented) {
                composerSheet
            }
        }
    }

    private var composerSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("だれにも紐づかない、言葉の痕跡だけを残します。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                TextEditor(text: $draftText)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .frame(minHeight: 200)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))

                HStack {
                    Label(
                        TraceTextureClassifier.classify(from: draftText).title,
                        systemImage: TraceTextureClassifier.classify(from: draftText).symbol
                    )
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())

                    Spacer()

                    Text("\(draftText.count) / 140")
                        .font(.caption)
                        .foregroundStyle(draftText.count > 140 ? .red : .secondary)
                }

                Spacer()
            }
            .padding(16)
            .navigationTitle("新規投稿")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        isComposerPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("流す") {
                        viewModel.addPost(text: draftText)
                        draftText = ""
                        isComposerPresented = false
                    }
                    .disabled(!canSubmit)
                }
            }
        }
    }

    private var canSubmit: Bool {
        let trimmed = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= 140
    }
}

private struct TraceBackgroundView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.01, green: 0.01, blue: 0.04),
                    Color(red: 0.03, green: 0.04, blue: 0.09),
                    Color(red: 0.02, green: 0.07, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            GeometryReader { proxy in
                let size = proxy.size
                ForEach(0..<120, id: \.self) { index in
                    let radius = CGFloat((index % 3) + 1)
                    Circle()
                        .fill(index.isMultiple(of: 5) ? Color.cyan.opacity(0.14) : Color.white.opacity(0.18))
                        .frame(width: radius * 2, height: radius * 2)
                        .position(
                            x: CGFloat((index * 73) % 1000) / 1000 * max(size.width, 1),
                            y: CGFloat((index * 151 + 37) % 1000) / 1000 * max(size.height, 1)
                        )
                }
            }

            Rectangle()
                .fill(
                    RadialGradient(
                        colors: [.clear, Color.black.opacity(0.45)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 520
                    )
                )
        }
        .ignoresSafeArea()
    }
}

private struct TraceBubbleView: View {
    let post: TracePost
    let diameter: CGFloat

    var body: some View {
        VStack(spacing: 10) {
            Text(post.text)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.88))
                .lineLimit(4)
                .padding(.horizontal, 18)
                .padding(.top, 18)

            Label(post.texture.title, systemImage: post.texture.symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.72))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.06), in: Capsule())

            Text(post.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.56))
                .padding(.bottom, 14)
        }
        .frame(width: diameter, height: diameter)
        .background(
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.24),
                            post.texture.baseColor.opacity(0.09),
                            Color.black.opacity(0.24)
                        ],
                        center: UnitPoint(x: 0.35, y: 0.3),
                        startRadius: 6,
                        endRadius: diameter * 0.62
                    )
                )
        )
        .background(.ultraThinMaterial.opacity(0.18), in: Circle())
        .overlay {
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.55), Color.white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        }
        .overlay {
            Circle()
                .trim(from: 0.06, to: 0.3)
                .stroke(Color.white.opacity(0.4), lineWidth: 2)
                .rotationEffect(.degrees(-24))
                .padding(10)
        }
        .overlay(alignment: .topLeading) {
            Circle()
                .fill(Color.white.opacity(0.45))
                .frame(width: diameter * 0.16, height: diameter * 0.16)
                .blur(radius: 1.4)
                .offset(x: diameter * 0.22, y: diameter * 0.22)
        }
        .shadow(color: post.texture.baseColor.opacity(0.26), radius: 24, y: 6)
    }
}

private struct TracePost: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    let createdAt: Date
    let texture: TraceTexture

    var bubbleDiameter: CGFloat {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let length = CGFloat(trimmed.count)
        let lineCount = CGFloat(max(trimmed.split(separator: "\n").count, 1))
        let punctuationCount = CGFloat(trimmed.filter { "!?！？。、,.…".contains($0) }.count)

        // 長さは平方根で伸びを抑え、改行と記号で質感の差を出す。
        let lengthBoost = min(sqrt(length) * 7.4, 74)
        let lineBoost = min((lineCount - 1) * 14, 40)
        let punctuationBoost = min(punctuationCount * 2.8, 18)

        let raw = 122 + lengthBoost + lineBoost + punctuationBoost
        let clamped = min(max(raw * texture.diameterScale, 130), 275)
        return clamped
    }
}

private enum TraceTexture: String, Codable, CaseIterable {
    case lightParticle
    case heavyLiquid
    case ripple
    case burst
    case clearGlass

    var title: String {
        switch self {
        case .lightParticle: "軽い粒"
        case .heavyLiquid: "重めの液体"
        case .ripple: "ゆらぐ波紋"
        case .burst: "はじける粒子"
        case .clearGlass: "透明ガラス"
        }
    }

    var symbol: String {
        switch self {
        case .lightParticle: "sparkles"
        case .heavyLiquid: "drop.fill"
        case .ripple: "water.waves"
        case .burst: "burst"
        case .clearGlass: "square.transparent"
        }
    }

    var baseColor: Color {
        switch self {
        case .lightParticle: .mint
        case .heavyLiquid: .blue
        case .ripple: .teal
        case .burst: .orange
        case .clearGlass: .white
        }
    }

    var motionScale: CGFloat {
        switch self {
        case .lightParticle: 1.18
        case .heavyLiquid: 0.74
        case .ripple: 1.03
        case .burst: 1.42
        case .clearGlass: 0.9
        }
    }

    var diameterScale: CGFloat {
        switch self {
        case .lightParticle: 0.88
        case .heavyLiquid: 1.24
        case .ripple: 1.08
        case .burst: 1.16
        case .clearGlass: 0.96
        }
    }
}

private enum TraceTextureClassifier {
    static func classify(from text: String) -> TraceTexture {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return .clearGlass }
        if trimmed.contains("！") || trimmed.contains("!") {
            return .burst
        }
        if trimmed.contains("？") || trimmed.contains("?") {
            return .ripple
        }
        if trimmed.split(separator: "\n").count >= 3 {
            return .heavyLiquid
        }
        if trimmed.count <= 18 {
            return .lightParticle
        }
        if trimmed.count >= 70 {
            return .heavyLiquid
        }
        return .clearGlass
    }
}

private struct TraceLocalStore {
    private let anonymousIDKey = "traceflow.anonymousID"
    private let postsKey = "traceflow.localPosts"

    func loadAnonymousID() -> String {
        if let existing = UserDefaults.standard.string(forKey: anonymousIDKey) {
            return existing
        }

        let created = String(UUID().uuidString.prefix(8)).lowercased()
        UserDefaults.standard.set(created, forKey: anonymousIDKey)
        return created
    }

    func loadPosts() -> [TracePost] {
        guard
            let data = UserDefaults.standard.data(forKey: postsKey),
            let decoded = try? JSONDecoder().decode([TracePost].self, from: data)
        else {
            return Self.seedPosts
        }
        return decoded.sorted(by: { $0.createdAt > $1.createdAt })
    }

    func savePosts(_ posts: [TracePost]) {
        guard let data = try? JSONEncoder().encode(posts) else { return }
        UserDefaults.standard.set(data, forKey: postsKey)
    }

    private static let seedPosts: [TracePost] = [
        TracePost(
            id: UUID(),
            text: "今日の空気は、少しだけ軽い。",
            createdAt: .now.addingTimeInterval(-3600),
            texture: .lightParticle
        ),
        TracePost(
            id: UUID(),
            text: "この沈黙は安心なのか、逃げなのか。",
            createdAt: .now.addingTimeInterval(-1800),
            texture: .ripple
        ),
        TracePost(
            id: UUID(),
            text: "言葉にならない重さだけが残っている。",
            createdAt: .now.addingTimeInterval(-900),
            texture: .heavyLiquid
        )
    ]
}

private struct BubblePhysicsState {
    var position: CGPoint
    var velocity: CGVector
    var radius: CGFloat
    var motionScale: CGFloat
}

@MainActor
private final class TraceBubbleFieldEngine: ObservableObject {
    @Published private var states: [UUID: BubblePhysicsState] = [:]

    private var bounds: CGSize = .zero
    private var textures: [UUID: TraceTexture] = [:]
    private var timer: AnyCancellable?
    private var lastTick = Date()

    init() {
        timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] now in
                self?.tick(now: now)
            }
    }

    func configure(posts: [TracePost], in size: CGSize) {
        bounds = size
        textures = Dictionary(uniqueKeysWithValues: posts.map { ($0.id, $0.texture) })
        var next = states

        for post in posts where next[post.id] == nil {
            next[post.id] = seedState(for: post)
        }

        let validIDs = Set(posts.map(\.id))
        next = next.filter { validIDs.contains($0.key) }

        for (id, var state) in next {
            state.radius = radius(for: id)
            state.motionScale = textures[id]?.motionScale ?? 1
            state.position.x = min(max(state.position.x, state.radius), max(bounds.width - state.radius, state.radius))
            state.position.y = min(max(state.position.y, state.radius), max(bounds.height - state.radius, state.radius))
            next[id] = state
        }

        states = next
    }

    func updateBounds(_ size: CGSize) {
        bounds = size
    }

    func state(for post: TracePost) -> (position: CGPoint, diameter: CGFloat) {
        guard let state = states[post.id] else {
            let fallback = CGPoint(x: bounds.width * 0.5, y: bounds.height * 0.5)
            return (fallback, post.bubbleDiameter)
        }
        return (state.position, state.radius * 2)
    }

    private func tick(now: Date) {
        guard bounds.width > 40, bounds.height > 40, !states.isEmpty else {
            lastTick = now
            return
        }

        let dt = min(max(now.timeIntervalSince(lastTick), 0.01), 0.05)
        lastTick = now

        var next = states

        for (id, var bubble) in next {
            let impulseX = CGFloat.random(in: -7...7) * bubble.motionScale
            let impulseY = CGFloat.random(in: -7...7) * bubble.motionScale
            bubble.velocity.dx += impulseX * dt
            bubble.velocity.dy += impulseY * dt

            let maxSpeed = 38 * bubble.motionScale
            let speed = hypot(bubble.velocity.dx, bubble.velocity.dy)
            if speed > maxSpeed {
                let scale = maxSpeed / speed
                bubble.velocity.dx *= scale
                bubble.velocity.dy *= scale
            }

            bubble.velocity.dx *= 0.99
            bubble.velocity.dy *= 0.99

            bubble.position.x += bubble.velocity.dx
            bubble.position.y += bubble.velocity.dy

            if bubble.position.x - bubble.radius < 0 {
                bubble.position.x = bubble.radius
                bubble.velocity.dx = abs(bubble.velocity.dx) * 0.82
            } else if bubble.position.x + bubble.radius > bounds.width {
                bubble.position.x = bounds.width - bubble.radius
                bubble.velocity.dx = -abs(bubble.velocity.dx) * 0.82
            }

            if bubble.position.y - bubble.radius < 0 {
                bubble.position.y = bubble.radius
                bubble.velocity.dy = abs(bubble.velocity.dy) * 0.82
            } else if bubble.position.y + bubble.radius > bounds.height {
                bubble.position.y = bounds.height - bubble.radius
                bubble.velocity.dy = -abs(bubble.velocity.dy) * 0.82
            }

            next[id] = bubble
        }

        let ids = Array(next.keys)
        if ids.count > 1 {
            for index in 0..<(ids.count - 1) {
                for other in (index + 1)..<ids.count {
                    let idA = ids[index]
                    let idB = ids[other]
                    guard var a = next[idA], var b = next[idB] else { continue }

                    let dx = b.position.x - a.position.x
                    let dy = b.position.y - a.position.y
                    var distance = hypot(dx, dy)
                    let minDistance = a.radius + b.radius
                    if distance >= minDistance { continue }

                    if distance < 0.001 {
                        distance = 0.001
                    }

                    let nx = dx / distance
                    let ny = dy / distance
                    let overlap = minDistance - distance

                    a.position.x -= nx * overlap * 0.5
                    a.position.y -= ny * overlap * 0.5
                    b.position.x += nx * overlap * 0.5
                    b.position.y += ny * overlap * 0.5

                    let relativeVelocityX = b.velocity.dx - a.velocity.dx
                    let relativeVelocityY = b.velocity.dy - a.velocity.dy
                    let velocityAlongNormal = relativeVelocityX * nx + relativeVelocityY * ny

                    if velocityAlongNormal < 0 {
                        let restitution: CGFloat = 0.86
                        let impulse = -(1 + restitution) * velocityAlongNormal / 2
                        a.velocity.dx -= impulse * nx
                        a.velocity.dy -= impulse * ny
                        b.velocity.dx += impulse * nx
                        b.velocity.dy += impulse * ny
                    }

                    next[idA] = a
                    next[idB] = b
                }
            }
        }

        states = next
    }

    private func seedState(for post: TracePost) -> BubblePhysicsState {
        let seeded = abs(post.id.uuidString.hashValue)
        let radius = post.bubbleDiameter * 0.5
        let width = max(bounds.width, radius * 2 + 1)
        let height = max(bounds.height, radius * 2 + 1)

        let x = CGFloat(seeded % 1000) / 1000 * (width - radius * 2) + radius
        let y = CGFloat((seeded / 1000) % 1000) / 1000 * (height - radius * 2) + radius
        let angle = CGFloat((seeded / 1_000_000) % 360) * (.pi / 180)
        let baseSpeed = CGFloat(12 + (seeded % 20))
        let speed = baseSpeed * post.texture.motionScale

        return BubblePhysicsState(
            position: CGPoint(x: x, y: y),
            velocity: CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed),
            radius: radius,
            motionScale: post.texture.motionScale
        )
    }

    private func radius(for id: UUID) -> CGFloat {
        states[id]?.radius ?? 88
    }
}

@MainActor
private final class TraceTimelineViewModel: ObservableObject {
    @Published private(set) var posts: [TracePost] = []
    @Published private(set) var anonymousUserID: String = ""

    private let store = TraceLocalStore()

    init() {
        anonymousUserID = store.loadAnonymousID()
        posts = store.loadPosts()
    }

    func addPost(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 140 else { return }

        let newPost = TracePost(
            id: UUID(),
            text: trimmed,
            createdAt: .now,
            texture: TraceTextureClassifier.classify(from: trimmed)
        )
        posts.insert(newPost, at: 0)
        store.savePosts(posts)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

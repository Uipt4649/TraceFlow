import SwiftUI
import MetalKit

struct TraceMetalBackgroundView: UIViewRepresentable {
    func makeCoordinator() -> TraceMetalRenderer {
        TraceMetalRenderer()
    }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero)
        view.device = MTLCreateSystemDefaultDevice()
        view.isPaused = false
        view.enableSetNeedsDisplay = false
        view.preferredFramesPerSecond = 60
        view.framebufferOnly = true
        view.clearColor = MTLClearColor(red: 0.01, green: 0.01, blue: 0.04, alpha: 1.0)
        context.coordinator.attach(to: view)
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
    }
}

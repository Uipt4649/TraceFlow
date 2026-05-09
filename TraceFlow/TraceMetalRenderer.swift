import Foundation
import MetalKit
import simd

private struct MetalStarVertex {
    var position: SIMD2<Float>
    var pointSize: Float
    var color: SIMD4<Float>
}

private struct MetalViewportUniforms {
    var viewportSize: SIMD2<Float>
}

final class TraceMetalRenderer: NSObject, MTKViewDelegate {
    private var deviceRef: MTLDevice?
    private var queue: MTLCommandQueue?
    private var pipeline: MTLRenderPipelineState?
    private var starBuffer: MTLBuffer?

    private var stars: [MetalStarVertex] = []
    private var starVelocity: [SIMD2<Float>] = []

    func attach(to view: MTKView) {
        guard let device = view.device else { return }
        deviceRef = device
        queue = device.makeCommandQueue()

        let library = device.makeDefaultLibrary()
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library?.makeFunction(name: "trace_star_vertex")
        descriptor.fragmentFunction = library?.makeFunction(name: "trace_star_fragment")
        descriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat

        do {
            pipeline = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            print("Metal pipeline creation failed: \(error)")
        }

        createStars(count: 140)
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }

    func draw(in view: MTKView) {
        guard
            let pipeline,
            let queue,
            let pass = view.currentRenderPassDescriptor,
            let buffer = queue.makeCommandBuffer(),
            let encoder = buffer.makeRenderCommandEncoder(descriptor: pass),
            let drawable = view.currentDrawable
        else { return }

        advanceStars(in: view.drawableSize)

        var viewport = MetalViewportUniforms(
            viewportSize: SIMD2(Float(view.drawableSize.width), Float(view.drawableSize.height))
        )

        encoder.setRenderPipelineState(pipeline)
        if let starBuffer {
            encoder.setVertexBuffer(starBuffer, offset: 0, index: 0)
        }
        encoder.setVertexBytes(&viewport, length: MemoryLayout<MetalViewportUniforms>.stride, index: 1)
        encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: stars.count)
        encoder.endEncoding()

        buffer.present(drawable)
        buffer.commit()
    }

    private func createStars(count: Int) {
        stars.removeAll(keepingCapacity: true)
        starVelocity.removeAll(keepingCapacity: true)

        for index in 0..<count {
            let x = Float((index * 73) % 1000) / 1000
            let y = Float((index * 151 + 37) % 1000) / 1000
            let size = Float((index % 3) + 1) * 1.3
            let color: SIMD4<Float> = index.isMultiple(of: 5)
                ? SIMD4(0.45, 0.95, 1.0, 0.78)
                : SIMD4(1.0, 1.0, 1.0, 0.82)

            stars.append(
                MetalStarVertex(position: SIMD2(x, y), pointSize: size, color: color)
            )

            let velocity = SIMD2<Float>(
                Float((index % 7) - 3) * 0.00006,
                Float((index % 9) - 4) * 0.00005
            )
            starVelocity.append(velocity)
        }
        rebuildStarBuffer()
    }

    private func advanceStars(in size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }

        for index in stars.indices {
            stars[index].position += starVelocity[index]

            if stars[index].position.x < 0 {
                stars[index].position.x = 1
            } else if stars[index].position.x > 1 {
                stars[index].position.x = 0
            }

            if stars[index].position.y < 0 {
                stars[index].position.y = 1
            } else if stars[index].position.y > 1 {
                stars[index].position.y = 0
            }
        }
        rebuildStarBuffer()
    }

    private func rebuildStarBuffer() {
        guard let deviceRef else { return }
        let length = MemoryLayout<MetalStarVertex>.stride * stars.count
        guard length > 0 else {
            starBuffer = nil
            return
        }
        starBuffer = deviceRef.makeBuffer(bytes: stars, length: length, options: .storageModeShared)
    }
}

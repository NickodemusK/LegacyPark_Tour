import SwiftUI
import RealityKit
import ARKit

struct ContentView: View {
    let modelNames       = ["Obama", "Rosa_Parks", "11_7_2024"]
    let modelFullNames   = ["President Obama", "Rosa Parks", "Frederick Douglass"]
    let modelDescriptions = [
        "44th President of the United States.",
        "Civil Rights leader known for the Montgomery Bus Boycott.",
        "Abolitionist and Civil Rights leader."
    ]
    let modelLastNames   = ["Obama", "Parks", "Douglass"]

    @State private var selectedModelIndex = 0
    @State private var showARView = true

    var body: some View {
        VStack {
            ARViewContainer(
                modelName: modelNames[selectedModelIndex],
                modelText: modelFullNames[selectedModelIndex],
                modelDescription: modelDescriptions[selectedModelIndex],
                useWhiteBackground: !showARView ? true : false
            )
            .frame(maxWidth: .infinity, maxHeight: 400)

            Picker("Select Model", selection: $selectedModelIndex) {
                ForEach(0..<modelNames.count, id: \.self) { index in
                    Text(modelLastNames[index]).tag(index)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            Toggle("Show AR View (dark background)", isOn: $showARView)
                .padding(.horizontal)
                .padding(.bottom)
        }
        .navigationTitle("Legacy Tour")
    }
}

struct ARViewContainer: UIViewRepresentable {
    let modelName: String
    let modelText: String
    let modelDescription: String
    let useWhiteBackground: Bool

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.environment.background = useWhiteBackground ? .color(.white) : .color(.black)

        #if !targetEnvironment(simulator)
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        arView.session.run(config)
        #endif

        // Helper: find first ModelEntity in a hierarchy
        func firstModelEntity(in entity: Entity) -> ModelEntity? {
            if let me = entity as? ModelEntity { return me }
            for child in entity.children {
                if let found = firstModelEntity(in: child) { return found }
            }
            return nil
        }

        // Load the USDZ as a root Entity (not ModelEntity)
        if let root = try? Entity.load(named: modelName) {
            // Prefer plane anchoring so users can place on surfaces
            let anchor = AnchorEntity(plane: .any)

            // Find a ModelEntity to attach gestures/collisions
            if let model = firstModelEntity(in: root) {
                // Generate collisions for gestures to work
                model.generateCollisionShapes(recursive: true)
                // Install gestures on the model (no force-cast)
                arView.installGestures([.rotation, .scale], for: model)
            } else {
                // Fallback when no ModelEntity exists in the USDZ hierarchy:
                // Wrap the root in a ModelEntity "handle" so gestures can attach.
                let handle = ModelEntity()

                // Size the collision to the visual bounds of the root content
                let bounds = root.visualBounds(relativeTo: nil)
                let shape  = ShapeResource.generateBox(size: bounds.extents)
                handle.components[CollisionComponent.self] = CollisionComponent(shapes: [shape])

                // Optional: center the wrapped content
                root.position = .zero
                handle.addChild(root)

                // Now gestures can target 'handle'
                arView.installGestures([.rotation, .scale], for: handle)

                anchor.addChild(handle)
                arView.scene.addAnchor(anchor)
            }

            

            anchor.addChild(root)
            arView.scene.addAnchor(anchor)
        } else {
            // Visual fallback if the model is missing
            let text = MeshResource.generateText(
                "Missing \(modelName).usdz",
                extrusionDepth: 0.01,
                font: .systemFont(ofSize: 0.1, weight: .bold),
                containerFrame: .zero,
                alignment: .center,
                lineBreakMode: .byWordWrapping
            )
            let textEntity = ModelEntity(mesh: text, materials: [SimpleMaterial(color: .red, isMetallic: false)])
            let anchor = AnchorEntity(world: .zero)
            anchor.addChild(textEntity)
            arView.scene.addAnchor(anchor)
            print("⚠️ Failed to load \(modelName).usdz from bundle.")
        }

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
    }
}

#Preview {
    NavigationStack { ContentView() }
}

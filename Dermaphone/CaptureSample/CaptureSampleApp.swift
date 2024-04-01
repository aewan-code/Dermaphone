import SwiftUI

class CaptureSample: UIViewController {
    // Create an instance of CameraViewModel
    let model = CameraViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create a UIHostingController with ContentView
        let hostingController = UIHostingController(rootView: ContentView(model: model))
        
        // Add the hosting controller's view as a subview
        addChild(hostingController)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
    }
}

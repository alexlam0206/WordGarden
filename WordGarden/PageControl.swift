import SwiftUI
import UIKit

// A UIViewRepresentable for UIPageControl, allowing it to be used in SwiftUI.
struct PageControl: UIViewRepresentable {
    // The number of pages to display.
    var numberOfPages: Int
    // The current page index.
    @Binding var currentPage: Int

    // Creates the UIPageControl.
    func makeUIView(context: Context) -> UIPageControl {
        let control = UIPageControl()
        control.numberOfPages = numberOfPages
        control.pageIndicatorTintColor = UIColor.lightGray
        control.currentPageIndicatorTintColor = UIColor.darkGray
        control.addTarget(
            context.coordinator,
            action: #selector(Coordinator.updateCurrentPage(sender:)),
            for: .valueChanged)


        return control
    }

    // Updates the UIPageControl when data changes.
    func updateUIView(_ uiView: UIPageControl, context: Context) {
        uiView.numberOfPages = numberOfPages
        uiView.currentPage = currentPage
    }

    // Creates the coordinator to handle events.
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // The coordinator class to handle UIPageControl events.
    class Coordinator: NSObject {
        var control: PageControl

        init(_ control: PageControl) {
            self.control = control
        }

        // Updates the current page binding when the user interacts with the control.
        @objc func updateCurrentPage(sender: UIPageControl) {
            control.currentPage = sender.currentPage
        }
    }
}
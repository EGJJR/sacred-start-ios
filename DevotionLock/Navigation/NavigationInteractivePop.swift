//
//  NavigationInteractivePop.swift
//  DevotionLock
//
//  Restores edge-swipe back when custom ABYBackToolbar hides the system back button.
//

import SwiftUI
import UIKit

enum NavigationInteractivePop {
    static func configure() {
        // No-op: enabler is applied via View.abyInteractivePopEnabled().
    }
}

struct InteractivePopGestureEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        PopGestureHostController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        (uiViewController as? PopGestureHostController)?.enablePopGestureIfNeeded()
    }
}

private final class PopGestureHostController: UIViewController {
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        enablePopGestureIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        enablePopGestureIfNeeded()
    }

    func enablePopGestureIfNeeded() {
        guard let navigationController else { return }
        navigationController.interactivePopGestureRecognizer?.isEnabled = true
        navigationController.interactivePopGestureRecognizer?.delegate = navigationController
    }
}

extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}

extension View {
    func abyInteractivePopEnabled() -> some View {
        background(InteractivePopGestureEnabler())
    }
}

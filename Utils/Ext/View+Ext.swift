//
//  View+Ext.swift
//  Utils
//
//  Created by Andriy Biguniak on 10.05.2025.
//

import SwiftUI


extension View
{
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(NVDeviceRotationViewModifier(action: action))
    }
    
    
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    
    func onSizeUpdated(completion: @escaping (CGSize) -> Void) -> some View {
        self.background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        completion(proxy.size)
                    }
                    .onChange(of: proxy.size) {
                        completion(proxy.size)
                    }
            }
        }
    }
    
    
    // usage: .sync(self.$module.focused, with: self._focused)
    func sync<T: Equatable>(_ binding: Binding<T>, with focusState: FocusState<T>) -> some View {
        self
            .onChange(of: binding.wrappedValue) { old, new in
                focusState.wrappedValue = new
            }
            .onChange(of: focusState.wrappedValue) { old, new in
                binding.wrappedValue = new
            }
    }
    
    
    @inlinable
    func reversedMask<Mask: View>(
        alignment: Alignment = .center,
        @ViewBuilder _ mask: () -> Mask
    ) -> some View {
        self.mask(
            ZStack {
                Rectangle()
                mask()
                    .blendMode(.destinationOut)
            }
        )
    }
}


private struct NVDeviceRotationViewModifier: ViewModifier
{
    let action: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                action(UIDevice.current.orientation)
            }
    }
}

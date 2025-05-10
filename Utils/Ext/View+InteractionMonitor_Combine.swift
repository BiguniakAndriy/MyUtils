//
//  View+InteractionMonitor_Combine.swift
//  Utils
//
//  Created by Andriy Biguniak on 09.05.2025.
//

import SwiftUI
import Combine


public extension View
{
    func interactionMonitor(isInteracting: Binding<Bool>) -> some View {
        self.modifier(InteractionMonitorModifier(isInteracting: isInteracting))
    }
}


fileprivate struct InteractionMonitorModifier: ViewModifier
{
    @Binding
    var isInteracting: Bool
    
    @StateObject
    private var store = InteractionMonitor()
    
    func body(content: Content) -> some View {
        content
            .onChange(of: self.store.isInteracting) { _, new in
                self.isInteracting = new
            }
    }
}


final class InteractionMonitor: ObservableObject
{
    @Published
    var isInteracting = false
    
    private let idlePublisher = Timer.publish(every: 0.1, on: .main, in: .default).autoconnect()
    
    private let activePublisher = Timer.publish(every: 0.1, on: .main, in: .tracking).autoconnect()
    
    init() {
        self.activePublisher
            .map { _ in true }
            .merge(with: self.idlePublisher.map { _ in false })
            .removeDuplicates()
            .assign(to: &self.$isInteracting)
    }
}

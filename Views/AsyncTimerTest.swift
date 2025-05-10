//
//  ContentView.swift
//  Utils
//
//  Created by Andriy Biguniak on 22.04.2025.
//

import SwiftUI
import AsyncAlgorithms


struct MainView: View
{
    @Bindable
    var dataSource = MainViewDataSource()
    
    var body: some View {
        NavigationStack(path: self.$dataSource.navigationStack) {
            VStack {
                TestButton(name: "AsyncTimer") {
                    self.dataSource.navigationStack.append(.asyncTimer)
                }
            }
            .navigationDestination(for: Destionation.self) { destination in
                switch destination {
                    case .asyncTimer:
                        AsyncTimerView()
                    @unknown default:
                        Color.red
                }
            }
        }
    }
}

@Observable
class MainViewDataSource
{
    var navigationStack: [Destionation] = []
    
    init() {}
}

enum Destionation: Hashable
{
    case asyncTimer
}


struct AsyncTimerView: View
{
    let datasource = AsyncTimerDataSource()
    
    @State
    var text: Int = 0
    
    var body: some View {
        VStack {
            TestButton(name: "START") {
                self.datasource.startTimer()
            }
            
            Text("\(self.datasource.number)")
                .font(.title)
                .padding()
            
            TestButton(name: "STOP") {
                self.datasource.stopTimer()
            }
        }
        .onDisappear {
            self.datasource.stopTimer()
        }
    }
}

struct TestButton: View
{
    let name: String
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            Text(name).padding(10)
        }
        .buttonStyle(.borderedProminent)
    }
}


//@MainActor
@Observable
class AsyncTimerDataSource: @unchecked Sendable
{
    private var timer = AsyncTimer()
    
    var number: Int = 0
    
    init() {}
    
    deinit {
        print("deinit AsyncTimerDataSource")
    }
    
    func startTimer() {
//        Task { [weak self] in
            self.timer.start {
                Task { @MainActor [weak self] in
                    self?.number += 1
                }
            }
//        }
    }
    
    func stopTimer() {
        self.timer.stop()
        self.number = 0
    }
}

#Preview {
    AsyncTimerView()
}

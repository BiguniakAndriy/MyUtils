//
//  StreamMerge.swift
//  Utils
//
//  Created by Andriy Biguniak on 22.04.2025.
//


class StreamMerger<T: AsyncSequence>
{
    private var sequences: [(T, String)] = []
    
    var stream: AsyncStream<T> {
        let (stream, comntinuation) = AsyncStream<T>.makeStream()
        self.continuation = comntinuation
        return stream
    }
    
    private var continuation: AsyncStream<T>.Continuation?
    
    func append(sequence: T, identifier: String) {
        self.sequences.append((sequence, identifier))
        print("StreamMerger: sequence appended: \(identifier)")
    }
    
    func removeAll() {
        self.sequences.removeAll()
    }
    
    func remove(identifier: String) {
        if let index = self.sequences.firstIndex(where: { $0.1 == identifier }) {
            self.sequences.remove(at: index)
            print("StreamMerger: sequence removed: \(identifier)")
        } else {
            print("StreamMerger: sequence with\(identifier) not found")
        }
    }
}



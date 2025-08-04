//
//  MultiClientStreamProducer.swift
//  Utils
//
//  Created by Andriy Biguniak on 04.08.2025.
//

import Foundation


public actor MultiClientStreamProducer<T: Sendable>
{
    public
    nonisolated
    var stream: AsyncThrowingStream<T, Error> {
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: T.self)
        let clientID = UUID()
        continuation.onTermination = { [weak self] termination in
            guard let self = self else { return }
            Task {
                await self.removeClient(clientID)
            }
        }
        let client = Client(id: clientID, continuation: continuation)
        Task {
            await self.addClient(client)
        }
        return stream
    }
    
    private struct Client
    {
        let id: UUID
        let continuation: AsyncThrowingStream<T, Error>.Continuation
    }
    
    private var clients = Array<Client>()
    
    private var producerTask: Task<Void, Never>?
    
    private var clientsWaiting: CheckedContinuation<Void, Never>?
    
    private var waitingForClient: Bool
    
    private var changingInputStream: Bool = false
    
    private var producerID: String = "n/a"
    
    private let identifier: String
    
    public init(waitingForClints: Bool = true, identifier: String = "n/a"){
        self.waitingForClient = waitingForClints
        self.identifier = identifier
    }
    
    public nonisolated func setInputStream(_ input: AsyncThrowingStream<T, Error>) {
        Task {
            let producerID = await self.newProducerWillStart()
            let producer = Task { [weak self, id = self.identifier] in
                print("MCP: \(id). starting new producer task. id:\(producerID)")
                do {
                    for try await data in input {
                        //guard let self = self else { break }
                        await self?.sendDataToClients(data)
                    }
                    await self?.closeClientsStreams()
                } catch {
                    print(error)
                    await self?.closeClientsStreams(throwing: error)
                }
                print("MCP: \(id). producer task was closed. id:\(producerID)")
            }
            await self.setProducer(producer)
        }
    }
    
    public nonisolated func setInput<Input: AsyncSequence & Sendable>(_ input: Input)
    where Input.Element == T
    {
        Task {
            let producerID = await self.newProducerWillStart()
            let producer = Task { [weak self, id = self.identifier] in
                print("MCP: \(id). starting new producer task. id:\(producerID)")
                do {
                    for try await data in input {
                        //guard let self = self else { break }
                        await self?.sendDataToClients(data)
                    }
                    await self?.closeClientsStreams()
                } catch {
                    print(error)
                    await self?.closeClientsStreams(throwing: error)
                }
                print("MCP: \(id). producer task was closed. id:\(producerID)")
            }
            await self.setProducer(producer)
        }
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public nonisolated func setInputError(_ error: Error? = nil) {
        Task{
            if let error {
                print("MCP: \(self.identifier). setting error \(error) as input data.")
            } else {
                print("MCP: \(self.identifier). close immediately all new output stream.")
            }
            let producerID = await self.newProducerWillStart()
            let producer = Task { [weak self, id = self.identifier] in
                repeat {
                    await self?.waitingForClients()
                    if let error {
                        print("MCP: \(id). new client stream will be closed with error \(error)")
                    } else {
                        print("MCP: \(id). new client stream will be closed")
                    }
                    await self?.closeClientsStreams(throwing: error)
                } while !Task.isCancelled
                print("MCP: \(id). producer task was closed. id:\(producerID)")
            }
            await self.setProducer(producer)
        }
    }
    
    public func setWaitingForClients(_ value: Bool) {
        if !value {
            self.clientsWaiting?.resume()
            self.clientsWaiting = nil
        }
        self.waitingForClient = value
    }
    
    public nonisolated func reset() {
        Task{
            await self.producerTask?.cancel()
        }
    }
    
    private func newProducerWillStart() async -> String {
        self.clientsWaiting?.resume()
        self.clientsWaiting = nil
        if let oldProducer = self.producerTask {
            self.producerTask = nil
            print("MCP: \(self.identifier).  waiting for previous producer task (\(self.producerID)) closing")
            self.changingInputStream = true
            oldProducer.cancel()
            let _ = await oldProducer.value
            self.changingInputStream = false
        }
        self.producerID = String.random(length: 4)
        return self.producerID
    }
    
    private func setProducer(_ producer: Task<Void, Never>) {
        print("MCP: \(self.identifier). setting new producer task. id:\(self.producerID)")
        self.producerTask = producer
    }
    
    private func closeClientsStreams(throwing error: Error? = nil) {
        if !self.changingInputStream {
            self.clients.forEach{ $0.continuation.finish(throwing: error) }
        } else {
            print("MCP: \(self.identifier). avoiding closing output streams while changing input stream")
        }
    }
    
    private func removeClient(_ id: UUID) {
        var index = self.clients.count - 1
        while index >= 0 {
            if self.clients[index].id == id {
                self.clients[index].continuation.finish(throwing: CancellationError())
                self.clients.remove(at: index)
            }
            index -= 1
        }
    }
    
    private func addClient(_ client: Client) {
        self.clients.append(client)
        self.clientsWaiting?.resume()
        self.clientsWaiting = nil
    }
    
    private func waitingForClients() async {
        guard self.waitingForClient else { return }
        await withCheckedContinuation { continuation in
            if let previousWaiting = self.clientsWaiting {
                print("MCP: \(self.identifier). previous continuation is not resumed. possible data lost")
                previousWaiting.resume()
                self.clientsWaiting = nil
            }
            if self.clients.isEmpty {
                print("MCP: \(self.identifier). clients list is empty. waiting...")
                self.clientsWaiting = continuation
            } else {
                continuation.resume()
            }
        }
    }
    
    private func sendDataToClients(_ data: T) async {
        await self.waitingForClients()
        if !self.clients.isEmpty {
            print("MCP: \(self.identifier).  send data (\(String(reflecting: T.self)) to \(self.clients.count) client(s). waiting = \(self.waitingForClient)")
            self.clients.forEach { $0.continuation.yield(data) }
        }
    }
}

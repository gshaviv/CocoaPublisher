import Foundation
import UIKit
import Combine

protocol ControlWithPublisher: UIControl {}
extension UIControl: ControlWithPublisher {}

extension ControlWithPublisher {
    public func publisher(for event: UIControl.Event = .primaryActionTriggered) -> ControlPublisher<Self> {
        ControlPublisher(control:self, for:event)
    }
}

public struct ControlPublisher<T:UIControl> : Publisher {
    public typealias Output = T
    public typealias Failure = Never
    private unowned let control : T
    private let event : UIControl.Event
    
    public init(control:T, for event:UIControl.Event = .primaryActionTriggered) {
        self.control = control
        self.event = event
    }
    
    public func receive<S>(subscriber: S) where S : Subscriber, S.Input == Output, S.Failure == Failure {
        subscriber.receive(subscription: EventSubscription(downstream: subscriber, sender: control, event: event))
    }
    
    private class EventSubscription <S:Subscriber>: NSObject, Subscription where S.Input == Output, S.Failure == Failure {
        weak var sender : T?
        let event : UIControl.Event
        var downstream : S?
        
        init(downstream: S, sender : T, event : UIControl.Event) {
            self.downstream = downstream
            self.sender = sender
            self.event = event
        }
        
        func request(_ demand: Subscribers.Demand) {
            sender?.addTarget(self, action: #selector(handleEvent), for: event)
        }
        
        @objc func handleEvent() {
            guard let sender = sender else { return }
            _ = self.downstream?.receive(sender)
        }
        
        private func finish() {
            sender?.removeTarget(self, action: #selector(handleEvent), for: event)
            sender = nil
            downstream = nil
        }
        
        func cancel() {
            finish()
        }
        
        deinit {
            finish()
        }
    }
}


// -- gesture

protocol GestureWithPublisher: UIGestureRecognizer {}
extension UIGestureRecognizer: GestureWithPublisher {}

extension GestureWithPublisher {
    public func statePublisher() -> GesturePublisher<Self> {
        GesturePublisher(gesture:self)
    }
}

extension UITapGestureRecognizer {
    public var publisher: AnyPublisher<UITapGestureRecognizer, Never> {
        statePublisher().filter { $0.state == .ended }.eraseToAnyPublisher()
    }
}

extension UISwipeGestureRecognizer {
    public var publisher: AnyPublisher<UISwipeGestureRecognizer, Never> {
        statePublisher().filter { $0.state == .ended }.eraseToAnyPublisher()
    }
}

public struct GesturePublisher<T:UIGestureRecognizer> : Publisher {
    public typealias Output = T
    public typealias Failure = Never
    private unowned let gesture : T
    
    public init(gesture:T) {
        self.gesture = gesture
    }
    
    public func receive<S>(subscriber: S) where S : Subscriber, S.Input == Output, S.Failure == Failure {
        subscriber.receive(subscription: EventSubscription(downstream: subscriber, sender: gesture))
    }
    
    private class EventSubscription <S:Subscriber>: NSObject, Subscription where S.Input == Output, S.Failure == Failure {
        weak var sender : T?
        var downstream : S?
        
        init(downstream: S, sender : T) {
            self.downstream = downstream
            self.sender = sender
        }
        
        func request(_ demand: Subscribers.Demand) {
            sender?.addTarget(self, action: #selector(handleEvent))
        }
        
        @objc func handleEvent() {
            guard let sender = sender else { return }
            _ = self.downstream?.receive(sender)
        }
        
        private func finish() {
            sender?.removeTarget(self, action: #selector(handleEvent))
            sender = nil
            downstream = nil
        }
        
        func cancel() {
            finish()
        }
        
        deinit {
            finish()
        }
    }
}


// -- UIBarButtonItem



protocol BarButtonWithPublisher: UIBarButtonItem {}
extension UIBarButtonItem: BarButtonWithPublisher {}

extension BarButtonWithPublisher {
    public var publisher: BarButtonPublisher {
        BarButtonPublisher(control:self)
    }
}

public struct BarButtonPublisher : Publisher {
    public typealias Output = UIBarButtonItem
    public typealias Failure = Never
    private unowned let control : UIBarButtonItem
    
    public init(control:UIBarButtonItem) {
        self.control = control
    }
    
    public func receive<S>(subscriber: S) where S : Subscriber, S.Input == Output, S.Failure == Failure {
        subscriber.receive(subscription: EventSubscription(downstream: subscriber, sender: control))
    }
    
    private class EventSubscription <S:Subscriber>: NSObject, Subscription where S.Input == Output, S.Failure == Failure {
        weak var sender : UIBarButtonItem?
        var downstream : S?
        
        init(downstream: S, sender : UIBarButtonItem) {
            self.downstream = downstream
            self.sender = sender
        }
        
        func request(_ demand: Subscribers.Demand) {
            sender?.action = #selector(handleEvent)
            sender?.target = self
        }
        
        @objc func handleEvent() {
            guard let sender = sender else { return }
            _ = self.downstream?.receive(sender)
        }
        
        private func finish() {
            sender?.target = nil
            sender = nil
            downstream = nil
        }
        
        func cancel() {
            finish()
        }
        
        deinit {
            finish()
        }
    }
}

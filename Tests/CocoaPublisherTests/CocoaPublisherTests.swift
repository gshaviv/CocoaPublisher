import XCTest
@testable import CocoaPublisher
import UIKit
import Combine

final class CocoaPublisherTests: XCTestCase {
    func testButton() {
        var bag = [AnyCancellable]()
        let b = UIButton()
        var gotThere = false
        b.publisher(for: .touchUpInside)
            .sink { _ in
                gotThere = true
            }
            .store(in: &bag)
        b.callAction(for: .touchUpInside)
        XCTAssertTrue(gotThere)
    }
    
}


extension UIControl {
    func callAction(for event: UIControl.Event) {
        for target in allTargets {
            guard let target = target as? NSObjectProtocol else { continue }
            let actions = actions(forTarget: target, forControlEvent: event) ?? []
            for action in actions {
                target.perform(Selector(action), with: nil)
            }
        }
    }
}



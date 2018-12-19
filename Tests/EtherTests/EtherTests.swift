@testable import Ether
import XCTest

class EtherTests: XCTestCase {
    func testPrint() {
        print("hello")
    }
    
    static var allTests: [(String, (EtherTests) -> ()throws -> ())] {
        return [
            ("testPrint", testPrint)
        ]
    }
}

class AnotherTests: XCTestCase {
    func testOut() {
        print("bye")
    }
    
    static var allTests: [(String, (AnotherTests) -> ()throws -> ())] {
        return [
            ("testOut", testOut)
        ]
    }
}

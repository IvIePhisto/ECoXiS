import XCTest
import ECoXiS

class BasicTest: XCTestCase {

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testElement() {
        let text = "<Hello World!/>"
        var fooValue = "<foz'\">"
        var escapedFooValue = "&lt;foz'&quot;&gt;"
        var element = </"<test/>" + ["!foo": fooValue, "<bar/>": "boz"]
            + [<&text, PI("foo", "bar"), <!"--foo--bar--"]
        XCTAssert(element.name == "test")
        XCTAssert(element[0]! as XMLText == text)
        XCTAssert(text == element[0]! as XMLText)
        element.name = "1Foo/Bar?"
        XCTAssert(element.name == "FooBar")
        XCTAssert(element.attributes.count == 2)
        XCTAssert(element.attributes.contains("foo"))
        XCTAssert(element["foo"] == fooValue)
        XCTAssert(element.attributes.contains("bar"))
        XCTAssert(element.attributes["bar"] == "boz")
        element["bar"] = nil
        XCTAssert(element.attributes.count == 1)
        XCTAssert(!element.attributes.contains("bar"))
        var document = XML(element, doctype: Doctype())
        XCTAssert(document.toString() == "<?xml version=\"1.0\"?><!DOCTYPE FooBar><FooBar foo=\"\(escapedFooValue)\">&lt;Hello World!/&gt;<?foo bar?><!--foo-bar--></FooBar>")
        let pi = element[1] as XMLProcessingInstruction
        pi.value = "bar?> ? >"
        XCTAssert(pi.toString() == "<?foo bar? ? >?>")
        pi.target = nil
        element[0] = nil
        element[0] = nil
        element[0] = nil
        element["foo"] = nil
        XCTAssert(element.toString() == "<FooBar/>")
    }
}

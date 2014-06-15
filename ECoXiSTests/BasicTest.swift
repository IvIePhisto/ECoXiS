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
        var element = XMLElement("<test/>",
            ["!foo": fooValue, "<bar/>": "boz"], XMLText(text))
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
        XCTAssert(element.toString()
            == "<FooBar foo=\"\(escapedFooValue)\">&lt;Hello World!/&gt;</FooBar>")
        element[0] = nil
        element["foo"] = nil
        XCTAssert(element.toString() == "<FooBar/>")
    }
}

import XCTest
import ECoXiS

class BasicTest: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testPI() {
        let target = "-fo o <"
        let invalidTarget = "<?-"
        let value = "bar?>"
        let piString = "<?foo bar??>"
        let emptyPIString = "<?foo?>"
        var processingInstruction = PI(target, value)
        XCTAssert(processingInstruction.target == "foo")
        XCTAssert(processingInstruction.value == "bar?")
        XCTAssert(processingInstruction.toString() == piString)
        processingInstruction.value = nil
        XCTAssert(processingInstruction.toString() == emptyPIString)
        processingInstruction.target = invalidTarget
        XCTAssert(processingInstruction.target == nil)
        XCTAssert(processingInstruction.toString().isEmpty)
        // Text:
        XCTAssert(pi(target, value) == piString)
        XCTAssert(pi(target) == emptyPIString)
        XCTAssert(pi(invalidTarget).isEmpty)
    }

    func testComment() {
        let content = "--Foo----Bar--"
        let invalidContent = "----"
        let commentString = "<!--Foo-Bar-->"
        var comment = <!content
        XCTAssert(comment.content == "Foo-Bar")
        XCTAssert(comment.toString() == commentString)
        comment.content = invalidContent
        XCTAssert(comment.content == nil)
        XCTAssert(comment.toString() == "")
        // Text:
        XCTAssert(!content == commentString)
        XCTAssert(!invalidContent == "")
    }

    func testText() {
        let content = "<Foo & Bar>"
        let contentString = "&lt;Foo &amp; Bar&gt;"
        let text = <&content
        XCTAssert(text == content)
        XCTAssert(content == text)
        XCTAssert(text.toString() == contentString)
        // Text:
        XCTAssert(content& == contentString)
    }

    func testElement() {
        let text = "<Hello World!/>"
        let fooValue = "<foz'\">"
        let escapedFooValue = "&lt;foz'&quot;&gt;"
        let elementString = "<FooBar foo=\"&lt;foz'&quot;&gt;\">&lt;Hello World!/&gt;<?foo bar?><!--foo-bar--></FooBar>"
        let attributes = ["!foo": fooValue, "<bar/>": "boz"]
        var element = <"<test/>" | attributes
            | [<&text, PI("foo", "bar"), <!"--foo--bar--"]
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
        XCTAssert(element.toString() == elementString)
        element[0] = nil
        element[0] = nil
        element[0] = nil
        element["foo"] = nil
        XCTAssert(element.toString() == "<FooBar/>")
        // Text:
        XCTAssert(el("1Foo/Bar?", ["foo": fooValue], text& + pi("foo", "bar")
            + !"--foo--bar--") == elementString)
        XCTAssert(el("1Foo/Bar?") == "<FooBar/>")
    }
}

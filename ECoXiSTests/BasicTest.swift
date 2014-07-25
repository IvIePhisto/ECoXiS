// TODO: add equality tests

import XCTest
import ECoXiS


func template(title: String, message: String) -> XMLDocument {
    let titleTextNode = <&title
    return XML(
        <"html" | ["lang": "en", "xmlns": "http://www.w3.org/1999/xhtml"] | [
            <"head" | [<"title" | titleTextNode],
            <"body" | [
                <"h1" | titleTextNode,
                <"p!" | <&message,
                <!"This is a comment, multiple --- are collapsed!--",
                PI("processing-instruction-target", "PI?> content")
            ]
        ],
        omitXMLDeclaration: true, doctype: Doctype()
    )
}


class BasicTest: XCTestCase {

    func testPI() {
        let target = "-fo o <"
        let invalidTarget = "<?-"
        let value = "bar?>"
        let piString = "<?foo bar??>"
        let emptyPIString = "<?foo?>"
        // Model:
        var processingInstruction = PI(target, value)
        XCTAssert(processingInstruction.target == "foo")
        XCTAssert(processingInstruction.value == "bar?")
        XCTAssert(processingInstruction.description == piString)
        processingInstruction.value = nil
        XCTAssert(processingInstruction.description == emptyPIString)
        processingInstruction.target = invalidTarget
        XCTAssert(processingInstruction.target == nil)
        XCTAssert(processingInstruction.description.isEmpty)
        // Text:
        XCTAssert(pi(target, value) == piString)
        XCTAssert(pi(target) == emptyPIString)
        XCTAssert(pi(invalidTarget).isEmpty)
    }

    func testComment() {
        let content = "--Foo----Bar--"
        let invalidContent = "----"
        let commentString = "<!--Foo-Bar-->"
        // Model:
        var comment = <!content
        XCTAssert(comment.content == "Foo-Bar")
        XCTAssert(comment.description == commentString)
        comment.content = invalidContent
        XCTAssert(comment.content == nil)
        XCTAssert(comment.description == "")
        // Text:
        XCTAssert(!content == commentString)
        XCTAssert(!invalidContent == "")
    }

    func testText() {
        let content = "<Foo & Bar>"
        let contentString = "&lt;Foo &amp; Bar&gt;"
        // Model:
        let text = <&content
        XCTAssert(text == content)
        XCTAssert(content == text)
        XCTAssert(text.description == contentString)
        // Text:
        XCTAssert(content& == contentString)
    }

    func testElement() {
        let text = "<Hello World!/>"
        let fooValue = "<foz'\">"
        let escapedFooValue = "&lt;foz'&quot;&gt;"
        let elementString = "<FooBar foo=\"&lt;foz'&quot;&gt;\">&lt;Hello World!/&gt;<?foo bar?><!--foo-bar--></FooBar>"
        let attributes = ["!foo": fooValue, "<bar/>": "boz"]
        // Model:
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
        XCTAssert(element.description == elementString)
        element[0] = nil
        element[0] = nil
        element[0] = nil
        element["foo"] = nil
        XCTAssert(element.description == "<FooBar/>")
        // Text:
        XCTAssert(el("1Foo/Bar?", ["foo": fooValue], text& + pi("foo", "bar")
            + !"--foo--bar--") == elementString)
        XCTAssert(el("1Foo/Bar?") == "<FooBar/>")
    }

    func testDoctype() {
        var doctype = Doctype(publicID: "<Foo Bar>", systemID: "\"foo'\"bar")
        XCTAssert(doctype.publicID == "Foo Bar")
        XCTAssert(!doctype.useQuotForSystemID)
        XCTAssert(doctype.systemID == "\"foo\"bar")
        XCTAssert(doctype.toString("test")
            == "<!DOCTYPE test PUBLIC \"Foo Bar\" '\"foo\"bar'>")
        doctype.systemID = nil
        XCTAssert(doctype.publicID != nil
            && doctype.toString("test") == "<!DOCTYPE test>")
        doctype.systemID = "foo'bar\""
        XCTAssert(doctype.useQuotForSystemID)
        XCTAssert(doctype.systemID == "foo'bar")
        doctype.publicID = nil
        XCTAssert(doctype.toString("test")
            == "<!DOCTYPE test SYSTEM \"foo'bar\">")
        doctype.systemID = nil
        XCTAssert(doctype.toString("foo") == "<!DOCTYPE foo>")
    }

    func testDocument() {
        let documentString = "<?xml version=\"1.0\"?><!DOCTYPE FooBar><!--before--><FooBar/><?after?>"
        // Model:
        var document = XML(<"FooBar", beforeElement: [<!"before"],
            afterElement: [PI("after")], doctype: Doctype())
        XCTAssert(document.toString() == documentString)
        document.element.name = nil
        XCTAssert(document.toString().isEmpty)
        document.element.name = "test"
        document.omitXMLDeclaration = true
        document.doctype = nil
        document.beforeElement = []
        document.afterElement.removeAll()
        XCTAssert(document.toString() == "<test/>")
        // Text:
        XCTAssert(xml("FooBar", doctype: Doctype(), beforeElement: !"before",
            afterElement: pi("after")) == documentString)
        XCTAssert(xml("<>").isEmpty)
        XCTAssert(xml("test", omitXMLDeclaration: true) == "<test/>")
    }

    func testTemplate() {
        let templateString = "<!DOCTYPE html><html lang=\"en\" xmlns=\"http://www.w3.org/1999/xhtml\"><head><title>&lt;Foo Bar&gt;</title></head><body><h1>&lt;Foo Bar&gt;</h1><p>Hello World!</p><!--This is a comment, multiple - are collapsed!--><?processing-instruction-target PI? content?></body></html>"
        XCTAssert(template("<Foo Bar>", "Hello World!").toString() == templateString)
    }
}

# ECoXiS – Easy Creation of XML in Swift

This XCode 6 project implements a library to create XML in Apple's Swift. It is
currently in alpha status, meaning the implementation and interfaces may be
subject to change. It supports the full XML standard except for standalone
document type declarations and entity definitions. There is no CDATA
representation, because that is just an easier way to markup certain text nodes.


## Example

Here is example Swift code using ECoXiS. It implements a template function to
create a HTML5 document:

```Swift
func template(title: String, message: String) -> XMLDocument {
    let escapedTitle = <&title
    return XML(
        <"html" | ["lang": "en", "xmlns": "http://www.w3.org/1999/xhtml"]
        | [
            <"head" | [<"title" | escapedTitle],
            <"body" | [
                <"h1" | escapedTitle,
                <"p!" | <&message,
                <!"This is a comment, multiple --- are collapsed!--",
                PI("processing-instruction-target", "PI?> content")
            ]
        ],
        omitXMLDeclaration: true, doctype: Doctype()
    )
}
```

The call of `template("<Foo Bar>", "Hello world!").toString()` yields (here
pretty printed for better readability):

```XML
<!DOCTYPE html>
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
    <head><title>&lt;Foo Bar&gt;</title></head>
    <body>
        <h1>&lt;Foo Bar&gt;</h1>
        <p>Hello World!</p>
        <!--This is a comment, multiple - are collapsed!-->
        <?processing-instruction-target PI? content?>
    </body>
</html>
```

## API

The code should be self-documenting (knowledge of XML assumed), but see the
following for a description of the important files and their contents.

### XML Object Model – `ECoXiS/Model.swift`

In this file a object model for XML is defined. It enforces well-formedness.
Strings given for XML constructs (like element or attribute names) are
stripped of invalid characters or strings. If such a construct becomes
invalid by these modifications, its `toString()` method returns an empty
string (e.g. if an element's name contains no valid characters, calling
`toString()` on that element returns an empty string). The XML model is
defined by the following:

`protocol XMLNode`
:   Defines the interface for XML nodes.

`protocol XMLMiscNode: XMLNode`
:   Used to mark comment and processing instruction nodes to be used as
    document child nodes.

`class XMLDocumentTypeDeclaration`
:   Contains the data of a document type declaration.

`class XMLDocument: Sequence`
:   Implements a XML document. It contains an `XMLElement` instance as the
    document element, before and after that may be `XMLMiscNode` instances.
    It can also contain a `XMLDocumentTypeDeclaration`.

`class XMLAttributes`
:   A `Dictionary<String, String>`-like object representing attributes of
    an XML element.

`class XMLElement: XMLNode`
:   Represents an XML element with child nodes and attributes, which can be
    accessed as the instance properties `attributes: XMLAttributes` and
    `children: XMLNode[]` or by subscript access (using `String` returns an
    attribute, `Int` as subscript returns a child node).

`class XMLText: XMLNode`
:   An instance of this class stands for a XML text node in this model.

`class XMLComment: XMLMiscNode`
:   XML comments are implemented by this class.

`class XMLProcessingInstruction: XMLMiscNode`
:   This class represents the processing instructions of XML.


### Main File & Shortcuts – `ECoXiS/ECoXiS.swift`

The main file of the module, but it contains only a few shortcuts to create
objects from `ECoXiS/Model.swift`.

Type-aliases
:   `XML = XMLDocument`
:   `PI = XMLProcessingInstruction`
:   `Doctype = XMLDocumentTypeDeclaration`

Operator  `@prefix func < (String) -> XMLElement`
:   Creates a `XMLElement` instance, the name being the given string.

Operator `@infix func | (XMLElement, Dictionary<String, String>) -> XMLElement`
:   For each entry in the given dictionary set the the appropriate attribute on
    the element.

Operator `@infix func | (XMLElement, XMLNode) -> XMLElement`
:   Appends the given node to the children of the element.

Operator `@infix func | (XMLElement, XMLNode[]) -> XMLElement`
:   Appends all the nodes given in the array to the children of the element.

Operator `@prefix func <& (String) -> XMLText`
:   Creates a `XMLText` instance, the content being the given string.

Operator `@prefix func <! (String) -> XMLComment`
:   Creates a `XMLComment` instance, the content being the given string.


### Low-Overhead XML String Creation – `ECoXiS/StringCreation.swift`

Here some operators and functions are defined to create strings of (possible
malformed) XML, but with little overhead.

`func xml -> String`
:   Creates the string for a XML document. The data for the root element must be
    given and it may be specified to omit the XML declaration, if and what
    document type declaration to use and more.

`func el -> String`
:   Produces the string for a XML element.

`func pi -> String`
:   Creates the string for a XML processing instruction.

Operator `@postfix func & (String) -> String`
:   Escapes the given string to use it as XML text.

Operator `@prefix func ! (String) -> String`
:   Makes the text for a XML comment from the given string.


### Utilities for XML – `ECoXiS/Utilities.swift`

Contains the class `XMLUtilities` which has class methods to escape text for
XML and to enforce various syntax constraints of XML.


### File `ECoXiSTests/BasicTests.swift`

In this file some tests for the API are defined, see this for some usage
examples.

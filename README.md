# ECoXiS – Easy Creation of XML in Swift

This library implements a library to create XML in Apple's Swift as an XCode 6
project. It is currently in alpha status, meaning the implementation and
interfaces may be subject to change.

## Example

Here is example Swift code using ECoXiS to implement a template function
creating a HTML5 document:

    func template(title: String, message: String) -> String {
        let escapedTitle = title&
        return XML(
            <"html" + ["lang": "en", "xmlns": "http://www.w3.org/1999/xhtml"]
            + [
                <"head" + [<"title" + [escapedTitle]],
                <"body" + [
                    <"h1" + escapedTitle,
                    <"p!" + message&,
                    !"This is a comment, multiple --- are collapsed!--",
                    PI("processing-instruction-target", "PI?> content")
                ]
            ],
            omitXMLDeclaration: true, doctype: Doctype()
        )
    }

The call of `template("<Foo Bar>", "Hello world!")` yields (here pretty printed
for better readability):

    <!DOCTYPE html>
    <html lang="en" xmlns="http://www.w3.org/1999/xhtml">
        <head><title>&lt;Foo Bar&gt;</title></head>
        <body>
            <h1>&lt;Foo Bar&gt;</h1>
            <p>Hello World!
                <!--This is a comment, multiple - are collapsed!-->
                <?processing-instruction-target PI content?>
            </p>
        </body>
    </html>


## API

The code should be self-documenting (knowledge of XML assumed), but see the
following for a description of the important files and their contents:

`ECoXiS/ECoXiS.swift`
:   The main file of the module, but it contains only a few shortcuts to create
    objects from `ECoXiS/Model.swift`

`ECoXiS/Model.swift`
:   In this file a object model for XML is defined. It enforces well-formedness.

`ECoXiS/StringCreation.swift`
:   Here some operators and functions are defined to create strings of (possible
    malformed) XML, but with little overhead.

`ECoXiS/Utilities.swift`
:   Contains the class `XMLUtilities` which contains class methods to escape
    text for XML and to enforce various syntax constraints of XML.

`ECoXiSTests/BasicTests.swift`
:   In this file some tests for the API are defined, see this for some examples.

operator prefix <& {}

@prefix func <& (content: String) -> XMLText {
    return XMLText(content)
}

operator prefix <! {}

@prefix func <! (content: String) -> XMLComment {
    return XMLComment(content)
}

operator prefix </ {}

@prefix func </ (name: String) -> XMLElement {
    return XMLElement(name)
}


@infix func + (element: XMLElement, attributes: Dictionary<String, String>)
        -> XMLElement {
    for (name, value) in attributes {
        element[name] = value
    }
    return element
}

@infix func + (element: XMLElement, nodes: XMLNode[])
        -> XMLElement {
    element.children += nodes
    return element
}

typealias PI = XMLProcessingInstruction
typealias Doctype = XMLDocumentTypeDeclaration
typealias XML = XMLDocument

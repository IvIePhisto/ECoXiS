public operator prefix <& {}

@prefix public func <& (content: String) -> XMLText {
    return XMLText(content)
}

public operator prefix <! {}

@prefix public func <! (content: String) -> XMLComment {
    return XMLComment(content)
}

public operator prefix < {}

@prefix public func < (name: String) -> XMLElement {
    return XMLElement(name)
}


@infix public func | (element: XMLElement, attributes: [String: String])
        -> XMLElement {
    for (name, value) in attributes {
        element[name] = value
    }
    return element
}


@infix public func | (element: XMLElement, nodes: [XMLNode])
        -> XMLElement {
    element.children += nodes
    return element
}

@infix public func | (element: XMLElement, node: XMLNode)
        -> XMLElement {
    element.children += node
    return element
}


public typealias PI = XMLProcessingInstruction
public typealias Doctype = XMLDocumentTypeDeclaration
public typealias XML = XMLDocument

prefix operator <& {}

/**
Creates a XML text node.
:param content: The text contained in the node.
:returns: The created text instance.
*/
public prefix func <& (content: String) -> XMLText {
    return XMLText(content)
}


prefix operator <! {}


/**
Creates a XML comment node.

Note that the comment content is stripped of invalid character combinations,
i.e. a dash ("-") may not appear at the beginning or the end and in between
only single dashes may appear.

:param content: The text of the comment.
:returns: The created comment instance.
*/
public prefix func <! (content: String) -> XMLComment {
    return XMLComment(content)
}

prefix operator </ {}

/**
Creates an XML element node.

Note that the element name is stripped of invalid characters.

:param name: The name of the element.
:returns: The created element instance.
*/
public prefix func </ (name: String) -> XMLElement {
    return XMLElement(name)
}


/**
Sets attributes on a XML element from a dictionary of string to strings.

Note that attribute names are stripped of invalid characters.

:param element: The element instance to set attributes on.
:param attributes: The attributes to be set.
:returns: The element instance.
*/
public func | (element: XMLElement, attributes: [String: String])
        -> XMLElement {
    for (name, value) in attributes {
        element[name] = value
    }
    return element
}


/**
Appends an array of XML nodes to the children of an element.

:param element: The element to which the nodes will be appended.
:param nodes: The nodes to append to the elemnts's children.
:returns: The element instance.
*/
public func | (element: XMLElement, nodes: [XMLNode])
        -> XMLElement {
    element.children += nodes
    return element
}


/**
Appends a single XML node to the children of an element.

:param element: The element to which the node will be appended.
:param node: The node to append to the element's children.
:returns: The element instance.
*/
public func | (element: XMLElement, node: XMLNode)
        -> XMLElement {
    element.children.append(node)
    return element
}


public typealias PI = XMLProcessingInstruction
public typealias Doctype = XMLDocumentTypeDeclaration
public typealias XML = XMLDocument

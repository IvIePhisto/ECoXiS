// TODO: add deep copying

public enum XMLNodeType {
    case Element, Text, Comment, ProcessingInstruction
}


public protocol XMLNode: Printable {
    var nodeType: XMLNodeType { get }
}

public func == (left: XMLNode, right: XMLNode) -> Bool {
    if left.nodeType != right.nodeType {
        return false
    }

    switch left.nodeType {
    case .Element:
        return (left as! XMLElement) != right as! XMLElement
    case .Text:
        return (left as! XMLText) != right as! XMLText
    case .Comment:
        return (left as! XMLComment) != right as! XMLComment
    case .ProcessingInstruction:
        return left as! XMLProcessingInstruction
                != right as! XMLProcessingInstruction
    }
}

public func != (left: XMLNode, right: XMLNode) -> Bool {
    return !(left == right)
}

public func == (left: [XMLNode], right: [XMLNode]) -> Bool {
    if left.count != right.count {
        return false
    }

    for (leftNode, rightNode) in Zip2(left, right) {
        if leftNode != rightNode {
            return false
        }
    }

    return true
}


public protocol XMLMiscNode: XMLNode {}

public func == (left: XMLMiscNode, right: XMLMiscNode) -> Bool {
    return left as XMLNode == right as XMLNode
}

public func != (left: XMLMiscNode, right: XMLMiscNode) -> Bool {
    return (left as XMLNode) != right as XMLNode
}

public func == (left: [XMLMiscNode], right: [XMLMiscNode]) -> Bool {
    if left.count != right.count {
        return false
    }

    for (leftNode, rightNode) in Zip2(left, right) {
        if leftNode != rightNode {
            return false
        }
    }

    return true
}

public func += (inout left: [XMLNode], right: [XMLMiscNode]) {
    for node in right {
        left.append(node)
    }
}

public func == (left: String, right: XMLText) -> Bool {
    return left == right.content
}

public func == (left: XMLText, right: String) -> Bool {
    return left.content == right
}

public enum XMLNameSettingResult {
    case InvalidName, ModifiedName, ValidName
}


public class XMLAttributes: SequenceType, Equatable {
    private var _attributes = [String: String]()

    public var count: Int { return _attributes.count }

    // MARK: BUG: making "attributes" unnamed yields compiler error
    init(attributes: [String: String] = [:]) {
        update(attributes)
    }

    public func set(name: String, _ value: String?) -> XMLNameSettingResult {
        if let _name = XMLUtilities.enforceName(name) {
            if !_name.isEmpty {
                _attributes[_name] = value
                return _name == name ? .ValidName : .ModifiedName
            }
        }

        return .InvalidName
    }

    public func contains(name: String) -> Bool {
        return _attributes[name] != nil
    }

    public func update(attributes: [String: String]) {
        for (name, value) in attributes {
            set(name, value)
        }
    }

    public func generate() -> GeneratorOf<(String, String)> {
        return GeneratorOf(_attributes.generate())
    }

    public subscript(name: String) -> String? {
        get {
            return _attributes[name]
        }

        set {
            set(name, newValue)
        }
    }

    class func createString(var attributeGenerator:
            GeneratorOf<(String, String)>) -> String {
        var result = ""

        while let (name, value) = attributeGenerator.next() {
            var escapedValue = XMLUtilities.escape(value, .EscapeQuot)
            result += " \(name)=\"\(escapedValue)\""
        }

        return result
    }

    func toString() -> String {
        return XMLAttributes.createString(self.generate())
    }

    func equals(other: XMLAttributes) -> Bool {
        return self._attributes == other._attributes
    }
}

public func == (left: XMLAttributes, right: XMLAttributes) -> Bool {
    return left.equals(right)
}


public class XMLElement: XMLNode, Equatable {
    public let nodeType = XMLNodeType.Element

    private var _name: String?
    public var name: String? {
        get { return _name }
        set {
            if let name = newValue {
                _name = XMLUtilities.enforceName(name)
            }
            else {
                _name = nil
            }
        }
    }

    public let attributes: XMLAttributes
    public var children: [XMLNode]

    public var description:String {
        if let n = name {
            return XMLElement.createString(n,
                attributesString: attributes.toString(),
                childrenString: XMLElement.createChildrenString(children))
        }

        return ""
    }

    public init(_ name: String, attributes: [String: String] = [:],
            children: [XMLNode] = []) {
        self.attributes = XMLAttributes(attributes: attributes)
        self.children = children
        self.name = name
    }

    public subscript(name: String) -> String? {
        get {
            return attributes[name]
        }

        set {
            attributes[name] = newValue
        }
    }

    public subscript(index: Int) -> XMLNode? {
        get {
            if index < children.count {
                return children[index]
            }

            return nil
        }

        set {
            if let node = newValue {
                if index == children.count {
                    children.append(node)
                }
                else {
                    children[index] = node
                }
            }
            else {
                children.removeAtIndex(index)
            }
        }
    }

    class func createChildrenString(children: [XMLNode]) -> String {
        var childrenString = ""

        for child in children {
            childrenString += child.description
        }

        return childrenString
    }

    class func createString(name: String, attributesString: String = "",
            childrenString: String = "") -> String {
        var result = "<\(name)\(attributesString)"

        if childrenString.isEmpty {
            result += "/>"
        }
        else {
            result += ">\(childrenString)</\(name)>"
        }

        return result
    }
}

public func == (left: XMLElement, right: XMLElement) -> Bool {
        if left.name != right.name || left.attributes != right.attributes {
            return false
        }

        return left.children == right.children
}


public class XMLDocumentTypeDeclaration: Equatable {
    private var _systemID: String?
    private var _publicID: String?
    private var _useQuotForSystemID = false

    public var useQuotForSystemID: Bool { return _useQuotForSystemID }
    public var systemID: String? {
        get { return _systemID }
        set {
            (_useQuotForSystemID, _systemID) =
                XMLUtilities.enforceDoctypeSystemID(newValue)
        }
    }
    public var publicID: String? {
        get { return _publicID }
        set {
            _publicID = XMLUtilities.enforceDoctypePublicID(newValue)
        }
    }

    public init(publicID: String? = nil, systemID: String? = nil) {
        self.publicID = publicID
        self.systemID = systemID
    }

    public func toString(name: String) -> String {
        var result = "<!DOCTYPE \(name)"

        if let sID = systemID {
            if let pID = publicID {
                result += " PUBLIC \"\(pID)\" "

            }
            else {
                result += " SYSTEM "
            }

            if useQuotForSystemID {
                result += "\"\(sID)\""
            }
            else {
                result += "'\(sID)'"
            }
        }

        result += ">"

        return result
    }
}

public func == (left: XMLDocumentTypeDeclaration,
        right: XMLDocumentTypeDeclaration) -> Bool {
    return left.publicID == right.publicID && left.systemID == right.systemID
}


public class XMLDocument: SequenceType, Equatable {
    public var omitXMLDeclaration: Bool
    public var doctype: XMLDocumentTypeDeclaration?
    public var beforeElement: [XMLMiscNode]
    public var element: XMLElement
    public var afterElement: [XMLMiscNode]
    public var count: Int {
        return beforeElement.count + 1 + afterElement.count
    }

    public init(_ element: XMLElement, beforeElement: [XMLMiscNode] = [],
            afterElement: [XMLMiscNode] = [],
            omitXMLDeclaration:Bool = false,
            doctype: XMLDocumentTypeDeclaration? = nil) {
        self.beforeElement = beforeElement
        self.element = element
        self.afterElement = afterElement
        self.omitXMLDeclaration = omitXMLDeclaration
        self.doctype = doctype
    }

    public func generate() -> GeneratorOf<XMLNode> {
        var nodes = [XMLNode]()
        nodes += beforeElement
        nodes.append(element)
        nodes += afterElement

        return GeneratorOf(nodes.generate())
    }

    class func createString(#omitXMLDeclaration: Bool,
            encoding: String? = nil,
            doctypeString: String?,
            childrenString: String) -> String {
        var result = ""

        if !omitXMLDeclaration {
            result += "<?xml version=\"1.0\""

            if let e = encoding {
                result += " encoding=\"\(e)\""
            }

            result += "?>"
        }

        if let dtString = doctypeString {
            result += dtString
        }

        result += childrenString

        return result
    }

    public func toString(encoding: String? = nil) -> String {
        if element.name == nil {
            return ""
        }

        var doctypeString: String?

        if let dt = doctype {
            if let n = element.name {
                doctypeString = dt.toString(n)
            }
        }

        var childrenString = ""

        for child in self {
            childrenString += child.description
        }

        return XMLDocument.createString(omitXMLDeclaration: omitXMLDeclaration,
            encoding: encoding, doctypeString: doctypeString,
            childrenString: childrenString)
    }
}

public func == (left: XMLDocument, right: XMLDocument) -> Bool {
    return left.omitXMLDeclaration == right.omitXMLDeclaration
        && left.doctype == right.doctype
        && left.beforeElement == right.beforeElement
        && left.element == right.element
        && left.afterElement == right.afterElement
}


public class XMLText: XMLNode, Equatable {
    public let nodeType = XMLNodeType.Text
    public var content: String

    public var description: String {
        return XMLText.createString(content)
    }

    public init(_ content: String) {
        self.content = content
    }

    class func createString(content: String) -> String {
        return XMLUtilities.escape(content)
    }
}

public func == (left: XMLText, right: XMLText) -> Bool {
    return left.content == right.content
}


/**
Represents a XML comment node.

Note that a value assigned to the property/initialization parameter `content` is
stripped of invalid character combinations: a dash ("-") may not appear at
the beginning or the end and in between only single dashes may appear.
*/
public class XMLComment: XMLMiscNode, Equatable {
    public let nodeType = XMLNodeType.Comment

    private var _content: String?
    public var content: String? {
        get { return _content }
        set { _content = XMLUtilities.enforceCommentContent(newValue) }
    }

    public var description: String {
        if let c = content {
            return XMLComment.createString(c)
        }

        return ""
    }

    public init(_ content: String) {
        self.content = content
    }

    class func createString(content: String) -> String {
        return "<!--\(content)-->"
    }
}

public func == (left: XMLComment, right: XMLComment) -> Bool {
    return left.content == right.content
}


public class XMLProcessingInstruction: XMLMiscNode, Equatable {
    public let nodeType = XMLNodeType.ProcessingInstruction

    private var _target: String?
    public var target: String? {
        get { return _target }
        set {
            _target = XMLUtilities.enforceProcessingInstructionTarget(newValue)
        }
    }

    private var _value: String?
    public var value: String? {
        get { return _value }
        set {
            _value = XMLUtilities.enforceProcessingInstructionValue(newValue)
        }
    }


    public var description: String {
        if let t = target {
            return XMLProcessingInstruction.createString(t, value: value)
        }

        return ""
    }

    public init(_ target: String, _ value: String? = nil) {
        self.target = target
        self.value = value
    }

    class func createString(target: String, value: String?) -> String {
        var result = ""
        result += "<?\(target)"

        if let v = value {
            result += " \(v)"
        }

        result += "?>"
        return result
    }
}

public func == (left: XMLProcessingInstruction,
        right: XMLProcessingInstruction) -> Bool {
    return left.target == right.target && left.value == right.value
}

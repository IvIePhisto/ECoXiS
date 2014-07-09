enum XMLNodeType {
    case Document, Element, Text, Comment, ProcessingInstruction
}


protocol XMLNode {
    var nodeType: XMLNodeType { get }

    func toString() -> String
}


protocol XMLMiscNode: XMLNode {}


@assignment func += (inout left: [XMLNode], right: [XMLMiscNode]) {
    for node in right {
        left.append(node)
    }
}

@infix func ==(left: String, right: XMLText) -> Bool {
    return left == right.content
}

@infix func ==(left: XMLText, right: String) -> Bool {
    return left.content == right
}


class XMLAttributes: Sequence {
    let _get: String -> String?
    let set: (String, String?) -> Bool?
    let contains: String -> Bool
    let _count: () -> Int
    let _generate: () -> DictionaryGenerator<String, String>

    var count: Int { return _count() }

    init(attributes: [String: String] = [:]) { // making "attributes" unnamed yields compiler error
        var attrs = [String: String]()
        _get = { attrs[$0] }
        set = {
            var maybeName = XMLUtilities.enforceName($0)

            if let name = maybeName {
                if !name.isEmpty {
                    if let value = $1 {
                        attrs[name] = $1
                        return true
                    } else {
                        attrs[name] = nil
                        return false
                    }
                }
            }

            return nil
        }
        contains = { attrs[$0] != nil }
        _count = { attrs.count }
        _generate = { attrs.generate() }
        update(attributes)
    }

    func update(attributes: [String: String]) {
        for (name, value) in attributes {
            set(name, value)
        }
    }

    func generate() -> DictionaryGenerator<String, String> {
        return _generate()
    }

    subscript(name: String) -> String? {
        get {
            return _get(name)
        }

        set {
            set(name, newValue)
        }
    }

    class func createString(var attributeGenerator:
            DictionaryGenerator<String, String>) -> String {
        var result = ""

        while let (name, value) = attributeGenerator.next() {
            var escapedValue = XMLUtilities.escape(value, .EscapeQuot)
            result += " \(name)=\"\(escapedValue)\""
        }

        return result
    }

    func toString() -> String {
        return XMLAttributes.createString(self._generate())
    }
}


class XMLElement: XMLNode {
    let nodeType = XMLNodeType.Element

    let getName: () -> String?
    let setName: String? -> ()
    var name: String? {
        get { return getName() }
        set { setName(newValue) }
    }
    let attributes: XMLAttributes
    var children: [XMLNode]

    init(_ name: String, attributes: [String: String] = [:],
            children: [XMLNode] = []) {
        var elementName:String? = nil
        getName = { elementName }
        setName = {
            if let name = $0 {
                elementName = XMLUtilities.enforceName(name)
            }
            else {
                elementName = nil
            }
        }
        self.attributes = XMLAttributes(attributes: attributes)
        self.children = children
        self.name = name
    }

    subscript(name: String) -> String? {
        get {
            return attributes[name]
        }

        set {
            attributes[name] = newValue
        }
    }

    subscript(index: Int) -> XMLNode? {
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
            childrenString += child.toString()
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

    func toString() -> String {
        if let n = name {
            return XMLElement.createString(n,
                attributesString: attributes.toString(),
                childrenString: XMLElement.createChildrenString(children))
        }

        return ""
    }
}


class XMLDocumentTypeDeclaration {
    let _getSystemID: () -> String?
    let _setSystemID: String? -> ()
    let _getPublicID: () -> String?
    let _setPublicID: String? -> ()
    let _getUseQuotForSystemID: () -> Bool

    var useQuotForSystemID: Bool { return _getUseQuotForSystemID() }
    var systemID: String? {
        get { return _getSystemID() }
        set { _setSystemID(newValue) }
    }
    var publicID: String? {
        get { return _getPublicID() }
        set { _setPublicID(newValue) }
    }

    init(publicID: String? = nil, systemID: String? = nil) {
        var pubID: String?
        _getPublicID = { pubID }
        _setPublicID = { pubID = XMLUtilities.enforceDoctypePublicID($0) }
        var sysID: String?
        var useQuot: Bool = true
        _getSystemID = { sysID }
        _setSystemID = {
            (useQuot, sysID) = XMLUtilities.enforceDoctypeSystemID($0)
        }
        _getUseQuotForSystemID = { useQuot }
        self.publicID = publicID
        self.systemID = systemID
    }

    func toString(name: String) -> String {
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


class XMLDocument: Sequence {
    var omitXMLDeclaration: Bool
    var doctype: XMLDocumentTypeDeclaration?
    var beforeElement: [XMLMiscNode]
    var element: XMLElement
    var afterElement: [XMLMiscNode]
    var count: Int { return beforeElement.count + 1 + afterElement.count }


    init(_ element: XMLElement, beforeElement: [XMLMiscNode] = [],
            afterElement: [XMLMiscNode] = [],
            omitXMLDeclaration:Bool = false,
            doctype: XMLDocumentTypeDeclaration? = nil) {
        self.beforeElement = beforeElement
        self.element = element
        self.afterElement = afterElement
        self.omitXMLDeclaration = omitXMLDeclaration
        self.doctype = doctype
    }

    func generate() -> GeneratorOf<XMLNode> {
        var nodes = [XMLNode]()
        nodes += beforeElement
        nodes += element
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

    func toString(encoding: String? = nil) -> String {
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
            childrenString += child.toString()
        }

        return XMLDocument.createString(omitXMLDeclaration: omitXMLDeclaration,
            encoding: encoding, doctypeString: doctypeString,
            childrenString: childrenString)
    }
}


class XMLText: XMLNode {
    let nodeType = XMLNodeType.Text

    let _getContent: () -> String
    let _setContent: String -> ()
    var content: String {
        get { return _getContent() }
        set { _setContent(newValue) }
    }

    init(_ content: String) {
        var c = ""
        _getContent = { c }
        _setContent = { c = $0 }
        self.content = content
    }

    class func createString(content: String) -> String {
        return XMLUtilities.escape(content)
    }

    func toString() -> String {
        return XMLText.createString(content)
    }
}


class XMLComment: XMLMiscNode {
    let nodeType = XMLNodeType.Comment

    let _getContent: () -> String?
    let _setContent: String? -> ()
    var content: String? {
        get { return _getContent() }
        set { _setContent(newValue) }
    }

    init(_ content: String) {
        var c:String?
        _getContent = { c }
        _setContent = { c = XMLUtilities.enforceCommentContent($0) }
        self.content = content
    }

    class func createString(content: String) -> String {
        return "<!--\(content)-->"
    }

    func toString() -> String {
        if let c = content {
            return XMLComment.createString(c)
        }

        return ""
    }
}


class XMLProcessingInstruction: XMLMiscNode {
    let nodeType = XMLNodeType.ProcessingInstruction

    let _getTarget: () -> String?
    let _setTarget: String? -> ()
    var target: String? {
        get { return _getTarget() }
        set { _setTarget(newValue) }
    }

    let _getValue: () -> String?
    let _setValue: String? -> ()
    var value: String? {
        get { return _getValue() }
        set { _setValue(newValue) }
    }

    init(_ target: String, _ value: String? = nil) {
        var t:String? = nil
        _getTarget = { t }
        _setTarget = {
            t = XMLUtilities.enforceProcessingInstructionTarget($0)
        }
        var v:String? = nil
        _getValue = { v }
        _setValue = { v = XMLUtilities.enforceProcessingInstructionValue($0) }
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

    func toString() -> String {
        if let t = target {
            return XMLProcessingInstruction.createString(t, value: value)
        }

        return ""
    }
}


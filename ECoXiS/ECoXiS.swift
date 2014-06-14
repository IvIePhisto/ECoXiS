import Foundation


enum XMLCharacterScalars: UInt32 {
    case Colon = 58, A = 65, Z = 90, a = 97, z = 122, Underscore = 95,
        Minus = 45, Dot = 46, Zero = 48, Nine = 57
}


class XMLUtilities {
    class func escape(text: String) -> String {
        if let escapedText = CFXMLCreateStringByEscapingEntities(
                nil, text.bridgeToObjectiveC(), nil) {
            return escapedText
        }

        return ""
    }

    class func isNameStartCharacter(codePoint: UInt32) -> Bool {
        return XMLCharacterScalars.Colon.toRaw() == codePoint
            || (XMLCharacterScalars.A.toRaw() <= codePoint
                    && XMLCharacterScalars.Z.toRaw() >= codePoint)
            || XMLCharacterScalars.Underscore.toRaw() == codePoint
            || (XMLCharacterScalars.a.toRaw() <= codePoint
                    && XMLCharacterScalars.z.toRaw() >= codePoint)
            || (0xC0 <= codePoint && 0xD6 >= codePoint)
            || (0xD8 <= codePoint && 0xF6 >= codePoint)
            || (0xF8 <= codePoint && 0x2FF >= codePoint)
            || (0x370 <= codePoint && 0x37D >= codePoint)
            || (0x37F <= codePoint && 0x1FFF >= codePoint)
            || (0x200C <= codePoint && 0x200D >= codePoint)
            || (0x2070 <= codePoint && 0x218F >= codePoint)
            || (0x2C00 <= codePoint && 0x2FEF >= codePoint)
            || (0x3001 <= codePoint && 0xD7FF >= codePoint)
            || (0xF900 <= codePoint && 0xFDCF >= codePoint)
            || (0xFDF0 <= codePoint && 0xFFFD >= codePoint)
            || (0x10000 <= codePoint && 0xEFFFF >= codePoint)
    }

    class func isNameCharacter(codePoint: UInt32) -> Bool {
        if isNameStartCharacter(codePoint) {
            return true
        }
        return XMLCharacterScalars.Minus.toRaw() == codePoint
            || XMLCharacterScalars.Dot.toRaw() == codePoint
            || (XMLCharacterScalars.Zero.toRaw() <= codePoint
                    && XMLCharacterScalars.Nine.toRaw() >= codePoint)
            || 0xB7 == codePoint
            || (0x300 <= codePoint && 0x36F >= codePoint)
            || (0x203F <= codePoint && 0x2040 >= codePoint)
    }

    class func enforceName(name: String) -> String? {
        var result = ""
        var resultCharacterCount = 0
        var check: UInt32 -> Bool = isNameStartCharacter
        check = {
            (codePoint: UInt32) -> Bool in
            check = self.isNameCharacter
            return self.isNameStartCharacter(codePoint)
        }

        for unicodeScalar in name.unicodeScalars {
            var codePoint = unicodeScalar.value

            if check(codePoint) {
                result += "\(unicodeScalar)"
                resultCharacterCount++
            }
        }

        if resultCharacterCount == 0 {
            return nil
        }

        return result
    }
}


enum XMLNodeType {
    case Document, Element, Text, Comment, ProcessingInstruction
}


class XMLNode {
    let nodeType: XMLNodeType

    init(_ nodeType: XMLNodeType) {
        self.nodeType = nodeType
    }

    func toString() -> String {
        return ""
    }
}


class XMLText: XMLNode {
    var value: String

    init(_ value: String) {
        self.value = value
        super.init(.Text)
    }

    override func toString() -> String {
        return XMLUtilities.escape(value)
    }
}


@infix func ==(left: String, right: XMLText) -> Bool {
    return left == right.value
}

@infix func ==(left: XMLText, right: String) -> Bool {
    return left.value == right
}


class XMLContainerNode: XMLNode {
    var children: XMLNode[]

    init(_ nodeType: XMLNodeType, children: XMLNode[]) {
        self.children = children
        super.init(nodeType)
    }
}


class XMLAttributes: Sequence {
    let _get: String -> String?
    let set: (String, String?) -> Bool?
    let contains: String -> Bool
    let _count: () -> Int
    let _generate: () -> DictionaryGenerator<String, String>

    var count: Int { return _count() }

    init(attributes: Dictionary<String, String> = [:]) { // making "attributes" unnamed yields compiler error
        var attrs = Dictionary<String, String>()
        _get = { attrs[$0] }
        set = {
            var maybeName = XMLUtilities.enforceName($0)

            if let name = maybeName {
                if let value = $1 {
                    attrs[name] = value
                    return true
                } else {
                    attrs[name] = nil
                    return false
                }
            }

            return nil
        }
        contains = { attrs[$0] != nil }
        _count = { attrs.count }
        _generate = { attrs.generate() }
        update(attributes)
    }

    func update(attributes: Dictionary<String, String>) {
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

    func toString() -> String {
        var result = ""

        for (name, value) in self {
            var escapedValue = XMLUtilities.escape(value)
            result += " \(name)=\"\(escapedValue)\""
        }

        return result
    }
}


class XMLElement: XMLContainerNode {
    let getName: () -> String?
    let setName: String? -> ()
    var name: String? {
        get { return getName() }
        set { setName(newValue) }
    }
    let attributes: XMLAttributes

    init(_ name: String, _ attributes: Dictionary<String, String> = [:],
            _ children: XMLNode...) {
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
        super.init(.Element, children: children)
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

    override func toString() -> String {
        var result = "<\(name)\(attributes.toString())"

        if children.count == 0 {
            result += "/>"
        }
        else {
            result += ">"

            for child in children {
                result += child.toString()
            }

            result += "</\(name)>"
        }

        return result
    }
}


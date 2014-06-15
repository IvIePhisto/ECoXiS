class XMLUtilities {
    enum CharacterScalars: UInt32 {
        case Colon = 58, A = 65, Z = 90, a = 97, z = 122, Underscore = 95,
            Minus = 45, Dot = 46, Zero = 48, Nine = 57
    }

    enum AttributeValueEscape {
        case NoAttribute, EscapeQuot, EscapeApos
    }

    class func escape(value: String, _ attributeValueEscape:
            AttributeValueEscape = .NoAttribute) -> String {
        var result = ""

        for character in value {
            switch (character, attributeValueEscape) {
            case ("<", _):
                result += "&lt;"
            case (">", _):
                result += "&gt;"
            case ("&", _):
                result += "&amp;"
            case ("'", .EscapeApos):
                result += "&apos;"
            case ("\"", .EscapeQuot):
                result += "&quot;"
            default:
                result += character
            }
        }

        return result
    }

    class func isNameStartCharacter(codePoint: UInt32) -> Bool {
        return CharacterScalars.Colon.toRaw() == codePoint
            || (CharacterScalars.A.toRaw() <= codePoint
                    && CharacterScalars.Z.toRaw() >= codePoint)
            || CharacterScalars.Underscore.toRaw() == codePoint
            || (CharacterScalars.a.toRaw() <= codePoint
                    && CharacterScalars.z.toRaw() >= codePoint)
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
        return CharacterScalars.Minus.toRaw() == codePoint
            || CharacterScalars.Dot.toRaw() == codePoint
            || (CharacterScalars.Zero.toRaw() <= codePoint
                    && CharacterScalars.Nine.toRaw() >= codePoint)
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

    class func enforceCommentContent(value: String) -> String {
        var isFirst = true
        var index = 0
        var lastIndex = countElements(value) - 1
        var result = ""
        var appendMinus = false
        var lastWasMinus = false

        for character in value {
            let isMinus = character == "-"
            let isLast = index == lastIndex

            if isMinus {
                appendMinus = !isFirst
            }
            else {
                if appendMinus && !isLast {
                    result += "-"
                    appendMinus = false
                }
                result += character
                isFirst = false
                lastWasMinus = false
            }

            index++
        }

        return result
    }

    class func enforceProcessingInstructionTarget(target: String?) -> String? {
        if let t = target {
            if let t = enforceName(t) {
                if countElements(t) == 3 {
                    var invalid = true
                    var index = 0

                    validation: for character in t {
                        switch (index, character) {
                        case (0, "x"), (0, "X"), (1, "m"), (1, "M"), (2, "l"),
                                (2, "L"):
                            break
                        default:
                            invalid = false
                            break validation
                        }
                        index++
                    }

                    if invalid {
                        return nil
                    }
                }

                return t
            }
        }

        return nil
    }

    class func enforceProcessingInstructionValue(value: String?) -> String? {
        if let v = value {
            var result = ""
            var lastWasQuestionMark = false

            for character in v {
                if character != ">" || !lastWasQuestionMark {
                    result += character
                    lastWasQuestionMark = character == "?"
                }
            }

            return result
        }

        return nil
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


class XMLContentNode: XMLNode {
    let _getContent: () -> String
    let _setContent: String -> ()
    var content: String {
        get { return _getContent() }
        set { _setContent(newValue) }
    }

    init(_ nodeType: XMLNodeType, _ content: String,
            getter: () -> String, setter: String -> ()) {
        _getContent = getter
        _setContent = setter
        super.init(nodeType)
        self.content = content
    }
}


class XMLText: XMLContentNode {
    init(_ content: String) {
        var c = ""
        super.init(.Text, content, getter: { c }, setter: { c = $0 })
    }

    override func toString() -> String {
        return XMLUtilities.escape(content)
    }
}


class XMLComment: XMLContentNode {
    init(_ content: String) {
        var c = ""
        super.init(.Comment, content, getter: { c },
            setter: { c = XMLUtilities.enforceCommentContent($0) })
    }

    override func toString() -> String {
        return "<!--\(content)-->"
    }
}


class XMLProcessingInstruction: XMLNode {
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
        var v:String? = ""
        _getValue = { v }
        _setValue = { v = XMLUtilities.enforceProcessingInstructionValue($0) }
        super.init(.ProcessingInstruction)
        self.target = target
        self.value = value
    }

    override func toString() -> String {
        var result = ""

        if let t = target {
            result += "<?\(target)"

            if let v = value {
                result += " \(v)"
            }

            result += "?>"
        }

        return result
    }
}


@infix func ==(left: String, right: XMLText) -> Bool {
    return left == right.content
}

@infix func ==(left: XMLText, right: String) -> Bool {
    return left.content == right
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
            var escapedValue = XMLUtilities.escape(value, .EscapeQuot)
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
        if let n = name {
            var result = "<\(n)\(attributes.toString())"
            var childrenString = ""

            for child in children {
                childrenString += child.toString()
            }

            if childrenString.isEmpty {
                result += "/>"
            }
            else {
                result += ">\(childrenString)</\(name)>"
            }

            return result
        }

        return ""
    }
}


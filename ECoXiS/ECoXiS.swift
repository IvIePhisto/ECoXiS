class XMLUtilities {
    struct CharacterScalars {
        static let Colon:UInt32 = 58
        static let A:UInt32 = 65
        static let Z:UInt32 = 90
        static let a:UInt32 = 97
        static let z:UInt32 = 122
        static let Underscore:UInt32 = 95
        static let Minus:UInt32 = 45
        static let Dot:UInt32 = 46
        static let Zero:UInt32 = 48
        static let Nine:UInt32 = 57
        static let Space:UInt32 = 32
        static let Return:UInt32 = 13
        static let NewLine:UInt32 = 10
        static let Apostrophe:UInt32 = 39
        static let Slash:UInt32 = 47
        static let ExclamationMark:UInt32 = 33
        static let Hashbang:UInt32 = 35
        static let Percent:UInt32 = 37
        static let Equals:UInt32 = 61
        static let QuestionMark:UInt32 = 63
        static let Semicolon:UInt32 = 59
        static let At:UInt32 = 64
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
        return CharacterScalars.Colon == codePoint
            || (CharacterScalars.A <= codePoint
                    && CharacterScalars.Z >= codePoint)
            || CharacterScalars.Underscore == codePoint
            || (CharacterScalars.a <= codePoint
                    && CharacterScalars.z >= codePoint)
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
        return CharacterScalars.Minus == codePoint
            || CharacterScalars.Dot == codePoint
            || (CharacterScalars.Zero <= codePoint
                    && CharacterScalars.Nine >= codePoint)
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

    class func enforceDoctypeSystemID(systemID: String?) -> (Bool, String?) {
        if let sysID = systemID {
            var useQuot: Bool?
            var result = ""

            for character in sysID {
                switch character {
                case "'":
                    if let uQ = useQuot {
                        if uQ {
                            result += character
                        }
                    } else {
                        result += character
                        useQuot = true
                    }
                case "\"":
                    if let uQ = useQuot {
                        if !uQ {
                            result += character
                        }
                    } else {
                        result += character
                        useQuot = false
                    }
                default:
                    result += character
                }
            }

            if !useQuot {
                useQuot = true
            }

            return (useQuot!, result)
        }

        return (true, nil)
    }

    class func enforceDoctypePublicID(publicID: String?) -> String? {
        if let pID = publicID {
            var result = ""

            for unicodeScalar in pID.unicodeScalars {
                var us = unicodeScalar.value

                switch us {
                case CharacterScalars.Space,
                        CharacterScalars.Return,
                        CharacterScalars.NewLine,
                        CharacterScalars.ExclamationMark,
                        CharacterScalars.Colon,
                        CharacterScalars.Equals,
                        CharacterScalars.QuestionMark,
                        CharacterScalars.Semicolon,
                        CharacterScalars.At,
                        CharacterScalars.Underscore:
                    result += "\(unicodeScalar)"
                default:
                    if (CharacterScalars.A <= us && CharacterScalars.Z >= us)
                        || (CharacterScalars.a <= us
                                && CharacterScalars.z >= us)
                        || (CharacterScalars.Zero <= us
                                && CharacterScalars.Nine >= us)
                        || (CharacterScalars.Apostrophe <= us
                                && CharacterScalars.Slash >= us)
                        || (CharacterScalars.Hashbang <= us
                                && CharacterScalars.Percent >= us) {
                        result += "\(unicodeScalar)"
                    }
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


protocol XMLNode {
    var nodeType: XMLNodeType { get }

    func toString() -> String
}


protocol XMLMiscNode: XMLNode {}


@assignment func += (inout left: XMLNode[], right: XMLMiscNode[]) {
    for node in right {
        left.append(node)
    }
}


class XMLContentNode: XMLNode {
    let nodeType: XMLNodeType
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
        self.nodeType = nodeType
        self.content = content
    }

    class func createString(content: String) -> String {
        return ""
    }

    func toString() -> String {
        return ""
    }
}


class XMLText: XMLContentNode {
    init(_ content: String) {
        var c = ""
        super.init(.Text, content, getter: { c }, setter: { c = $0 })
    }

    override class func createString(content: String) -> String {
        return XMLUtilities.escape(content)
    }

    override func toString() -> String {
        return XMLText.createString(content)
    }
}


class XMLComment: XMLContentNode, XMLMiscNode {
    init(_ content: String) {
        var c = ""
        super.init(.Comment, content, getter: { c },
            setter: { c = XMLUtilities.enforceCommentContent($0) })
    }

    override class func createString(content: String) -> String {
        return "<!--\(content)-->"
    }

    override func toString() -> String {
        return XMLComment.createString(content)
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
        var v:String? = ""
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
    var children: XMLNode[]

    init(_ name: String, attributes: Dictionary<String, String> = [:],
            children: XMLNode[] = []) {
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

    class func createChildrenString(children: XMLNode[]) -> String {
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

struct XMLDocumentTypeDeclaration {
    let useQuotForSystemID: Bool
    let systemID: String?
    let publicID: String?

    init(publicID: String? = nil, systemID: String? = nil) {
        (useQuotForSystemID, self.systemID) =
            XMLUtilities.enforceDoctypeSystemID(systemID)
        self.publicID = XMLUtilities.enforceDoctypePublicID(publicID)
    }

    func toString(name: String) -> String {
        var result = "<!DOCTYPE \(name) "

        if let sID = systemID {
            if let pID = publicID {
                result += "PUBLIC \"\(pID)\" "

            }
            else {
                result += "SYSTEM "
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
    var beforeElement: XMLMiscNode[]
    var element: XMLElement
    var afterElement: XMLMiscNode[]
    var count: Int { return beforeElement.count + 1 + afterElement.count }


    init(_ element: XMLElement, beforeElement: XMLMiscNode[] = [],
            afterElement: XMLMiscNode[] = [],
            omitXMLDeclaration:Bool = false,
            doctype: XMLDocumentTypeDeclaration? = nil) {
        self.beforeElement = beforeElement
        self.element = element
        self.afterElement = afterElement
        self.omitXMLDeclaration = omitXMLDeclaration
        self.doctype = doctype
    }

    func generate() -> IndexingGenerator<Array<XMLNode>> {
        var nodes = XMLNode[]()
        nodes += beforeElement
        nodes += element
        nodes += afterElement

        return nodes.generate()
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

    func toString() -> String {
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
            doctypeString: doctypeString, childrenString: childrenString)
    }
}

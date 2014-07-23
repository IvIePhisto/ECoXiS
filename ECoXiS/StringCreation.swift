public operator postfix & {} // not possible to use '&' as prefix operator

@postfix public func & (content: String) -> String {
    return XMLUtilities.escape(content)
}


@prefix public func ! (content: String) -> String {
    let maybeContent = XMLUtilities.enforceCommentContent(content)
    
    if let c = maybeContent {
        return XMLComment.createString(c)
    }

    return ""
}


public func pi(target: String, _ value: String? = nil) -> String {
    let maybeTarget = XMLUtilities.enforceProcessingInstructionTarget(target)

    if let t = maybeTarget {
        let v = XMLUtilities.enforceProcessingInstructionValue(value)
        return XMLProcessingInstruction.createString(t, value: v)
    }

    return ""
}


public func el(name: String, _ attributes: [String: String] = [:],
        _ children: String = "") -> String {
    let maybeName = XMLUtilities.enforceName(name)

    if let n = maybeName {
        var preparedAttributes = [String: String]()

        for (name, value) in attributes {
            if let n = XMLUtilities.enforceName(name) {
                preparedAttributes[n] = value
            }
        }

        let a = XMLAttributes.createString(GeneratorOf(preparedAttributes.generate()))
        return XMLElement.createString(n, attributesString: a,
            childrenString: children)
    }

    return ""
}


public func el(name: String, children: String) -> String {
    return el(name, [:], children)
}


public func xml(name: String, _ attributes: [String: String] = [:],
            _ children: String = "", omitXMLDeclaration:Bool = false,
            encoding: String? = nil,
            doctype: XMLDocumentTypeDeclaration? = nil,
            beforeElement: String = "", afterElement: String = "") -> String {
    if let n = XMLUtilities.enforceName(name) {
        let dt = doctype?.toString(n)
        let element = el(name, attributes, children)
        let childrenString = beforeElement + element + afterElement

        return XMLDocument.createString(omitXMLDeclaration: omitXMLDeclaration,
            encoding: encoding, doctypeString: dt, childrenString: childrenString)
    }

    return ""
}


public func xml(name: String, children: String, omitXMLDeclaration:Bool = false,
            encoding: String? = nil,
            doctype: XMLDocumentTypeDeclaration? = nil,
            beforeElement: String = "", afterElement: String = "") -> String {
    return xml(name, [:], children,
        omitXMLDeclaration: omitXMLDeclaration, encoding: encoding,
        doctype: doctype, beforeElement: beforeElement,
        afterElement: afterElement)
}

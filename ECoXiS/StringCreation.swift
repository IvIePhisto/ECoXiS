operator postfix & {}

@postfix func & (content: String) -> String {
    return XMLUtilities.escape(content)
}

@prefix func ! (content: String) -> String {
    let c = XMLUtilities.enforceCommentContent(content)
    return XMLComment.createString(c)
}

func pi(target: String, _ value: String? = nil) -> String {
    let maybeTarget = XMLUtilities.enforceProcessingInstructionTarget(target)

    if let t = maybeTarget {
        let v = XMLUtilities.enforceProcessingInstructionValue(value)
        return XMLProcessingInstruction.createString(t, value: v)
    }

    return ""
}

func el(name: String, _ attributes: Dictionary<String, String> = [:],
        children: () -> String) -> String {
    let maybeName = XMLUtilities.enforceName(name)

    if let n = maybeName {
        let c = children()
        var preparedAttributes = Dictionary<String, String>()

        for (name, value) in attributes {
            if let n = XMLUtilities.enforceName(name) {
                let v = XMLUtilities.escape(value, .EscapeQuot)
                preparedAttributes[n] = v
            }
        }

        let a = XMLAttributes.createString(preparedAttributes.generate())
        return XMLElement.createString(n, attributesString: a,
            childrenString: c)
    }

    return ""
}


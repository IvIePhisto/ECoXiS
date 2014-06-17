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


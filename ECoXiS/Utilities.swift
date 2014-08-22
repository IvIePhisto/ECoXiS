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
                result.append(character)
            }
        }

        return result
    }

    class func isCodePointValid(codePoint: UInt32, valid: UInt32...) -> Bool {
        for validCodePoint in valid {
            if codePoint == validCodePoint {
                return true
            }
        }

        return false
    }

    class func isCodePointInRanges(codePoint: UInt32,
            ranges: (UInt32, UInt32)...) -> Bool {
        for (lowerBound, upperBound) in ranges {
            if lowerBound <= codePoint && codePoint <= upperBound {
                return true
            }
        }

        return false
    }

    class func isNameStartCharacter(codePoint: UInt32) -> Bool {
        return isCodePointValid(codePoint, valid:
                    CharacterScalars.Colon,
                    CharacterScalars.Underscore)
            || isCodePointInRanges(codePoint, ranges:
                (CharacterScalars.A, CharacterScalars.Z),
                (CharacterScalars.a, CharacterScalars.z),
                (0xC0, 0xD6),
                (0xD8, 0xF6),
                (0xF8, 0x2FF),
                (0x370, 0x37D),
                (0x37F, 0x1FFF),
                (0x200C, 0x200D),
                (0x2070, 0x218F),
                (0x2C00, 0x2FEF),
                (0x3001, 0xD7FF),
                (0xF900, 0xFDCF),
                (0xFDF0, 0xFFFD),
                (0x10000, 0xEFFFF))
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
            let isNameStartCharacter = self.isNameStartCharacter(codePoint)

            if isNameStartCharacter {
                check = self.isNameCharacter
            }

            return isNameStartCharacter
        }

        for unicodeScalar in name.unicodeScalars {
            var codePoint = unicodeScalar.value

            if check(codePoint) {
                result.append(unicodeScalar)
                resultCharacterCount++
            }
        }

        if resultCharacterCount == 0 {
            return nil
        }

        return result
    }

    class func enforceCommentContent(content: String?) -> String? {
        if let c = content {
            var isFirst = true
            var index = 0
            var lastIndex = countElements(c) - 1
            var result = ""
            var appendMinus = false
            var lastWasMinus = false

            for character in c {
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
                    result.append(character)
                    isFirst = false
                    lastWasMinus = false
                }

                index++
            }

            if result.isEmpty {
                return nil
            }

            return result
        }

        return nil
    }

    class func enforceProcessingInstructionTarget(target: String?) -> String? {
        if let t = target {
            if let t = enforceName(t) {
                if countElements(t) == 3 {
                    check: for (index, character) in enumerate(t) {
                        switch (index, character) {
                        case (0, "x"), (0, "X"), (1, "m"), (1, "M"):
                            break
                        case (2, "l"), (2, "L"):
                            return nil
                        default:
                            break check
                        }
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
                    result.append(character)
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
                            result.append(character)
                        }
                    } else {
                        result.append(character)
                        useQuot = true
                    }
                case "\"":
                    if let uQ = useQuot {
                        if !uQ {
                            result.append(character)
                        }
                    } else {
                        result.append(character)
                        useQuot = false
                    }
                default:
                    result.append(character)
                }
            }

            if useQuot == nil {
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
                    result.append(unicodeScalar)
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
                        result.append(unicodeScalar)
                    }
                }
            }

            return result
        }

        return nil
    }
}


#Requires AutoHotkey v2.0

class Json {
    static Parse(text) {
        parser := Json.Parser(text)
        return parser.Parse()
    }

    static Dump(value, indent := 2) {
        serializer := Json.Serializer(indent)
        return serializer.Dump(value)
    }

    class Parser {
        __New(text) {
            this.text := text
            this.length := StrLen(text)
            this.index := 1
        }

        Parse() {
            value := this.ParseValue()
            this.SkipWhitespace()
            if (this.index <= this.length) {
                throw Error("Unexpected trailing JSON content at position " this.index)
            }
            return value
        }

        ParseValue() {
            this.SkipWhitespace()
            if (this.index > this.length) {
                throw Error("Unexpected end of JSON input.")
            }

            ch := this.Peek()
            switch ch {
                case "{":
                    return this.ParseObject()
                case "[":
                    return this.ParseArray()
                case '"':
                    return this.ParseString()
                case "t":
                    return this.ParseLiteral("true", true)
                case "f":
                    return this.ParseLiteral("false", false)
                case "n":
                    return this.ParseLiteral("null", "")
            }

            if RegExMatch(ch, "^-|\d$") {
                return this.ParseNumber()
            }

            throw Error("Unexpected JSON token '" ch "' at position " this.index)
        }

        ParseLiteral(literal, value) {
            literalLength := StrLen(literal)
            if (SubStr(this.text, this.index, literalLength) != literal) {
                throw Error("Expected '" literal "' at position " this.index)
            }

            this.index += literalLength
            return value
        }

        ParseObject() {
            obj := Map()
            this.index += 1
            this.SkipWhitespace()

            if (this.Peek() = "}") {
                this.index += 1
                return obj
            }

            loop {
                key := this.ParseString()
                this.SkipWhitespace()
                this.Expect(":")
                obj[key] := this.ParseValue()
                this.SkipWhitespace()

                ch := this.Peek()
                if (ch = "}") {
                    this.index += 1
                    break
                }

                if (ch != ",") {
                    throw Error("Expected ',' or '}' at position " this.index)
                }

                this.index += 1
                this.SkipWhitespace()
            }

            return obj
        }

        ParseArray() {
            arr := []
            this.index += 1
            this.SkipWhitespace()

            if (this.Peek() = "]") {
                this.index += 1
                return arr
            }

            loop {
                arr.Push(this.ParseValue())
                this.SkipWhitespace()

                ch := this.Peek()
                if (ch = "]") {
                    this.index += 1
                    break
                }

                if (ch != ",") {
                    throw Error("Expected ',' or ']' at position " this.index)
                }

                this.index += 1
                this.SkipWhitespace()
            }

            return arr
        }

        ParseString() {
            this.Expect('"')
            result := ""

            while (this.index <= this.length) {
                ch := this.Peek()
                this.index += 1

                if (ch = '"') {
                    return result
                }

                if (ch = "\") {
                    escape := this.Peek()
                    this.index += 1

                    switch escape {
                        case '"', "\\", "/":
                            result .= escape
                        case "b":
                            result .= Chr(8)
                        case "f":
                            result .= Chr(12)
                        case "n":
                            result .= "`n"
                        case "r":
                            result .= "`r"
                        case "t":
                            result .= "`t"
                        case "u":
                            hexValue := SubStr(this.text, this.index, 4)
                            if !RegExMatch(hexValue, "^[0-9A-Fa-f]{4}$") {
                                throw Error("Invalid unicode escape at position " this.index)
                            }

                            result .= Chr("0x" hexValue)
                            this.index += 4
                        default:
                            throw Error("Invalid escape sequence at position " this.index)
                    }

                    continue
                }

                result .= ch
            }

            throw Error("Unterminated JSON string.")
        }

        ParseNumber() {
            start := this.index

            if (this.Peek() = "-") {
                this.index += 1
            }

            if (this.Peek() = "0") {
                this.index += 1
            } else {
                this.ConsumeDigits()
            }

            if (this.Peek() = ".") {
                this.index += 1
                this.ConsumeDigits()
            }

            ch := this.Peek()
            if (ch = "e" || ch = "E") {
                this.index += 1
                if (this.Peek() = "+" || this.Peek() = "-") {
                    this.index += 1
                }
                this.ConsumeDigits()
            }

            numberText := SubStr(this.text, start, this.index - start)
            return numberText + 0
        }

        ConsumeDigits() {
            start := this.index

            while (this.index <= this.length) {
                if !RegExMatch(this.Peek(), "^\d$") {
                    break
                }
                this.index += 1
            }

            if (this.index = start) {
                throw Error("Expected digit at position " this.index)
            }
        }

        SkipWhitespace() {
            while (this.index <= this.length) {
                ch := this.Peek()
                if (ch = " " || ch = "`t" || ch = "`n" || ch = "`r") {
                    this.index += 1
                    continue
                }
                break
            }
        }

        Expect(expected) {
            if (this.Peek() != expected) {
                throw Error("Expected '" expected "' at position " this.index)
            }
            this.index += 1
        }

        Peek() {
            return (this.index > this.length) ? "" : SubStr(this.text, this.index, 1)
        }
    }

    class Serializer {
        __New(indent := 2) {
            this.indent := indent
        }

        Dump(value) {
            return this.SerializeValue(value, 0)
        }

        SerializeValue(value, level) {
            if (value is Map) {
                return this.SerializeMap(value, level)
            }

            if (value is Array) {
                return this.SerializeArray(value, level)
            }

            valueType := Type(value)
            switch valueType {
                case "String":
                    return this.SerializeString(value)
                case "Integer", "Float":
                    return value
            }

            throw TypeError("Unsupported JSON value type: " valueType)
        }

        SerializeMap(value, level) {
            if (value.Count = 0) {
                return "{}"
            }

            newline := this.indent ? "`n" : ""
            separator := this.indent ? ",`n" : ","
            parts := []

            for key, item in value {
                parts.Push(this.Indent(level + 1) this.SerializeString(key) ":" (this.indent ? " " : "") this.SerializeValue(item, level + 1))
            }

            return "{" newline this.Join(parts, separator) newline this.Indent(level) "}"
        }

        SerializeArray(value, level) {
            if (value.Length = 0) {
                return "[]"
            }

            newline := this.indent ? "`n" : ""
            separator := this.indent ? ",`n" : ","
            parts := []

            for item in value {
                parts.Push(this.Indent(level + 1) this.SerializeValue(item, level + 1))
            }

            return "[" newline this.Join(parts, separator) newline this.Indent(level) "]"
        }

        SerializeString(value) {
            escaped := StrReplace(value, "\", "\\")
            escaped := StrReplace(escaped, '"', '\"')
            escaped := StrReplace(escaped, "`r", "\r")
            escaped := StrReplace(escaped, "`n", "\n")
            escaped := StrReplace(escaped, "`t", "\t")
            return '"' escaped '"'
        }

        Join(items, separator) {
            output := ""
            for index, item in items {
                if (index > 1) {
                    output .= separator
                }
                output .= item
            }
            return output
        }

        Indent(level) {
            if !this.indent {
                return ""
            }

            padding := ""
            loop (level * this.indent) {
                padding .= " "
            }
            return padding
        }
    }
}
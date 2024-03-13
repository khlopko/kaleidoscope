// Lexer implementation for the Kaleidoscope language.
// see: https://llvm.org/docs/tutorial/MyFirstLanguageFrontend/LangImpl01.html

import Foundation

enum Token {
    case EOF
    case def
    case extern
    case identifier
    case number
    case unknown(Character)
}

struct Lexer {
    var identifierStr: String?
    var numVal: Double?
    private var lastChar: Character!

    mutating func getTok() -> Token {
        while lastChar == nil || lastChar == " " {
            getChar()
        }
        if lastChar.isLetter {
            var identifierChars: [Character] = []
            while lastChar.isLetter || lastChar.isNumber {
                identifierChars.append(lastChar)
                getChar()
            }
            identifierStr = String(identifierChars)
            if identifierStr == "def" {
                return .def
            }
            if identifierStr == "extern" {
                return .extern
            }
            return .identifier
        }
        if lastChar.isNumber || lastChar == "." {
            var numStr = ""
            var floatingPoint = false
            while lastChar.isNumber || lastChar == "." {
                if lastChar == "." {
                    if floatingPoint {
                        break
                    }
                    floatingPoint = true
                }
                numStr.append(lastChar)
                getChar()
            }
            numVal = Double(numStr)
            return .number
        }
        if lastChar == "#" {
            getChar() // step over
            // skip line
            while lastChar.isNewline && lastChar != nil {
                getChar()
            }
            if lastChar != nil {
                return getTok()
            }
        }
        if lastChar == nil {
            return .EOF
        }
        let token: Token = .unknown(lastChar)
        getChar()
        return token
    }
    
    private mutating func getChar() {
        let c = getchar()
        guard c != EOF else {
            lastChar = nil
            return
        }
        guard let scalar = Unicode.Scalar(UInt16(c)) else {
            lastChar = nil
            return
        }
        lastChar = Character(scalar)
    }
}


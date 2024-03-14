// Driver implementation

import Foundation

struct Driver {
    private var parser: Parser

    init(parser: consuming Parser) {
        self.parser = parser
    }

    mutating func mainLoop() {
        FileHandle.standardError.write("ready> ".data(using: .utf8)!)
        parser.getNextToken()
        while true {
            FileHandle.standardError.write("ready> ".data(using: .utf8)!)
            switch parser.currTok {
            case .EOF:
                return
            case .unknown(";"):
                // skip top-level semicolon
                parser.getNextToken()
                // skip newline
                parser.getNextToken()
            case .def:
                handleDef()
            case .extern:
                handleExtern()
            default:
                handleTopLevelExpr()
            }
        }
    }

    private mutating func handleDef() {
        if parser.parseDefinition() != nil {
            FileHandle.standardError.write("Parsed a function definition\n".data(using: .utf8)!)
        } else {
            parser.getNextToken()
        }
    }

    private mutating func handleExtern() {
        if parser.parseExtern() != nil {
            FileHandle.standardError.write("Parsed an extern\n".data(using: .utf8)!)
        } else {
            parser.getNextToken()
        }
    }

    private mutating func handleTopLevelExpr() {
        if parser.parseTopLevelExpr() != nil {
            FileHandle.standardError.write("Parsed a top lever expr\n".data(using: .utf8)!)
        } else {
            parser.getNextToken()
        }
    }
}

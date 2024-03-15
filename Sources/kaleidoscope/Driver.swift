// Driver implementation

import Foundation
import cllvm

struct Driver {
    private var parser: Parser
    private var codegen: Codegen

    init(parser: consuming Parser, codegen: consuming Codegen) {
        self.parser = parser
        self.codegen = codegen
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
        if let ast = parser.parseDefinition() {
            genFn(ast)
        } else {
            parser.getNextToken()
        }
    }

    private mutating func handleExtern() {
        if let ast = parser.parseExtern() {
            genProto(ast)
        } else {
            parser.getNextToken()
        }
    }

    private mutating func handleTopLevelExpr() {
        if let ast = parser.parseTopLevelExpr() {
            if let fn = genFn(ast) {
                LLVMEraseGlobalIFunc(fn)
            }
        } else {
            parser.getNextToken()
        }
    }

    private mutating func genProto(_ ast: consuming PrototypeAST) {
        if let fn = codegen.prototype(ast) {
            printLLVMValue(fn)
        }
    }

    @discardableResult
    private mutating func genFn(_ ast: consuming FunctionAST) -> LLVMValueRef? {
        guard let fn = codegen.function(ast) else {
            return nil
        }
        printLLVMValue(fn)
        return nil
    }

    private func printLLVMValue(_ value: LLVMValueRef) {
        if let str = LLVMPrintValueToString(value) {
            let data = String.init(cString: str).data(using: .utf8)!
            FileHandle.standardError.write(data)
            FileHandle.standardError.write("\n".data(using: .utf8)!)
        } else {
            FileHandle.standardError.write("Failed to print LLVM IR\n".data(using: .utf8)!)
        }
    }
}

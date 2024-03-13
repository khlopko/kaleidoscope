// AST implementation for Kaleidoscope language
// see: https://llvm.org/docs/tutorial/MyFirstLanguageFrontend/LangImpl02.html

import Foundation

protocol ExprAST {
}

struct NumberExprAST: ExprAST {
    let val: Double
}

struct VarExprAST: ExprAST {
    let name: String
}

struct BinaryOpExprAST: ExprAST {
    let op: Token
    let lhs: any ExprAST
    let rhs: any ExprAST
}

struct CallExprAST: ExprAST {
    let callee: String
    let args: [any ExprAST]
}

struct PrototypeAST {
    let name: String
    let args: [String]
}

struct FunctionAST {
    let proto: PrototypeAST
    let body: ExprAST
}

struct Parser {
    private var currTok: Token?
    private var lexer: Lexer
    private let precedence: [Character: UInt8] = [
        "<": 10,
        "+": 20,
        "-": 30,
        "*": 40,
    ]

    init(lexer: Lexer) {
        self.lexer = lexer
    }

    private func getCurrTokPrecedence() -> UInt8? {
        if case let .unknown(val) = currTok {
            return precedence[val]
        }
        return nil
    }

    private mutating func parse() -> (any ExprAST)? {
        switch currTok {
        case .identifier:
            return parseIdentifierExpr()
        case .number:
            return parseNumberExpr()
        case .unknown("("):
            return parseParenExpr()
        default: 
            return logErr("unknown token when expecting an expression")
        }
    }

    private mutating func parseExpr() -> (any ExprAST)? {
        guard let lhs = parse() else {
            return nil
        }
        return parseBinOpExpr(exprPrec: 0, lhs: lhs)
    }

    private mutating func parseBinOpExpr(exprPrec: UInt8, lhs: consuming any ExprAST) -> (any ExprAST)? {
        while true {
            guard let currPrec = getCurrTokPrecedence(), currPrec >= exprPrec else {
                return lhs
            }
            let binOp = currTok!
            getNextToken()
            guard var rhs = parse() else {
                return nil
            }
            if let nextPrec = getCurrTokPrecedence(), currPrec < nextPrec {
                guard let nextExpr = parseBinOpExpr(exprPrec: currPrec + 1, lhs: rhs) else {
                    return nil
                }
                rhs = nextExpr
            }
            lhs = BinaryOpExprAST(op: binOp, lhs: lhs, rhs: rhs)
        }
    }

    private mutating func parsePrototype() -> PrototypeAST? {
        guard case .identifier = currTok else {
            return logErrP("Expected function name in prototype")
        }
        let fnName = lexer.identifierStr!
        getNextToken()
        fatalError("Not complete")
    }

    private mutating func parseNumberExpr() -> any ExprAST {
        let result = NumberExprAST(val: lexer.numVal!)
        getNextToken()
        return result
    }

    private mutating func parseParenExpr() -> (any ExprAST)? {
        getNextToken()
        let e = parseExpr()
        if e == nil {
            return nil
        }
        guard case .unknown(")") = currTok else {
            return logErr("expected ')'")
        }
        getNextToken()
        return e
    }

    private mutating func parseIdentifierExpr() -> (any ExprAST)? {
        let idName = lexer.identifierStr!
        getNextToken()
        guard case .unknown("(") = currTok else {
            return VarExprAST(name: idName)
        }
        getNextToken()
        var args: [any ExprAST] = []
        defer {
            getNextToken()
        }
        if case .unknown(")") = currTok {
            return CallExprAST(callee: idName, args: args)
        }
        while true {
            if let e = parseExpr() {
                args.append(e)
            } else {
                return nil
            }
            if case .unknown(")") = currTok {
                break
            }
            guard case .unknown(",") = currTok else {
                return logErr("Expected ')' or ',' in argument list")
            }
            getNextToken()
        }
        return CallExprAST(callee: idName, args: args)
    }

    private func logErr(_ message: String) -> (any ExprAST)? {
        if let data = message.data(using: .ascii) {
            FileHandle.standardError.write(data)
        }
        return nil
    }

    private func logErrP(_ message: String) -> PrototypeAST? {
        if let data = message.data(using: .ascii) {
            FileHandle.standardError.write(data)
        }
        return nil
    }

    private mutating func getNextToken() {
        currTok = lexer.getTok()
    }
}

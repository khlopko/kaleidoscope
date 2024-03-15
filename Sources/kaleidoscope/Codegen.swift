//
//  Codegen.swift
//

import cllvm

struct Codegen {
    private let ctx: LLVMContextRef
    private let builder: LLVMBuilderRef
    private let module: LLVMModuleRef
    private var namedValues: [String: LLVMValueRef] = [:]

    init?() {
        guard let ctx = LLVMContextCreate() else {
            return nil
        }
        self.ctx = ctx
        guard let builder = LLVMCreateBuilderInContext(ctx) else {
            return nil
        }
        self.builder = builder
        module = LLVMModuleCreateWithNameInContext("codegen", ctx)
    }

    func number(_ ast: borrowing NumberExprAST) -> LLVMValueRef {
        LLVMConstReal(LLVMDoubleTypeInContext(ctx), ast.val)
    }

    func variable(_ ast: borrowing VarExprAST) -> LLVMValueRef? {
        namedValues[ast.name]
    }

    func binOp(_ ast: borrowing BinaryOpExprAST) -> LLVMValueRef? {
        guard let l = expr(ast.lhs), let r = expr(ast.rhs) else {
            return nil
        }
        switch ast.op {
        case .unknown("+"): 
            return LLVMBuildFAdd(builder, l, r, "addtmp")
        case .unknown("-"): 
            return LLVMBuildFSub(builder, l, r, "subtmp")
        case .unknown("*"): 
            return LLVMBuildFMul(builder, l, r, "multmp")
        case .unknown("<"):
            let cmp = LLVMBuildFCmp(builder, LLVMRealOLT, l, r, "cmptmp")
            return LLVMBuildUIToFP(builder, cmp, LLVMDoubleTypeInContext(ctx), "booltmp")
        default:
            return nil
        }
    }

    func call(_ ast: borrowing CallExprAST) -> LLVMValueRef? {
        guard let calleeF = LLVMGetNamedFunction(module, ast.callee) else {
            return nil
        }
        let expectedNumOfArgs = LLVMGetNumArgOperands(calleeF)
        if expectedNumOfArgs != ast.args.count {
            return nil
        }
        var args: [LLVMValueRef?] = ast.args.map { expr($0) }
        return LLVMBuildCall2(
            builder,
            LLVMGetCalledFunctionType(calleeF),
            calleeF,
            &args,
            expectedNumOfArgs,
            "calltmp"
        )
    }

    func prototype(_ ast: PrototypeAST) -> LLVMValueRef? {
        let doubleType = LLVMDoubleTypeInContext(ctx)
        var args = ast.args.map { _ in doubleType }
        let fnType = LLVMFunctionType(
            doubleType,
            &args,
            UInt32(ast.args.count),
            0
        )
        return LLVMAddFunction(module, ast.name, fnType)
    }
    
    // TODO: parameters match validation against IR function
    mutating func function(_ ast: FunctionAST) -> LLVMValueRef? {
        var fn = LLVMGetNamedFunction(module, ast.proto.name)
        if fn == nil {
            fn = prototype(ast.proto)
        }
        guard let fn else {
            return nil
        }
        guard let bb = LLVMAppendBasicBlockInContext(ctx, fn, "entry") else {
            return nil
        }
        namedValues = [:]
        for (i, arg) in ast.proto.args.enumerated() {
            namedValues[arg] = LLVMGetParam(fn, UInt32(i))
        }
        LLVMPositionBuilderAtEnd(builder, bb)
        guard let value = expr(ast.body) else {
            LLVMEraseGlobalIFunc(fn)
            return nil
        }
        LLVMBuildRet(builder, value)
        return fn
    }

    // TODO: convert to enum?
    func expr(_ ast: any ExprAST) -> LLVMValueRef? {
        switch ast {
        case let ast as NumberExprAST: return number(ast)
        case let ast as VarExprAST: return variable(ast)
        case let ast as BinaryOpExprAST: return binOp(ast)
        case let ast as CallExprAST: return call(ast)
        default: return nil
        }
    }
}

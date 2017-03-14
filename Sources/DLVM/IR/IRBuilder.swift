//
//  IRBuilder.swift
//  DLVM
//
//  Created by Richard Wei on 12/18/16.
//
//

open class IRBuilder {

    open let module: Module

    open fileprivate(set) weak var currentBlock: BasicBlock? {
        didSet {
            currentFunction = currentBlock?.parent
        }
    }

    open weak var currentFunction: Function? {
        didSet {
            if oldValue !== currentFunction {
                variableNameId = 0
            }
        }
    }

    fileprivate var variableNameId = 0

    public init(module: Module) {
        self.module = module
    }

}

public extension IRBuilder {

    convenience init(moduleName: String) {
        self.init(module: Module(name: moduleName))
    }

    convenience init(function: Function) {
        self.init(module: function.parent)
    }

    convenience init(basicBlock: BasicBlock) {
        self.init(module: basicBlock.module)
        move(to: basicBlock)
    }

}

// MARK: - Helpers
extension IRBuilder {

    func makeVariableName(in function: Function) -> String {
        defer { variableNameId += 1 }
        return disambiguatedName(for: "v\(variableNameId)", in: function)
    }

    func disambiguatedName(for name: String, in function: Function, id: Int = 0) -> String {
        let newName = id == 0 ? name : name + ".\(id)"
        return function.containsName(newName)
             ? disambiguatedName(for: name, in: function, id: id + 1)
             : newName
    }

}

// MARK: - Main builder API
extension IRBuilder {

    @discardableResult
    open func define(_ value: GlobalValue) -> Use {
        module.insert(value)
        let use = Use(kind: .global(value))
        return use
    }

    open func makeLiteral(_ literal: Literal, shape: TensorShape, type: DataType) -> Use {
        return makeLiteral(LiteralValue(shape: shape, dataType: type, literal: literal))
    }

    open func makeLiteral(_ literalValue: LiteralValue) -> Use {
        return Use(kind: .literal(literalValue))
    }

    @discardableResult
    open func buildFunction(named name: String,
                            arguments: [(String, Type)],
                            result: Type = .void,
                            isDifferentiable: Bool) -> Function {
        let fun = Function(name: name,
                           arguments: arguments, 
                           result: result,
                           isDifferentiable: isDifferentiable,
                           parent: module)
        module.append(fun)
        return fun
    }

    @discardableResult
    open func buildBasicBlock(named name: String,
                              arguments: [(String, Type)],
                              in function: Function) -> BasicBlock {
        let newName = disambiguatedName(for: name, in: function)
        let block = BasicBlock(name: newName, arguments: arguments, parent: function)
        function.append(block)
        return block
    }

    @discardableResult
    open func buildInstruction(_ kind: InstructionKind, name: String? = nil) -> Use {
        let block = currentBlock!
        let function = block.parent
        let inst = Instruction(name: kind.type.isVoid ? nil : (name ?? makeVariableName(in: function)),
                               kind: kind, parent: block)
        let use = Use(kind: .local(inst))
        return use
    }
}

// MARK: - Positioning
extension IRBuilder {

    open func move(to basicBlock: BasicBlock?) {
        currentBlock = basicBlock
    }

}

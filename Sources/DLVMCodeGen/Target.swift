//
//  Target.swift
//  DLVM
//
//  Copyright 2016-2017 Richard Wei.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import LLVM_C

public protocol LLFunctionPrototype: Hashable {
    var name: StaticString { get }
    var type: LLVMTypeRef { get }
    var arguments: [LLVMValueRef] { get }
}

public protocol LLTypePrototype: Hashable {
    var name: StaticString { get }
    var type: LLVMTypeRef { get }
}

public extension LLFunctionPrototype {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.name.utf8Start == rhs.name.utf8Start
    }
    
    var hashValue: Int {
        return name.utf8Start.hashValue
    }
}

public extension LLFunctionPrototype where Self : RawRepresentable, Self.RawValue == StaticString {
    var name: StaticString {
        return rawValue
    }
}

public extension LLTypePrototype where Self : RawRepresentable, Self.RawValue == StaticString {
    var name: StaticString {
        return rawValue
    }

    // Opaque by default
    public var type: LLVMTypeRef {
        return StructType(name: name.description)
    }
}

import DLVM

public protocol LLTarget : LLFunctionPrototypeCacheable {
    var module: LLVMModuleRef { get }
    init(module: LLVMModuleRef)
}

public protocol LLFunctionPrototypeCacheable : class {
    var functions: [AnyHashable : LLVMValueRef] { get set }
    func function<T : LLFunctionPrototype>(from prototype: T) -> LLVMValueRef
}

extension StaticString : Equatable {
    public static func == (lhs: StaticString, rhs: StaticString) -> Bool {
        return lhs.utf8Start == rhs.utf8Start
    }
}

extension LLTarget where Self : LLFunctionPrototypeCacheable {
    func emit<T : LLFunctionPrototype>(_ prototype: T,
                                       using builder: LLVM.IRBuilder,
                                       name: String = "") -> LLVMValueRef {
        let function = self.function(from: prototype)
        return builder.buildCall(function, args: prototype.arguments, name: name)
    }
}

extension LLFunctionPrototypeCacheable where Self : LLTarget {
    public func function<T : LLFunctionPrototype>(from prototype: T) -> LLVMValueRef {
        if let fun = functions[prototype] {
            return fun
        }
        let builder = IRBuilder(module: module)
        let fun = builder.addFunction(prototype.name.description,
                                      type: prototype.type)
        functions[prototype] = fun
        return fun
    }
}

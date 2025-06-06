//
//  PropertyInfo.swift
//  swift-codable-macro
//
//  Created by SerikaPHB  on 2025/1/28.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation



struct PropertyInfo: Sendable, Equatable, Hashable {
    
    var name: TokenSyntax
    var type: PropertyType
    var initializer: ExprSyntax?
    var dataType: TypeSyntax?
    var attributes: [AttributeSyntax]
    
    var hasOptionalTypeDecl: Bool { dataType?.is(OptionalTypeSyntax.self) == true }
    var nameStr: String { name.text }
    var isRequired: Bool { type != .computed && initializer == nil && !hasOptionalTypeDecl }
    var typeExpression: ExprSyntax? {
        if let dataType {
            "\(dataType).self"
        } else if let initializer {
            "CodableMacro.codableMacroStaticType(of: \(initializer))"
        } else {
            nil
        }
    }
    
}



extension PropertyInfo {
    
    enum PropertyType: Sendable, Equatable, Hashable {
        case constant
        case stored
        case computed
    }
    
}



extension PropertyInfo {
    
    static func extract(from declaration: VariableDeclSyntax) throws(DiagnosticsError) -> PropertyInfo {
        
        let attributes = declaration.attributes.compactMap { $0.as(AttributeSyntax.self) }
        
        guard let name = declaration.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier else {
            throw .diagnostic(node: declaration, message: .syntaxInfo.property.missingIdentifier)
        }
        
        let initializer = declaration.bindings.first?.initializer?.value
        
        let typeAnnotation = declaration.bindings.first?.typeAnnotation?.type
        
        let type: PropertyType
        
        if declaration.bindingSpecifier.tokenKind == .keyword(.let) {
            type = .constant
        } else if initializer != nil {
            type = .stored
        } else if let accessors = declaration.bindings.first?.accessorBlock?.accessors {
            if let accessors = accessors.as(AccessorDeclListSyntax.self) {
                let isComputed = accessors.isEmpty || accessors.lazy
                    .map { $0.accessorSpecifier.tokenKind }
                    .contains { $0 == .keyword(.get) || $0 == .keyword(.set) }
                type = isComputed ? .computed : .stored
            } else {
                type = .computed
            }
        } else {
            type = .stored
        }
        
        return .init(
            name: name,
            type: type,
            initializer: initializer,
            dataType: typeAnnotation?.trimmed,
            attributes: attributes
        )
        
    }
    
    
    enum Error {
        static let missingIdentifier: SyntaxInfoDiagnosticMessage = .init(
            id: "missing_identifier",
            message: "Missing identifier for property"
        )
    }
    
}



extension SyntaxInfoDiagnosticMessageGroup {
    static var property: PropertyInfo.Error.Type { PropertyInfo.Error.self }
}

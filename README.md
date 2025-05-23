# swift-codable-macro

Provide Swift Macros for automatically generate customizable implementation for conforming `Codable` protocol. 

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FStar-Lord-PHB%2Fswift-codable-macro%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/Star-Lord-PHB/swift-codable-macro) [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FStar-Lord-PHB%2Fswift-codable-macro%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/Star-Lord-PHB/swift-codable-macro)

## Introduction 

Swift Compiler already provides auto implementation when we conform a custom type to `Codable`. It is nice when you are in charge of defining the encoding / decoding format, but unfortunately, that is not always the case. When the format is defined by others, we might have to use wired property name or even implement `encode(to:)` and `init(:from)` ourselves. 

Such problem usually occurs when using an REST API provided by some third parties. For example, we might expect a `Person` struct to be something like this: 

```swift
public struct Person: Codable {
    var id: String
    var name: String 
    var age: Int
}
```

However, the response body of the REST API might, for some reason, be something like this: 

```json
{
    "data": {
        "id": "9F6E1D7A-EF6A-4F7A-A1E0-46105DD31F3E",
        "meta": {
            "name": "Serika",
            "age": 15
        }
    }
}
```

In this case, we have to implement the conformance to `Codable` ourselves. 

To handle such situation in a "swifter" way, the `swift-codable-macro` is here to help. For the example above, we can how declare the `Person` Struct like this: 

```swift
@Codable
public struct Person {
    @CodingField("data", "id")
    var id: String
    @CodingField("data", "meta", "name")
    var name: String 
    @CodingField("data", "meta", "age")
    var age: Int
}
```

Done! The `Codable` conformance and implementation of `encode(to:)` and `init(from:)` will be generated automatically! No other additional implementation code required! 

This is not all the capability of this package. The following codes provide a brief view of what it can do. 

```swift
@Codable
struct Person {
    
    @CodingField("data", "uid")
    @DecodeTransform(source: String.self, with: { UUID(uuidString: $0)! })
    @EncodeTransform(source: UUID.self, with: \.uuidString)
    var id: UUID
    
    @CodingField("data", "meta", "name")
    @CodingValidate(source: String.self, with: { !$0.isEmpty })
    @CodingValidate(source: String.self, with: { !$0.contains(where: { $0.isNumber }) })
    var name: String 
    
    @CodingField("data", "meta", "gender", onMissing: .male, onMismatch: .female)
    let gender: Gender
    
    @CodingField("data", "meta", "birth", default: .distancePast)
    @CodingTransform(
        .doubleDateTransform, 
        .doubleTypeTransform(option: .string)
    )
    var birthday: Date
    
    @CodingField("data", "meta", "known_programming_languages")
    @SequenceCodingField(
        subPath: "name", 
        onMissing: .ignore, 
        onMismatch: .value("Swift"),
        decodeTransform: Set.init
    )
    var knownProgrammingLanguages: Set<String>
    
    @CodingIgnore
	var habit: String = "writing Swift Macro"
    
}

@SingleValueCodable
struct FilePath {
    @SingleValueCodableDelegate
    var storage: String
    var isDir: Bool = false 
}
```

## Provided Macros

**Codable(inherit:)**

Annotate a class or a struct for auto conforming to `Codable` protocol. It will look up all the stored properties in the type definition and generate the implementation base on any customization found. 

**CodingField(_:default:)**

Specify a custom coding path and a default value for a stored property. If the coding path is not provided, the name of the property will be used. The default value is not required to be set using the `default` parameter, you can also provide a standard initializer for the property or use an optional type. The macro is able to take that into account. 

**CodingField(_:onMissing:onMismatch:)**

Similar to `CodingField(_:default:)`, but it allow specifying separate default values for value missing and type mismatch. 

**CodingIgnore**

Make a stored property to be ignored when doing encoding / decoding. It requires that property to be optional or has a standard initializer. 

**DecodeTransform(source:with:)**

Specify a custom transformation when decoding for a property.  It will first try to decode the value to the provided `sourceType`, then convert it using the provided transformation. 

**EncodeTransform(source:with:)**

Specify a custom transformation when encoding a property. It will first convert the value using the provided transformation, then encoded the converted value. 

**CodingTransform(_\:)**

Specify a sequence of transformations when encoding / decoding a property. The transformations here should be instances of types that conform to `EvenCodingTransformProtocol`. 

* When encoding the property, the transformations will be used in order
* When decoding the property, the transformations will be used in reversed-order 

**CodingValidate(source:with:)**

Specify a validation rules when decoding for a property. 

**SequenceCodingField(subPath:elementEncodedType:onMissing:onMismatch:decodeTransform:encodeTransform)**

Specify a custom behavior when decoding an encoded sequence (e.g.: JSON Array). Can specify sub path when decoding each element in the sequence and default behavior (ignore it or apply a default value) when an element cannot be decoded correctly.

**SingleValueCodable(inherit:)**

Annotate a Class or a struct for auto conforming to `Codable` protocol by a provided rule to convert an instance from/to an instance of another type that conforms to `Codable`. 

The rule can be provided by: 

* Implement `singleValueEncode()` and `init(from:)`
* Annotate one of the stored property with `SingleValueCodableDelegate` macro 

**SingleValueCodableDelegate**

Used together with `SingleValueCodable`, mark a property as the only target for encoding and decoding. 

## Installation 

In `Package.swift`, add the following line into your dependencies: 

```swift
.package(url: "https://github.com/Star-Lord-PHB/swift-codable-macro.git", from: "2.0.0")
```

Add `CodableMacro` as a dependency of your target:

```swift
.target(
    name: "Target", 
    dependencies: [
        .product(name: "CodableMacro", package: "swift-codable-macro"),
    ]
)
```

Add `import CodableMacro` in your source code. 
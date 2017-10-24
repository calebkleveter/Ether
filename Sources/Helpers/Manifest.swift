// The MIT License (MIT)
//
// Copyright (c) 2017 Caleb Kleveter
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

public class Manifest {
    public static let current = Manifest()
    private let fileManager = FileManager.default
    
    private init() {}
    
    /// Gets the name of the package that has a specefied URL by reading the `Package.resolved` file data.
    ///
    /// - Parameters:
    ///   - url: The URL of the package that the name is to get fetched from.
    ///   - fileManager: A file manager to use get the current directory path.
    /// - Returns: The name of the package that was found.
    /// - Throws: An error is thrown if either, 1) The data in the Package.resolved file is corrupted, or 2) A package does not exist with the URL passed in
    public func getPackageName(`for` url: String)throws -> String {
        guard let resolvedURL = URL(string: "file:\(fileManager.currentDirectoryPath)/Package.resolved") else {
            throw EtherError.fail("Bad path to package data. Make sure you are in the project root.")
        }
        let packageData = try Data(contentsOf: resolvedURL).json()
        
        guard let object = packageData?["object"] as? JSON,
            let pins = object["pins"] as? [JSON] else { throw EtherError.fail("Unable to read Package.resolved") }
        
        guard let package = try pins.filter({ (json) -> Bool in
            guard let repoURL = json["repositoryURL"] as? String else {
                throw EtherError.fail("Unable to read Package.resolved")
            }
            return repoURL == url
        }).first else {
            throw EtherError.fail("Unable to read Package.resolved")
        }
        
        guard let name = package["package"] as? String else {
            throw EtherError.fail("Unable to read Package.resolved")
        }
        
        return name
    }
}

extension NSMutableString {
    
    /// Adds a package dependency to a target in a package manifest file.
    ///
    /// - Parameters:
    ///   - dependency: The name of the dependency that will be added to a target.
    ///   - target: The target the dependency will be added to.
    ///   - packageData: The contents of the package manifest file.
    /// - Returns: The package manifest with the dependency added to the target.
    /// - Throws: Any errors that originate when creating an `NSRegularExpression`.
    public func addDependency(_ dependency: String, to target: String)throws {
        let targetPattern = try NSRegularExpression(pattern: "\\.(testT|t)arget\\(\\s*name:\\s\"(.*?)\".*?(\\)|\\])\\)", options: .dotMatchesLineSeparators)
        let dependenciesPattern = try NSRegularExpression(pattern: "(dependencies:\\s*\\[\\n?(\\s*).*?(\"|\\))),?\\s*\\]", options: .dotMatchesLineSeparators)
        let targetMatches = targetPattern.matches(in: String(self), options: [], range: NSMakeRange(0, self.length))
        
        guard let targetRange: NSRange = targetMatches.map({ (match) -> (name: String, range: NSRange) in
            let name = targetPattern.replacementString(for: match, in: self as String, offset: 0, template: "$2")
            let range = match.range
            return (name: name, range: range)
        }).filter({ (name: String, range: NSRange) -> Bool in
            return name == target
        }).first?.1 else { throw EtherError.fail("Attempted to add a dependency to a non-existent target") }
        
        dependenciesPattern.replaceMatches(in: self, options: [], range: targetRange, withTemplate: "$1, \"\(dependency)\"]")
    }
}
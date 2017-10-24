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

import Helpers
import Console
import Foundation
import Core

public final class Install: Command {
    public let id = "install"
    public let baseURL = "https://packagecatalog.com/data/package/"
    
    public let signature: [Argument] = [
        Value(name: "name", help: [
            "The name of the package that will be installed"
        ]),
        Option(name: "url", help: [
            "The URL for the package"
        ]),
        Option(name: "version", help: [
            "The desired version for the package",
            "This defaults to the latest version"
        ])
    ]
    
    public var help: [String] = [
        "Installs a package into the current project"
    ]
    
    public let console: ConsoleProtocol
    public let client = PackageJSONFetcher()
    
    public init(console: ConsoleProtocol) {
        self.console = console
    }
    
    public func run(arguments: [String]) throws {
        console.output("Reading Package Targets...", style: .info, newLine: true)
        
        let fileManager = FileManager.default
        let name = try value("name", from: arguments)
        let installBar = console.loadingBar(title: "Installing Dependency")
        
        // Get package manifest and JSON data
        guard let manifestURL = URL(string: "file:\(fileManager.currentDirectoryPath)/Package.swift") else {
            throw EtherError.fail("Bad path to package manifest. Make sure you are in the project root.")
        }
        guard let resolvedURL = URL(string: "file:\(fileManager.currentDirectoryPath)/Package.resolved") else {
            throw EtherError.fail("Bad path to package data. Make sure you are in the project root.")
        }
        let packageManifest = try String(contentsOf: manifestURL)
        var packageData = try Data(contentsOf: resolvedURL).json()
        var mutablePackageManifest = NSMutableString(string: packageManifest)
        
        // Get the names of the targets to add the dependency to
        let targets = try getTargets(fromManifest: packageManifest)
        let useTargets: [String] = inquireFor(targets: targets)
        
        installBar.start()
        
        let packageInstenceRegex = try NSRegularExpression(pattern: "(\\.package([\\w\\s\\d\\,\\:\\(\\)\\@\\-\\\"\\/\\.])+\\)),?(?:\\R?)", options: .anchorsMatchLines)
        let dependenciesRegex = try NSRegularExpression(pattern: "products: *\\[(?s:.*?)\\],\\s*dependencies: *\\[", options: .anchorsMatchLines)
        
        // Get the data for the package to install
        let newPackageData = try getPackageData(from: "https://packagecatalog.com/api/search/\(name)")
        let packageInstance = "$1,\n        .package(url: \"\(newPackageData.url)\", .exact(\"\(newPackageData.version)\"))\n"
        
        // Add the new package instance to the Package dependencies array.
        if packageInstenceRegex.matches(in: packageManifest, options: [], range: NSMakeRange(0, packageManifest.utf8.count)).count > 0  {
            packageInstenceRegex.replaceMatches(in: mutablePackageManifest, options: [], range: NSMakeRange(0, mutablePackageManifest.length), withTemplate: packageInstance)
        } else {
            dependenciesRegex.replaceMatches(in: mutablePackageManifest, options: [], range: NSMakeRange(0, mutablePackageManifest.length), withTemplate: packageInstance)
        }
        
        // Write the new package manifest to the Package.swift file
        try String(mutablePackageManifest).data(using: .utf8)?.write(to: URL(string: "file:\(fileManager.currentDirectoryPath)/Package.swift")!)
        
        // Update the packages.
        _ = try console.backgroundExecute(program: "swift", arguments: ["package", "update"])
        _ = try console.backgroundExecute(program: "swift", arguments: ["package", "resolve"])
        
        // Get the new package name and add it to the previously accepted targets.
        let dependencyName = try self.getPackageName(for: newPackageData.url, with: fileManager)
        for target in useTargets {
            mutablePackageManifest = try addDependency(dependencyName, to: target, inManifest: mutablePackageManifest)
        }
        
        // Write the Package.swift file again
        try String(mutablePackageManifest).data(using: .utf8)?.write(to: URL(string: "file:\(fileManager.currentDirectoryPath)/Package.swift")!)
        
        _ = try console.backgroundExecute(program: "swift", arguments: ["package", "update"])
        
        // Calculate the number of package that where installed and output it.
        guard let oldObject = packageData?["object"] as? JSON,
              let oldPins = oldObject["pins"] as? [JSON] else { return }
        
        packageData = try Data(contentsOf: resolvedURL).json()
        guard let object = packageData?["object"] as? JSON,
              let pins = object["pins"] as? [JSON] else { return }
        
        let newPackageCount = pins.count - oldPins.count
        
        installBar.finish()
        console.output("📦  \(newPackageCount) packages installed", style: .plain, newLine: true)
    }
    
    /// Gets that names of all the current projects targets.
    ///
    /// - Parameter packageData: The contents of the package manifest file.
    /// - Returns: All the target names.
    /// - Throws: Any errors that occur while creating an `NSRegularExpression` to match targets against.
    fileprivate func getTargets(fromManifest packageData: String)throws -> [String] {
        let targetPattern = try NSRegularExpression(pattern: "\\.(testT|t)arget\\(\\s*name:\\s\"(.*?)\".*?(\\)|\\])\\)", options: NSRegularExpression.Options.dotMatchesLineSeparators)
        let targetMatches = targetPattern.matches(in: packageData, options: [], range: NSMakeRange(0, packageData.utf8.count))
        
        let targetNames = targetMatches.map { (match) in
            return targetPattern.replacementString(for: match, in: packageData, offset: 0, template: "$2")
        }
        
        return targetNames
    }
    
    /// Asks the user if they want to add a dependency to the targets in the package manifest.
    ///
    /// - Parameter targets: The names of the targets available.
    /// - Returns: The names of the targets that where accepted.
    fileprivate func inquireFor(targets: [String]) -> [String] {
        var acceptedTargets: [String] = []
        var index = 0
        
        if targets.count > 1 {
            targetFetch: while index < targets.count {
                let target = targets[index]
                let response = console.ask("Would you like to add the package to the target '\(target)'? (y,n,q,?)")
                
                switch response {
                case "y":
                    acceptedTargets.append(target)
                    index += 1
                case "n":
                    index += 1
                case "q":
                    break targetFetch
                default: console.output("""
                y: Add the package as a dependency to the target.
                n: Do not add the package as a dependency to the target.
                q: Do not add the package as a dependency to the current target or any of the following targets.
                ?: Output this message.
                """, style: .info, newLine: true)
                }
            }
        } else {
            acceptedTargets.append(targets[0])
        }
        
        return acceptedTargets
    }
    
    /// Gets the URL and version of a package from the IBM package catalog API on a search URL.
    ///
    /// - Parameter url: The search URL for the IBM package catalog: `https://packagecatalog.com/api/search/{name}`
    /// - Returns: The URL and version of the first resulting package in the search.
    /// - Throws: Any errors that occur while fetching the JSON, or unwrapping the package data.
    fileprivate func getPackageData(from url: String)throws -> (url: String, version: String) {
        let packageUrl: String
        let version: String
        
        if url.contains("/") {
            let clientUrl = "https://packagecatalog.com/data/package/\(url)"
            let json = try client.get(from: clientUrl, withParameters: [:])
            guard let ghUrl = json["ghUrl"] as? String,
                  let packageVersion = json["version"] as? String else {
                    throw EtherError.fail("Bad JSON")
            }
            
            packageUrl = ghUrl
            version = packageVersion
        } else {
            let clientUrl = "https://packagecatalog.com/api/search/\(url)"
            let json = try client.get(from: clientUrl, withParameters: ["items": "1", "chart": "moststarred"])
            guard let data = json["data"] as? JSON,
                  let hits = data["hits"] as? JSON,
                  let results = hits["hits"] as? [JSON],
                  let source = results[0]["_source"] as? JSON else {
                    throw EtherError.fail("Bad JSON")
            }
            
            packageUrl = String(describing: source["git_clone_url"]!)
            version = String(describing: source["latest_version"]!)
        }
        
        return (url: packageUrl, version: version)
    }
    
    /// Adds a package dependency to a target in a package manifest file.
    ///
    /// - Parameters:
    ///   - dependency: The name of the dependency that will be added to a target.
    ///   - target: The target the dependency will be added to.
    ///   - packageData: The contents of the package manifest file.
    /// - Returns: The package manifest with the dependency added to the target.
    /// - Throws: Any errors that originate when creating an `NSRegularExpression`.
    fileprivate func addDependency(_ dependency: String, to target: String, inManifest packageData: NSMutableString)throws -> NSMutableString {
        let targetPattern = try NSRegularExpression(pattern: "\\.(testT|t)arget\\(\\s*name:\\s\"(.*?)\".*?(\\)|\\])\\)", options: .dotMatchesLineSeparators)
        let dependenciesPattern = try NSRegularExpression(pattern: "(dependencies:\\s*\\[\\n?(\\s*).*?(\"|\\))),?\\s*\\]", options: .dotMatchesLineSeparators)
        let targetMatches = targetPattern.matches(in: String(packageData), options: [], range: NSMakeRange(0, packageData.length))
        let replacementString = packageData
        
        guard let targetRange: NSRange = targetMatches.map({ (match) -> (name: String, range: NSRange) in
            let name = targetPattern.replacementString(for: match, in: packageData as String, offset: 0, template: "$2")
            let range = match.range
            return (name: name, range: range)
        }).filter({ (name: String, range: NSRange) -> Bool in
            return name == target
        }).first?.1 else { throw EtherError.fail("Attempted to add a dependency to a non-existent target") }
        
        dependenciesPattern.replaceMatches(in: replacementString, options: [], range: targetRange, withTemplate: "$1, \"\(dependency)\"]")
        
        return replacementString
    }
    
    /// Gets the name of the package that has a specefied URL by reading the `Package.resolved` file data.
    ///
    /// - Parameters:
    ///   - url: The URL of the package that the name is to get fetched from.
    ///   - fileManager: A file manager to use get the current directory path.
    /// - Returns: The name of the package that was found.
    /// - Throws: An error is thrown if either, 1) The data in the Package.resolved file is corrupted, or 2) A package does not exist with the URL passed in
    fileprivate func getPackageName(`for` url: String, with fileManager: FileManager)throws -> String {
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












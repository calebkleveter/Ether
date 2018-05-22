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
import Helpers
import Command

public final class Template: Command {
    public var arguments: [CommandArgument] = [
        CommandArgument.argument(name: "name", help: ["The name used to identify the template"])
    ]
    
    public var options: [CommandOption] = [
        CommandOption.flag(name: "remove", short: "r", help: ["Deletes the template"])
        // TODO: Add `github` flag to create remote repo and push.
    ]
    
    public var help: [String] = ["Creates and stores a template for use as the starting point of a project."]
    
    public init() {}
    
    public func run(using context: CommandContext) throws -> EventLoopFuture<Void> {
        let name = try context.argument("name")
        let removeTemplate = context.options["remove"] == nil ? false : true
        let manager = FileManager.default
        let barTitle = removeTemplate ? "Deleting Template" : "Saving Template"
        
        let temapletBar = context.console.loadingBar(title: barTitle)
        _ = temapletBar.start(on: context.container)
        
        let user = try Process.execute("whoami")
        try FileManager.default.createDirectory(
            at: URL(string: "file:/Users/\(user)/Library/Application%20Support/Ether/Templates")!,
            withIntermediateDirectories: true,
            attributes: [:]
        )
        
        var isDir : ObjCBool = true
        let directoryExists = manager.fileExists(atPath: "/Users/\(user)/Library/Application Support/Ether/Templates/\(name)", isDirectory: &isDir)

        if removeTemplate {
            if !directoryExists { throw EtherError(identifier: "templateNotFound", reason: "No template with the name '\(name)' was found") }
            _ = try Process.execute("rm", ["-rf", "/Users/\(user)/Library/Application Support/Ether/Templates/\(name)"])
        } else {
            if directoryExists { throw EtherError(identifier: "templateAlreadyExists", reason: "A template with the name '\(name)' was found") }
            let current = manager.currentDirectoryPath + "/."
            _ = try Process.execute("cp", ["-a", "\(current)", "/Users/\(user)/Library/Application Support/Ether/Templates/\(name)"])
        }
        
        temapletBar.succeed()
        return context.container.eventLoop.newSucceededFuture(result: ())
    }
}

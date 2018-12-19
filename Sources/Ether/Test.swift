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
import Command

public final class Test: Command {
    public var arguments: [CommandArgument] = []
    
    public var options: [CommandOption] = [
        CommandOption.value(name: "case", short: "c", help: [
            "Specifies the test case to run. Valid values look like this:",
            "- `EtherTests`",
            "- `EtherTests.EtherTests`",
            "- `EtherTests.EtherTests.testSomething"
        ]),
        CommandOption.flag(name: "verbose", short: "v", help: ["Outputs raw stdout from `swift test`"]),
        CommandOption.flag(name: "release", short: "r", help: ["Runs tests in release mode"])
    ]
    
    public var help: [String] = ["Runs `swift test` with formated output"]
    
    public init() {}
    
    public func run(using context: CommandContext) throws -> EventLoopFuture<Void> {
        var command = ["test"]
        if let `case` = context.options["case"] {
            let filters = `case`.split(separator: ".").map(String.init)
            if filters.count < 3 {
                command.append(contentsOf: ["--filter", `case`])
            } else {
                let filter = filters[0] + "." + filters[1] + "/" + filters[2]
                command.append(contentsOf: ["--filter", filter])
            }
        }
        
        let stdout = self.output()
        let exit = Process.asyncExecute("swift", command, on: context.container) { output in
            switch output {
            case let .stdout(data): self.log(data, on: context, with: stdout)
            case let .stderr(data): self.log(data, on: context, with: stdout)
            }
        }
        
        return exit.transform(to: ())
    }
    
    private func log(_ data: Data, on context: CommandContext, with stdout: (String) -> ConsoleText?) {
        guard let value = String(data: data, encoding: .utf8) else { return }
        
        if context.options["verbose"] == nil {
            value.split(separator: "\n").map(String.init).forEach { text in
                if let text = stdout(text) {
                    context.console.output(text, newLine: false)
                }
            }
        } else {
            context.console.print(value, newLine: false)
        }
    }
    
    private func output() -> (String) -> (ConsoleText?) {
        var compiling = false
        var suiteSuccess = false
        var error: String? = nil
        var measure: String? = nil
        
        let building = try! NSRegularExpression(pattern: "^(Compile|Linking)", options: [])
        let testSuiteStart = try! NSRegularExpression(pattern: "Test Suite '(.*?)(?:.xctest)?' started at (.*)", options: [])
        let testSuiteComplete = try! NSRegularExpression(pattern: "Test Suite '(.*?)(?:.xctest)?' (passed|failed) at (.*)", options: [])
        let testSuiteCompleteData = try! NSRegularExpression(
            pattern: "\\h+Executed (\\d+) tests, with (\\d+) failure \\((\\d+) unexpected\\) in (.+?) \\(.+?\\) seconds",
            options: []
        )
        let testCaseCompleted = try! NSRegularExpression(pattern: "^Test Case '-\\[(.*?) (.*?)\\]' (passed|failed) \\((.*?) seconds\\).", options: [])
        let testError = try! NSRegularExpression(pattern: ".*?\\.swift:\\d+: error: -\\[(.*?) (.*?)\\] : (.*)", options: [])
        let unknownError = try! NSRegularExpression(pattern: "<unknown>:0: error: -\\[(.*?) (.*?)\\] : (.*)", options: [])
        let testMeasure = try! NSRegularExpression(
            pattern: "^.*?\\.swift:\\d+: Test Case '-\\[(.*?) (.*?)\\]' measured \\[Time, seconds\\] average: (.*?), relative standard deviation: (.*?), values: \\[(.*?)\\], performanceMetricID:com.apple.XCTPerformanceMetric_WallClockTime, baselineName: \"(.*?)\", baselineAverage: (.*?), maxPercentRegression: (.*?), maxPercentRelativeStandardDeviation: (.*?), maxRegression: (.*?), maxStandardDeviation: (.*?)",
            options: []
        )
        let fatal = try! NSRegularExpression(pattern: "Fatal error: (.*)", options: [])
        
        func text(for test: String) -> ConsoleText? {
            if building.matches(in: test, options: [], range: test.range).count > 0 && compiling == false {
                compiling = true
                let output = ConsoleTextFragment(string: "Building...\n", style: ConsoleStyle(color: .brightBlack, background: nil, isBold: false))
                return [output]
                
            } else if let start = testSuiteStart.matches(in: test, options: [], range: test.range).first {
                let suite = test.substring(at: start.range(at: 1)) ?? "N/A"
                
                let running = ConsoleTextFragment(string: "Running ", style: ConsoleStyle(color: .brightBlack, background: nil, isBold: false))
                let name = ConsoleTextFragment(string: suite, style: ConsoleStyle(color: .brightBlack, background: nil, isBold: true))
                let ssuite = ConsoleTextFragment(string: " Suite\n", style: ConsoleStyle(color: .brightBlack, background: nil, isBold: false))
                
                suiteSuccess = false
                return [running, name, ssuite]
                
            } else if let complete = testCaseCompleted.matches(in: test, options: [], range: test.range).first {
                let name = test.substring(at: complete.range(at: 2)) ?? "N/A"
                let time = test.substring(at: complete.range(at: 4)) ?? "N/A"
                let success = test.substring(at: complete.range(at: 3)) ?? "failed"
                let background: ConsoleColor = success == "passed" ? .custom(r: 66, g: 147, b: 68) : .custom(r: 209, g: 50, b: 39)
                
                let bullet = ConsoleTextFragment(string: "\n  - ", style: ConsoleStyle(color: .brightBlack, background: nil, isBold: false))
                let status = ConsoleTextFragment(
                    string: success == "passed" ? " v " : " x ",
                    style: ConsoleStyle(color: .white, background: background, isBold: true)
                )
                let text = ConsoleTextFragment(string: " " + name, style: ConsoleStyle(color: .brightBlack, background: nil, isBold: true))
                let data = ConsoleTextFragment(string: " \(success) in \(time) seconds\(measure ?? ".") \(error ?? "")\n", style: ConsoleStyle(color: .brightBlack, background: nil, isBold: false))
                
                error = nil
                measure = nil
                
                return [bullet, status, text, data]
                
            } else if let testMeasure = testMeasure.matches(in: test, options: [], range: test.range).first {
                let average = test.substring(at: testMeasure.range(at: 3))
                measure = average == nil ? "." : ". Average measured time is \(average!) sec."
                return nil
                
            } else if let testError = testError.matches(in: test, options: [], range: test.range).first {
                let message = test.substring(at: testError.range(at: 3))
                error = message == nil ? "\n" : "\n    \(message!)"
                return nil
                
            } else if let uknownError = unknownError.matches(in: test, options: [], range: test.range).first {
                let message = test.substring(at: uknownError.range(at: 3))
                error = message == nil ? "\n" : "\n    \(message!)"
                return nil
                
            } else if let complete = testSuiteComplete.matches(in: test, options: [], range: test.range).first {
                let suite = test.substring(at: complete.range(at: 1)) ?? "N/A"
                let success = test.substring(at: complete.range(at: 2)) ?? "failed"
                
                let name = ConsoleTextFragment(string: !suiteSuccess ? "\n" + suite : suite, style: ConsoleStyle(color: .brightBlack, background: nil, isBold: true))
                let message = ConsoleTextFragment(string: " suite \(success)\n", style: ConsoleStyle(color: .brightBlack, background: nil, isBold: false))
                
                suiteSuccess = true
                return [name, message]
                
            } else if let complete = testSuiteCompleteData.matches(in: test, options: [], range: test.range).first {
                let run = test.substring(at: complete.range(at: 1)) ?? "0"
                let failed = test.substring(at: complete.range(at: 2)) ?? "0"
                
                let output = ConsoleTextFragment(
                    string: "  - Finished with \(failed) out of \(run) test cases failing\n",
                    style: ConsoleStyle(color: .brightBlack, background: nil, isBold: false)
                )
                return [output]
                
            } else if let fatal = fatal.matches(in: test, options: [], range: test.range).first {
                return [
                    ConsoleTextFragment(string: "Fatal Error: ", style: ConsoleStyle(color: .brightRed, background: nil, isBold: true)),
                    ConsoleTextFragment(string: test.substring(at: fatal.range(at: 1)) ?? "")
                ]
            } else {
                return nil
            }
        }
        
        return text
    }
}

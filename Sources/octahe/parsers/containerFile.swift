//
//  file.swift
//  
//
//  Created by Kevin Carter on 6/4/20.
//

import Foundation

enum FileParserError: Error {
    case fileReadFailure(filePath: String)
}

struct LineIterator {
    var lines: IndexingIterator<[Substring]> = [].makeIterator()
}

class FileParser {
    private static var LineData = LineIterator()

    class func trimLine(line: Substring) -> String {
        let trimmed = line.replacingOccurrences(of: "#.*", with: "", options: [.regularExpression])
        var trimmedLine = trimmed.strip
        if trimmedLine.hasSuffix(" \\") {
            trimmedLine = trimmedLine.replacingOccurrences(of: "\\", with: "")
            if let nextLine = LineData.lines.next() {
                trimmedLine += trimLine(line: nextLine)
            }
        }
        return trimmedLine
    }

    class func buildRawConfigs(files: [String]) throws -> [(key: String, value: String)] {
        var rawConfigs: [String] = []
        var configOptions: [(key: String, value: String)] = []
        for file in files {
            do {
                let configData = try String(contentsOfFile: file)
                rawConfigs.insert(configData, at: 0)
            } catch {
                throw FileParserError.fileReadFailure(filePath: file)
            }
        }
        for rawconfig in rawConfigs {
            let lines = rawconfig.split(whereSeparator: \.isNewline)
            LineData.lines = lines.makeIterator()
            while let line = LineData.lines.next() {
                let cleanedLine = trimLine(line: line)
                if !cleanedLine.isEmpty {
                    let verbArray = cleanedLine.split(separator: " ", maxSplits: 1).map(String.init)
                    if verbArray.count > 1 {
                        let stringitem = String(describing: verbArray[1])
                        if stringitem.isInt {
                            configOptions.append((key: verbArray[0], value: stringitem))
                        } else if stringitem.isBool {
                            configOptions.append((key: verbArray[0], value: stringitem))
                        } else {
                            do {
                                let data = stringitem.data(using: .utf8)!
                                // swiftlint:disable force_cast
                                let json = try JSONSerialization.jsonObject(
                                    with: data,
                                    options: .allowFragments
                                ) as! [String]

                                let joined = json.joined(separator: " ")
                                configOptions.append((key: verbArray[0], value: String(joined)))
                            } catch {
                                configOptions.append((key: verbArray[0], value: stringitem))
                            }
                        }
                    }
                }
            }
        }
        return configOptions
    }
}

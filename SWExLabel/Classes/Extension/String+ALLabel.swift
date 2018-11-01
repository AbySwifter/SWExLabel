//
//  String+ALLabel.swift
//  ExpressionDemo
//
//  Created by aby on 2018/10/8.
//  Copyright © 2018 aby. All rights reserved.
//

import Foundation

public extension String {
    public var isNewlineCharacterAtEnd: Bool {
        if self.count <= 0 {
            return false
        }
        let separator = NSMutableCharacterSet.newline()
        guard let lastRange = self.rangeOfCharacter(from: separator as CharacterSet, options: String.CompareOptions.backwards, range: nil) else {
            return false
        }
        let lastNSRange = NSRange.init(lastRange, in: self)
        return NSMaxRange(lastNSRange) == self.count
    }

    public var lineCount: UInt {
        if self.count <= 0 {
            return 0
        }
        var numberOfLine: UInt = 0
        var index = 0
        while index < self.count {
            let range = self.lineRange(for: Range.init(NSMakeRange(index, 0), in: self)!)
            let nsRange = NSRange.init(range, in: self)
            index = NSMaxRange(nsRange)
            numberOfLine += 1
        }
        if self.isNewlineCharacterAtEnd {
            return numberOfLine + 1
        }
        return numberOfLine
    }

    public func lengthTo(lineIndex: Int) -> Int {
        if self.count <= 0 {
            return 0
        }
        var numberOfLines = 0
        var index = 0
        while index < self.count {
            let range = self.lineRange(for:Range.init(NSMakeRange(index, 0), in: self)!)
            let nsRange = NSRange.init(range, in: self)
            index = NSMaxRange(nsRange)
            if numberOfLines == lineIndex {
                let lineString = String.init(self[range])
                if !lineString.isNewlineCharacterAtEnd {
                    return index
                }
                // 把这行的换行符给忽略
                if let lineEndRange = lineString.range(of: "\n\r") {
                    if NSMaxRange(NSRange.init(lineEndRange, in: lineString)) == lineString.count {
                        return index - 2
                    }
                }
                return index - 1
            }
            numberOfLines += 1
        }
        return 0
    }
}

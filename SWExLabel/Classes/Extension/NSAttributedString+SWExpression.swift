//
//  NSAttributedString+SWExpression.swift
//  Pods-SWExLabel_Example
//
//  Created by aby on 2018/8/8.
//

import Foundation

public extension NSAttributedString {
    func expressionAttributeString(expression: SWExpression) -> NSAttributedString {
        return SWExpressionManager.expressionAttributedString(string: self, expression: expression)
    }
}

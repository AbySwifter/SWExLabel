//
//  String+Expression.swift
//  ExpressionDemo
//
//  Created by aby on 2018/10/8.
//  Copyright © 2018 aby. All rights reserved.
//

import Foundation


// MARK: - String的延展
public extension String {
    public func expressionAttributedString(expression: ALExpression) -> NSAttributedString {
        return AlExpressionManager.expressionAttributedString(self, expression: expression)
    }
}

// MARK: - NSAttributedStrng 的延展
public extension NSAttributedString {
    public func expressionAttributedString(expression: ALExpression) -> NSAttributedString {
        return AlExpressionManager.expressionAttributedString(self, expression: expression)
    }
}

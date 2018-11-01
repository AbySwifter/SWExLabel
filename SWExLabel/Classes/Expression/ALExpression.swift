//
//  ALExpression.swift
//  ExpressionDemo
//
//  Created by aby on 2018/9/30.
//  Copyright © 2018 aby. All rights reserved.
//

import UIKit

public class ALExpression: NSObject {
    // - MARK: public property
    public var regex: String = "" {
        willSet {
            assert(newValue.count>0, "regex length must gather than 0")
            self.expressionRegularExpression = AlExpressionManager.share.expressionRegularExpression(regex: newValue)
        }
    }
    public var plistName: String = "" {
        didSet {
            assert(plistName.count>0, "plistName's length must gather than 0")
            if !plistName.lowercased().hasSuffix(".plist") {
                plistName.append(".plist")
            }
            self.expressionMap = AlExpressionManager.share.expressionMap(plistName: plistName)
        }
    }
    public var bundleName: String = "" {
        didSet {
            if !bundleName.lowercased().hasSuffix(".bundle") {
                bundleName.append(".bundle")
            }
        }
        // TODO: - 后期需要验证一下存在性
    }
    // MARK: - private proterty
    var expressionRegularExpression: NSRegularExpression?
    var expressionMap: Dictionary<String, String>?
    var isValid: Bool {
        // 判断是否有效的方法
        let valid = self.expressionRegularExpression != nil && self.expressionMap != nil && self.bundleName.count > 0
        return valid
    }
    // MARK: - public method
    public convenience init(regex: String, plistName: String, bundleName: String) {
        self.init()
        self.regex = regex
        self.plistName = plistName
        self.bundleName = bundleName
        self.expressionRegularExpression = AlExpressionManager.share.expressionRegularExpression(regex: self.regex)
        if !self.plistName.lowercased().hasSuffix(".plist") {
            self.plistName.append(".plist")
        }
        self.expressionMap = AlExpressionManager.share.expressionMap(plistName: self.plistName)
        if !self.bundleName.lowercased().hasSuffix(".bundle") {
            self.bundleName.append(".bundle")
        }
        assert(self.isValid, "此expression无效请检查参数")
    }
}

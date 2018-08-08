//
//  SWExpresion.swift
//  Pods-SWExLabel_Example
//
//  Created by aby on 2018/8/7.
//

import Foundation

public class SWExpression {
    public var regex: String
    public var plistName: String
    public var bundleName: String
    
    var getBundleName: String {
        if self.bundleName.lowercased().hasSuffix(".bundle") {
            return self.bundleName
        } else {
            return self.bundleName + ".bundle"
        }
    }
    
    var getPlistName: String {
        if self.plistName.lowercased().hasPrefix(".plist") {
            return self.plistName
        } else {
            return self.plistName + ".plist"
        }
    }
    
    var expressionRegularExpression: NSRegularExpression {
        return SWExpressionManager.shared.expressionRegularExpression(regex: self.regex)
    }
    var expressionMap: NSDictionary {
        let dic:NSDictionary = SWExpressionManager.shared.expressionMap(plistName: self.getPlistName)
        return dic
    }
    
    public init(regex: String, plistName: String, bundleName: String) {
        self.regex = regex
        self.plistName = plistName
        self.bundleName = bundleName
        assert(self.isValid, "此参数无效，请检查初始化方法")
    }
    
    public var isValid: Bool {
        return true
    }
    
    
}

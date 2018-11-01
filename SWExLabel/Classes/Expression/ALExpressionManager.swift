//
//  ALExpressionManager.swift
//  ExpressionDemo
//
//  Created by aby on 2018/9/30.
//  Copyright © 2018 aby. All rights reserved.
//

import UIKit

public class AlExpressionManager {
    public static let share = AlExpressionManager.init()
    private init() {

    }
    // MARK: - private prooerty
    lazy var expressionMapRecords: Dictionary<String, Dictionary<String,String>> = {
        var dic = Dictionary<String, Dictionary<String,String>>.init()
        return dic
    }()
    lazy var expressionRegularExpressionRecords: Dictionary<String,NSRegularExpression> = {
        var dic = Dictionary<String, NSRegularExpression>.init()
        return dic
    }()
    // MARK: - public method
    public static func expressionAttributedString(_ string: String, expression: ALExpression) -> NSAttributedString {
        let attributeString = NSAttributedString.init(string: string)
        return AlExpressionManager.expressionAttributedString(attributeString, expression: expression)
    }

    public static func expressionAttributedString(_ attrString: NSAttributedString, expression: ALExpression) -> NSAttributedString {
        assert(expression.isValid, "expression invalid")
        if attrString.length <= 0 {
            return attrString
        }
        let resultAttrString = NSMutableAttributedString.init()
        // 处理表情
        guard let resulets = expression.expressionRegularExpression?.matches(in: attrString.string,
                                                                       options: NSRegularExpression.MatchingOptions.withTransparentBounds,
                                                                       range: NSRange.init(location: 0, length: attrString.length)) else {
                                                                        return attrString
        }
        // 遍历表情，找到对应图像名称，并且处理
        var location: NSInteger = 0
        for result in resulets {
            let range = result.range
            let subAttrStr = attrString.attributedSubstring(from: NSRange.init(location: location, length: range.location - location))
            // 先把非表情部分添加上去
            resultAttrString.append(subAttrStr)
            // 标记下次循环的位置
            location = NSMaxRange(range)

            let expressionAttrStr = attrString.attributedSubstring(from: range)
            let imageName: String = expression.expressionMap?[expressionAttrStr.string] ?? ""
            if imageName.count>0 {
                // 加个表情到结果中去
                let bundle = Bundle.init(url: Bundle.main.url(forResource: expression.bundleName, withExtension: nil)!)
                let image: UIImage = UIImage.init(named: imageName, in: bundle!, compatibleWith: nil)!
                let attachment = ALTextAttachment.init(lineHeightMultiple: 1.00, imageAspectRatio: image.size.width/image.size.height) { (imageBounds, textConatainer, charIndex, textAttachment) -> UIImage in
                    return image
                }
                let attachmentString: NSMutableAttributedString = NSAttributedString.init(attachment: attachment).mutableCopy() as! NSMutableAttributedString
                expressionAttrStr.enumerateAttributes(in: NSRange.init(location: 0, length: expressionAttrStr.length), options: .longestEffectiveRangeNotRequired) { (attrs, range, stop) in
                    if attrs.count>0 && range.length==expressionAttrStr.length {
                        attachmentString.addAttributes(attrs, range: NSRange.init(location: 0, length: attachmentString.length))
                    }
                }
                resultAttrString.append(attachmentString)
            } else {
                resultAttrString.append(expressionAttrStr)
            }
        }
        if location < attrString.length {
            let range = NSRange.init(location: location, length: attrString.length - location)
            let sub = attrString.attributedSubstring(from: range)
            resultAttrString.append(sub)
        }
        return resultAttrString
    }

    public static func expressionAttributedStrings(_ strings: Array<String>, expression: ALExpression) -> Array<NSAttributedString> {
        var results = Dictionary<String, NSAttributedString>.init()
        let queue = DispatchQueue.global()
        let group = DispatchGroup.init()
        for str in strings {
            queue.async(group: group, qos: .default, flags: []) {
                let result = AlExpressionManager.expressionAttributedString(str, expression: expression)
                objc_sync_enter(self)
                results[str] = result
                objc_sync_exit(self)
            }
        }
        group.wait()
        // 重新排列
        var resultArr = Array<NSAttributedString>.init()
        for str in strings {
            if let attr = results[str] {
                resultArr.append(attr)
            }
        }
        return resultArr
    }

    public static func expressionAttributedStrings(_ strings: Array<String>, expression: ALExpression, callback: @escaping (Array<NSAttributedString>) ->Void ) -> Void {
        var results = Dictionary<String, NSAttributedString>.init()
        let queue = DispatchQueue.global()
        let group = DispatchGroup.init()
        for str in strings {
            queue.async(group: group, qos: .default, flags: []) {
                let result = AlExpressionManager.expressionAttributedString(str, expression: expression)
                objc_sync_enter(self)
                results[str] = result
                objc_sync_exit(self)
            }
        }
        group.notify(queue: queue) {
            var resultArr = Array<NSAttributedString>.init()
            for str in strings {
                if let attr = results[str] {
                    resultArr.append(attr)
                }
            }
            DispatchQueue.main.async {
                callback(resultArr)
            }
        }
    }

    // MARK: - common
    func expressionMap(plistName: String) -> Dictionary<String, String> {
        assert(plistName.count>0, "expressionMap(plistName:) 参数不得为空字符串")
        if let result = self.expressionMapRecords[plistName] {
            return result
        }
        guard let plistPath = Bundle.main.resourcePath?.appending("/\(plistName)"), let dict = NSDictionary.init(contentsOfFile: plistPath) as? Dictionary<String, String> else {
            assertionFailure("表情字典无法找到")
            return [String:String]()
        }
        self.expressionMapRecords[plistName] = dict
        return self.expressionMapRecords[plistName] ?? [String:String]()
    }

    func expressionRegularExpression(regex: String) -> NSRegularExpression {
        assert(regex.count>0, "参数不得为空")
        if let regulatExpresiion = self.expressionRegularExpressionRecords[regex] {
            return regulatExpresiion
        }
        guard let re = try? NSRegularExpression.init(pattern: regex, options: .allowCommentsAndWhitespace) else {
            assertionFailure("正则表达式有误")
            return NSRegularExpression.init()
        }
        self.expressionRegularExpressionRecords[regex] = re
        return re
    }
}

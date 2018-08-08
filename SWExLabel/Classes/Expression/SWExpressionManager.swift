//
//  SWExpressionManager.swift
//  Pods-SWExLabel_Example
//
//  Created by aby on 2018/8/7.
//

import Foundation


/// 处理表情的管理类
public class SWExpressionManager {
    public static let shared = SWExpressionManager.init()
    private init() {}
    
    private var expressionMapRecords: Dictionary<String, NSDictionary> = [:]
    private var expressionRegularExpressionRecords: Dictionary<String, NSRegularExpression> = [:]
    
    /// 替换字符中的表情为图片的方法
    ///
    /// - Parameters:
    ///   - string: 需要替换的字符
    ///   - expression: 替换的规则类
    /// - Returns: 返回替换后的富文本
    public class func expressionAttributedString(string: String, expression: SWExpression) -> NSAttributedString {
        let attributeStr = NSAttributedString.init(string: string)
        return expressionAttributedString(string: attributeStr, expression: expression)
    }
    
    /// 替换字符中的表情为图片的方法
    ///
    /// - Parameters:
    ///   - string: 需要替换的字符
    ///   - expression: 替换的规则类
    /// - Returns: 返回替换后的富文本
    public class func expressionAttributedString(string: NSAttributedString, expression: SWExpression) -> NSAttributedString {
        let target: NSMutableAttributedString = string.mutableCopy() as! NSMutableAttributedString
        if target.length <= 0 {
            return target
        }
        let tempAttribute = NSMutableAttributedString.init()
        // 处理表情
        let resArr = expression.expressionRegularExpression.matches(in: target.string, options: .withTransparentBounds, range: NSRange.init(location: 0, length: target.length))
        var location: Int = 0;
        for resultText: NSTextCheckingResult in resArr {
            let range: NSRange = resultText.range
            let subString: NSAttributedString = target.attributedSubstring(from: NSRange.init(location: location, length: range.location - location))
            // 先把非表情部分加上去
            tempAttribute.append(subString)
            // 修改location 的值，从下一个表情的位置开始
            location = NSMaxRange(range)
            
            let expressionStr = target.attributedSubstring(from: range)
            let imageName: String = expression.expressionMap.object(forKey: expressionStr.string) as? String ?? ""
            // 如果图片名存在
            if imageName.count > 0 {
                let bundle = Bundle.init(url: Bundle.main.url(forResource: expression.bundleName, withExtension: ".bundle")!)
                let image: UIImage = UIImage.init(named: imageName, in: bundle!, compatibleWith: nil)!
                let textAttachment = SWTextAttachment.init(lineHeightMultiple: 1.00, imageAspectRatio: image.size.width/image.size.height) { (imageBounds, textContainer, charIndex, textAttachment) -> UIImage in
                    return image
                }
                let attachmentString: NSMutableAttributedString = NSAttributedString.init(attachment: textAttachment).mutableCopy() as! NSMutableAttributedString
                expressionStr.enumerateAttributes(in: NSRange.init(location: 0, length: expressionStr.length), options: .longestEffectiveRangeNotRequired) { (attrs, range, stop) in
                    if attrs.count>0 && range.length==expressionStr.length {
                        attachmentString.addAttributes(attrs, range: NSRange.init(location: 0, length: attachmentString.length))
                    }
                }
                tempAttribute.append(attachmentString)
            } else {
                tempAttribute.append(expressionStr)
            }
        }
        if location < target.length {
            let range = NSRange.init(location: location, length: target.length - location)
            let sub = target.attributedSubstring(from: range)
            tempAttribute.append(sub)
        }
        return tempAttribute
    }
    
    
    /// 读取表情字典plist文件
    ///
    /// - Parameter plistName: 文件名
    /// - Returns: 读取后的字典文件
    public func expressionMap(plistName: String) -> NSDictionary {
        assert(plistName.count>0, "参数不能为空或者字符长度小于0")
        if let dic = self.expressionMapRecords[plistName] {
            return dic
        }
        guard let plistPath = Bundle.main.resourcePath?.appending("/\(plistName)") else {
            assert(false, "表情字典路径不存在")
            return NSDictionary.init()
        }
        let dictory = NSDictionary.init(contentsOfFile: plistPath)
        if let dic = dictory {
            self.expressionMapRecords[plistName] = dic
        } else {
            assert(false, "表情字典无法正确初始化")
        }
        return self.expressionMapRecords[plistName] ?? NSDictionary.init()
    }
    
    
    /// 处理正则表达式
    ///
    /// - Parameter regex: 正则表达式的字符串
    /// - Returns: 用来处理正则表达式的类
    public func expressionRegularExpression(regex: String) -> NSRegularExpression {
        assert(regex.count > 0, "参数字符不得为空字符")
        if let regular = self.expressionRegularExpressionRecords[regex] {
            return regular
        } else {
            
            let re:NSRegularExpression? = try? NSRegularExpression.init(pattern: regex, options: .caseInsensitive)
            assert(re != nil, "正则表达式\(regex)有误，请检查")
            self.expressionRegularExpressionRecords[regex] = re!
            return re!
        }
    }
    
    /// 给一个string数组，返回对应的表情attrStr数组，顺序一致
    ///
    /// - Parameters:
    ///   - strings: 要改变的string数组
    ///   - expression: 表情参数
    /// - Returns: 返回值
    public class func expressionAttributedString(strings: Array<String>, expression: SWExpression) -> Array<NSAttributedString> {
        var results: Dictionary = [String: NSAttributedString]()

        let queue: DispatchQueue = DispatchQueue.global()
        let group: DispatchGroup = DispatchGroup.init()
        for str in strings {
            queue.async(group: group, execute: DispatchWorkItem.init(block: {
                let result:NSAttributedString = SWExpressionManager.expressionAttributedString(string: str, expression: expression)
                // 线程锁
                objc_sync_enter(results)
                results[str] = result
                objc_sync_exit(results)
            }))
        }
        _ = group.wait(timeout: DispatchTime.distantFuture)
        
        // 重新排列
        var resultArr = [NSAttributedString]()
        for str in strings {
            resultArr.append(results[str]!)
        }
        return resultArr
    }
    
    
    /// 回调方法处理输入的字符串数组
    ///
    /// - Parameters:
    ///   - strings: 要处理的字符串数组
    ///   - expression: 配置
    ///   - callback: 返回回调
    public class func expressionAttributedString(strings: Array<String>, expression: SWExpression, callback:@escaping ((Array<NSAttributedString>) -> Void)) -> Void{
        var results: Dictionary = [String: NSAttributedString]()
        let queue: DispatchQueue = DispatchQueue.global()
        let group: DispatchGroup = DispatchGroup.init()
        for str in strings {
            queue.async(group: group, execute: DispatchWorkItem.init(block: {
                let result:NSAttributedString = SWExpressionManager.expressionAttributedString(string: str, expression: expression)
                // 线程锁
                objc_sync_enter(results)
                results[str] = result
                objc_sync_exit(results)
            }))
        }
        group.notify(queue: queue) {
            // 重新排列
            var resultArr = [NSAttributedString]()
            for str in strings {
                resultArr.append(results[str]!)
            }
            DispatchQueue.main.async(execute: {
                callback(resultArr)
            })
        }
        
    }
}


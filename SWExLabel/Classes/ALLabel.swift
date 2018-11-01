//
//  ALLabel.swift
//  ExpressionDemo
//
//  Created by aby on 2018/10/8.
//  Copyright © 2018 aby. All rights reserved.
//

import UIKit

enum AlLastTextType {
    case normal
    case attributed
}
// 总的有个极限
public let KALLabelFloatMax: CGFloat = 10000000.0
public let KALLabelAdjustMinFontSize: CGFloat = 1.0
public let KALLabelAdjustMinScaleFactor: CGFloat = 0.01

public func KMLabelStylePropertyNames() -> Array<String> {
    return ["font","textAlignment","textColor","highlighted",
             "highlightedTextColor","shadowColor","shadowOffset","enabled","lineHeightMultiple","lineSpacing"]
}


/// 私有类，不暴露给外界
class ALLabelStylePropertyRecord: NSObject {
    var font: UIFont?
    var textAlignment: NSTextAlignment?
    var textColor: UIColor?
    var highlighted: Bool?
    var highlightedTextColor: UIColor?
    var shadowColor: UIColor?
    var shadowOffset: CGSize?
    var enabled: Bool?
    var lineHeightMultiple: CGFloat? // 行高
    var lineSpacing: CGFloat? //行间距
    override func setValue(_ value: Any?, forUndefinedKey key: String) {
        print("key is \(key)")

    }

    func refresh(key: String, value: ALLabel) -> Void {
        switch key {
        case "font":
            self.font = value.font
        case "textAlignment":
            self.textAlignment = value.textAlignment
        case "textColor":
            self.textColor = value.textColor
        case "highlighted":
            self.highlighted = value.isHighlighted
        case "highlightedTextColor":
            self.highlightedTextColor = value.highlightedTextColor
        case "shadowColor":
            self.shadowColor = value.shadowColor
        case "shadowOffset":
            self.shadowOffset = value.shadowOffset
        case "enable":
            self.enabled = value.isEnabled
        case "lineHeightMultiple":
            self.lineHeightMultiple = value.lineHeightMultiple
        case "lineSpacing":
            self.lineSpacing = value.lineSpacing
        default:
            break
        }
    }
}

public class ALLabel: UILabel, NSLayoutManagerDelegate {
    // 公开的属性
    public var lineHeightMultiple: CGFloat = 0
    public var lineSpacing: CGFloat = 0
    public var textInsets: UIEdgeInsets = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0) {
        didSet {
            self.resizeTextContainerSize()
            self.invalidateIntrinsicContentSize()
        }
    }

    public var doBeforeDrawingTextBlock: ((CGRect, CGPoint, CGSize) -> Void)?

    // 未公开的属性
    var textStorage: NSTextStorage = NSTextStorage.init()
    lazy var layoutManager: ALLabelLayoutManager = {
        let layoutManager = ALLabelLayoutManager.init()
        layoutManager.allowsNonContiguousLayout = false
        layoutManager.delegate = self
        return layoutManager
    }()
    lazy var textContainer: NSTextContainer = {
        let textContainer: NSTextContainer = NSTextContainer.init()
        textContainer.maximumNumberOfLines = self.numberOfLines
        textContainer.lineBreakMode = self.lineBreakMode
        textContainer.lineFragmentPadding = 0.0
        textContainer.size = self.frame.size
        return textContainer
    }()
    var lastTextType: AlLastTextType = .normal {
        didSet {
            // 重置一下
            self.lastText = nil
            self.lastAttributedText = nil
        }
    }
    var styleRecord: ALLabelStylePropertyRecord = ALLabelStylePropertyRecord.init()

    var lastAttributedText: NSAttributedString?
    var lastText: String?

    // 控制 Attribute和text 的set方法触发的属性
    var needAttrWillSet: Bool = true
    var needTextWillSet: Bool = true

    override public var attributedText: NSAttributedString? {
        willSet {
            self.lastTextType = .attributed
            // 做一些在赋值了富文本之后的东西
            self.lastAttributedText = newValue
            self.invalidateIntrinsicContentSize()
            self.textStorage.setAttributedString(self.attributedTextForTextStorageFromLabelProperties())
//            self.textStorage.setAttributedString(newValue ?? NSAttributedString.init(string: "默认"))
            // 如果text和原本的一样的话，是不会触发redraw的，但我们的label比较灵活，验证很麻烦，所以均采取重绘的方式解决
            self.setNeedsDisplay()
        }
    }

    override public var text: String? {
        willSet {
            self.lastTextType = .normal
            self.lastText = newValue
            self.invalidateIntrinsicContentSize()
            self.textStorage.setAttributedString(self.attributedTextForTextStorageFromLabelProperties())
            // 如果text和原本的一样的话，是不会触发redraw的，但我们的label比较灵活，验证很麻烦，所以均采取重绘的方式解决
            self.setNeedsDisplay()
        }
    }

    override public var frame: CGRect {
        didSet {
            self.resizeTextContainerSize()
        }
    }

    override public var bounds: CGRect {
        didSet {
            self.resizeTextContainerSize()
        }
    }

    override public var numberOfLines: Int {
        didSet {
            let isChanged = numberOfLines != textContainer.maximumNumberOfLines
            textContainer.maximumNumberOfLines = numberOfLines
            if isChanged {
                self.invalidateIntrinsicContentSize()
                self.setNeedsDisplay()
            }
        }
    }

    override public var lineBreakMode: NSLineBreakMode {
        didSet {
            textContainer.lineBreakMode = lineBreakMode
            self.invalidateIntrinsicContentSize()
        }
    }

    public override var minimumScaleFactor: CGFloat {
        didSet {
            self.invalidateIntrinsicContentSize()
            self.setNeedsDisplay()
        }
    }
    /// 计算属性，返回一些文本的默认设置
    var attributesFromLabelProperties: [NSAttributedString.Key: Any]? {
        // 颜色
        var color = self.styleRecord.textColor
        if styleRecord.enabled != nil {
            color = UIColor.lightGray
        } else if styleRecord.highlighted ?? false {
            color = styleRecord.highlightedTextColor
        }
        if color == nil {
            color = styleRecord.textColor
        }
        if color == nil {
            color = UIColor.darkText
        }

        // 阴影
        let shadow = NSShadow.init()
        if let shadowColor = styleRecord.shadowColor {
            shadow.shadowColor = shadowColor
            shadow.shadowOffset = styleRecord.shadowOffset ?? CGSize.zero
        } else {
            shadow.shadowOffset = CGSize.init(width: 0, height: -1)
            shadow.shadowColor = nil
        }

        // 水平位置
        let paragraph = NSMutableParagraphStyle.init()
        paragraph.alignment = styleRecord.textAlignment ?? .left
        paragraph.lineSpacing = styleRecord.lineSpacing ?? 0
        paragraph.lineHeightMultiple = styleRecord.lineHeightMultiple ?? 1.0

        if styleRecord.font == nil {
            styleRecord.font = UIFont.systemFont(ofSize: 17.0)
        }

        let result = [NSAttributedString.Key.font : styleRecord.font,
                      NSAttributedString.Key.foregroundColor : color,
                      NSAttributedString.Key.shadow : shadow,
                      NSAttributedString.Key.paragraphStyle : paragraph]
        return result as [NSAttributedString.Key : Any]
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    deinit {
        for key in KMLabelStylePropertyNames() {
            self.removeObserver(self, forKeyPath: key, context: nil)
        }
    }

    func commonInit() -> Void {
        self.lineHeightMultiple = 1.0
        // 设置和TextKit相关
        self.textStorage.addLayoutManager(self.layoutManager)
        self.layoutManager.addTextContainer(self.textContainer)

        if let attr = super.attributedText {
            self.attributedText = attr
        } else {
            self.text = super.text
        }
        // kvo监视style属性
        for key in KMLabelStylePropertyNames() {
            // FIXME: KVC 有问题
            self.styleRecord.refresh(key: key, value: self)
            self.addObserver(self, forKeyPath: key, options: [NSKeyValueObservingOptions.new, .old], context: nil)
        }
    }

    func preferredSize(maxWidth: CGFloat) -> CGSize {
        var size = self.sizeThatFits(CGSize.init(width: maxWidth, height: KALLabelFloatMax))
        size.width = fmin(size.width, maxWidth)
        return size
    }

    func setDoBeforeDrawingTextBlock(block:@escaping ((CGRect, CGPoint, CGSize) -> Void)) -> Void {
        self.doBeforeDrawingTextBlock = block
        self.setNeedsDisplay()
    }

    func reSetText() -> Void {
        if lastTextType == .normal {
            self.text = lastText
        } else {
            self.attributedText = lastAttributedText
        }
    }

    // 根据label的属性来进行处理并返回给textStorage使用
    func attributedTextForTextStorageFromLabelProperties() -> NSMutableAttributedString {
        if self.lastTextType == .normal {
            guard let _lastText = self.lastText else {
                return NSMutableAttributedString.init(string: "")
            }
            return NSMutableAttributedString.init(string: _lastText, attributes: attributesFromLabelProperties)
        }
        guard let _lastAttributedString = self.lastAttributedText else {
            return NSMutableAttributedString.init(string: "")
        }
        // 遍历并添加label默认属性
        let newAttrStr = NSMutableAttributedString.init(string: _lastAttributedString.string, attributes: attributesFromLabelProperties)
        _lastAttributedString.enumerateAttributes(in: NSMakeRange(0, newAttrStr.length), options: NSAttributedString.EnumerationOptions.init(rawValue: 0)) { (attrs, range, stop) in
            if attrs.count > 0 {
                newAttrStr.addAttributes(attrs, range: range)
            }
        }
//        newAttrStr.addAttribute(NSAttributedString.Key.backgroundColor, value: UIColor.green, range: NSMakeRange(0, newAttrStr.length))
        return newAttrStr
    }
}

extension ALLabel {
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let key = keyPath else {
            return
        }
        if KMLabelStylePropertyNames().contains(key) {
            if let obj = object as? ALLabel {
                //FIXME: 取值有问题 存储到记录的对象里
                 self.styleRecord.refresh(key: key, value: obj)
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    public override func value(forUndefinedKey key: String) -> Any? {
        if key == "lineHeightMultiple" {
            return self.lineHeightMultiple
        }
        if key == "lineSpacing" {
            return self.lineSpacing
        }
        print("lable undefined Key: \(key)")
        return nil
    }
}

extension ALLabel {
    func drawTextSize(bonds size: CGSize) -> CGSize {
        let width = fmax(0, size.width - textInsets.left - textInsets.right)
        let height = fmax(0, size.height - textInsets.top - textInsets.bottom)
        return CGSize.init(width: width, height: height)
    }
    func textRect(forBounds bounds:CGRect, attributedString: NSAttributedString, limitedToNumberOfLines numberOfLines: NSInteger, lineCount: UnsafeMutablePointer<Int>?) -> CGRect {
        // 这种算是特殊情况，如果为空字符串, 那就没有必要了，也忽略textInset, 相对合理
        if attributedText?.length ?? 0 <= 0 {
           return CGRect.init(origin: bounds.origin, size: CGSize.zero)
        }
        var drawTextSize = self.drawTextSize(bonds: bounds.size)
        if drawTextSize.width <= 0 || drawTextSize.height <= 0 {
            var textBounds = CGRect.zero
            textBounds.origin = bounds.origin
            textBounds.size = CGSize.init(width: fmin(textInsets.left+textInsets.right, bounds.width), height: fmin(textInsets.top+textInsets.bottom, bounds.height))
            return textBounds
        }
        var textBounds = CGRect.zero
        autoreleasepool { () -> Void in
            let savedTextContainerSize = textContainer.size
            let savedTextContainerNumberOfLines = textContainer.maximumNumberOfLines
            if drawTextSize.height < KALLabelFloatMax {
                drawTextSize.height += self.lineSpacing
            }
            textContainer.size = drawTextSize
            textContainer.maximumNumberOfLines = numberOfLines
            var savedAttributedString:  NSAttributedString? = nil
            if !textStorage.isEqual(attributedString) {
                savedAttributedString = textStorage.copy() as? NSAttributedString
                textStorage.setAttributedString(attributedString)
            }
            let glyphRange = layoutManager.glyphRange(for: self.textContainer)
            // FIXME: 这里可能出问题
            if let _lineCount = lineCount {
                layoutManager.enumerateLineFragments(forGlyphRange: glyphRange, using: { (rect, usedRect, textContainer, glyphRange, stop) in
                    _lineCount.pointee += 1
                })
                if textStorage.string.isNewlineCharacterAtEnd {
                    _lineCount.pointee += 1
                }
            }
            textBounds = layoutManager.usedRect(for: textContainer)
            if  let save = savedAttributedString {
                textStorage.setAttributedString(save)
            }
            textContainer.size = savedTextContainerSize
            textContainer.maximumNumberOfLines = savedTextContainerNumberOfLines
        }
        // 最终修正
        textBounds.size.width = fmin(CGFloat(ceilf(Float(textBounds.size.width))), drawTextSize.width)
        textBounds.size.height = fmin(CGFloat(ceilf(Float(textBounds.size.height))), drawTextSize.height)
        textBounds.origin = bounds.origin

        textBounds.size = CGSize.init(width: fmin(textBounds.width + textInsets.left + textInsets.right, bounds.width), height: fmin(textBounds.height + textInsets.top + textInsets.bottom, bounds.height))
        return textBounds
    }
}


// MARK: - draw
extension ALLabel {
    func adjustsCurrentFontSizeToFit(scaleFactor: inout CGFloat, numberOfLines: Int, originalAttributedText: NSAttributedString, bounds: CGRect, resultAttributedString: UnsafeMutablePointer<NSAttributedString>?) -> Bool {
        var mustReturnTrue = false
        if self.minimumScaleFactor > scaleFactor {
            scaleFactor = self.minimumScaleFactor
            mustReturnTrue = true
        }
        // 总得有个极限
        scaleFactor = fmax(scaleFactor, KALLabelAdjustMinScaleFactor)
        // 遍历并且设置一个新的字体
        let attrStr = originalAttributedText.mutableCopy() as! NSMutableAttributedString
        if scaleFactor != 1.0 {
            attrStr.enumerateAttribute(NSAttributedString.Key.font, in: NSMakeRange(0, attrStr.length), options: NSAttributedString.EnumerationOptions.init(rawValue: 0)) { (value, range, stop) in
                guard let font = value as? UIFont else {return}
                if font.isKind(of: UIFont.self) {
                    let fontName = font.fontName
                    let newSize = font.pointSize*scaleFactor
                    if newSize < KALLabelAdjustMinFontSize {
                        mustReturnTrue = true
                    }
                    let newFont = UIFont.init(name: fontName, size: newSize)
                    attrStr.addAttribute(NSAttributedString.Key.font, value: newFont ?? UIFont.systemFont(ofSize: newSize), range: range)
                }
            }
        }
        if mustReturnTrue {
            if let pointer = resultAttributedString {
                pointer.pointee = attrStr
            }
            return true
        }
        var currentTextSize = CGSize.zero
        if numberOfLines > 0 {
            var lineCount = 0
            currentTextSize = self.textRect(forBounds:CGRect.init(x: 0, y: 0, width: bounds.width, height: KALLabelFloatMax), attributedString: attrStr, limitedToNumberOfLines: 0, lineCount: &lineCount).size
            if lineCount > numberOfLines {
                return false
            }
        } else {
            var lineCount = 0
            currentTextSize = self.textRect(forBounds: CGRect.init(x: 0, y: 0, width: bounds.width, height: KALLabelFloatMax), attributedString: attrStr, limitedToNumberOfLines: 0, lineCount: &lineCount).size
        }
        // 大小已经足够就认作OK了
        if currentTextSize.width <= bounds.width && currentTextSize.height <= bounds.height {
            if let pointer = resultAttributedString {
                pointer.pointee = attrStr
            }
            return true
        }
        return true
    }

    public override func drawText(in rect: CGRect) {
        let drawSize = self.drawTextSize(bonds: self.bounds.size)
        if drawSize.width <= 0 || drawSize.height <= 0 {
            return
        }
        if self.adjustsFontSizeToFitWidth {
            // 初始scale， 每次adjust都需要重头开始，因为也有可能有当前font被adjustc小过需要还原
            var scaleFactor: CGFloat = 1.0
            var mustContinueAdjust:Bool = true
            var attributedString: NSMutableAttributedString = self.attributedTextForTextStorageFromLabelProperties()
            if self.numberOfLines > 0 {
                // 一点点的矫正，使得内容能够放到当前的size里面
                // 找到当前的text绘制在一行时候需要占用的宽度，其实这个值可能不够，因为多行的时候应为wordwrap的关系，多行加起来的总宽度会多，但是这个能找到一个合适的矫正过程的开始值，大大减少矫正次数
                // 还有一种情况就是，有可能由于字符串李带换行符的关机，y造成压根不可能绘制到一行，这时候应该取会显示的最长的那一行。所以这里先要截除必然不会显示的部分
                let stringlineCount = attributedString.string.lineCount
                if stringlineCount > self.numberOfLines {
                    // 这里说明必然要截取
                    attributedString = attributedString.attributedSubstring(from: NSMakeRange(0, attributedString.string.lengthTo(lineIndex: self.numberOfLines - 1))) as! NSMutableAttributedString
                }
                var textWidth = self.textRect(forBounds: CGRect.init(x: 0, y: 0, width: KALLabelFloatMax, height: KALLabelFloatMax), attributedString: attributedString, limitedToNumberOfLines: 0, lineCount: nil).size.width
                textWidth = fmax(0, textWidth-textInsets.left-textInsets.right)
                if textWidth > 0 {
                    let availableWidth = textContainer.size.width * CGFloat(self.numberOfLines)
                    if textWidth > availableWidth {
                        scaleFactor = availableWidth / textWidth
                    }
                } else {
                    mustContinueAdjust = false
                }
            }
            if mustContinueAdjust {
                // 一点一点的矫正，使得当前内容可以放到size中
                var resultAtttributedString = attributedString as NSAttributedString
                while !self.adjustsCurrentFontSizeToFit(scaleFactor: &scaleFactor, numberOfLines: self.numberOfLines, originalAttributedText: attributedString, bounds: self.bounds, resultAttributedString: &resultAtttributedString) {
                    scaleFactor *= CGFloat(M_E / Double.pi)
                }
                textStorage.setAttributedString(resultAtttributedString)
            }
        }
        // 这里根据container的size和manager布局属性以及字符串来得到实际绘制的range区间
        let glyphRange = layoutManager.glyphRange(for: textContainer)
        // 获取绘制区域的大小
        let drawBounds = layoutManager.usedRect(for: textContainer)
        // 因为label是默认垂直居中的，所以需要根据实际的绘制区域的bounds来调整出居中的offset
        let textOffset = self.textOffset(textSize: drawBounds.size)
        
        if let doBefore = self.doBeforeDrawingTextBlock {
            let drawSize = CGSize.init(width: textContainer.size.width, height: drawBounds.size.height)
            doBefore(rect, textOffset, drawSize)
        }
        // 绘制文字
        layoutManager.drawBackground(forGlyphRange: glyphRange, at: textOffset)
        layoutManager.drawGlyphs(forGlyphRange: glyphRange, at: textOffset)
    }

    func textOffset(textSize:CGSize) -> CGPoint {
        var textOffset = CGPoint.zero
        textOffset.x = textInsets.left
        let paddingHeight = (self.bounds.height - textInsets.top - textInsets.bottom - textSize.height) / 2.0
        textOffset.y = paddingHeight + textInsets.top
        return textOffset
    }
}

// MARK: - size that fit
extension ALLabel {
    public override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        // fit实现和drawTextInRect大部分一样
        if numberOfLines > 1 && self.adjustsFontSizeToFitWidth {
            var scaleFactor: CGFloat = 1.0
            var attributedString = self.attributedTextForTextStorageFromLabelProperties()
            let stringLineCount = attributedString.string.lineCount
            if stringLineCount > self.numberOfLines {
                // 这里说明必然要截取
                attributedString = attributedString.attributedSubstring(from: NSMakeRange(0, attributedString.string.lengthTo(lineIndex: self.numberOfLines - 1))).mutableCopy() as! NSMutableAttributedString
            }
            var textWidth = self.textRect(forBounds: CGRect.init(x: 0, y: 0, width: KALLabelFloatMax, height: KALLabelFloatMax), attributedString: attributedString, limitedToNumberOfLines: 0, lineCount: nil).size.width
            textWidth = fmax(0, textWidth - textInsets.left - textInsets.right)
            if textWidth > 0 {
                let availableWidth = textContainer.size.width * CGFloat(numberOfLines)
                if textWidth > availableWidth {
                    scaleFactor = availableWidth / textWidth
                }
                // 一点点矫正，以使得内容可以放到当前的size里面去
                var resultAttributedString = attributedString as NSAttributedString
                while !self.adjustsCurrentFontSizeToFit(scaleFactor: &scaleFactor, numberOfLines: numberOfLines, originalAttributedText: attributedString, bounds: bounds, resultAttributedString: &resultAttributedString) {
                    scaleFactor *= CGFloat(M_E / Double.pi)
                }
                let textBounds = self.textRect(forBounds: bounds, attributedString: resultAttributedString, limitedToNumberOfLines: numberOfLines, lineCount: nil)
                return textBounds
            }
        }
        return self.textRect(forBounds: bounds, attributedString: textStorage, limitedToNumberOfLines: numberOfLines, lineCount: nil)
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        let _size = super.sizeThatFits(size)
        return self.sizePixeRound(_size)
    }

    func resizeTextContainerSize() -> Void {
        var size = self.drawTextSize(bonds: self.bounds.size)
        if size.height < KALLabelFloatMax {
            size.height += self.lineSpacing
        }
        textContainer.size = size
    }

    func sizePixeRound(_ size:CGSize) -> CGSize {
        var scale = 0.0
        scale = Double(UIScreen.main.scale)
        return CGSize.init(width: round(Double(size.width) * scale) / scale, height: round(Double(size.height) * scale) / scale)
    }
}


// MARK: - UIResponder
extension ALLabel {
    public override func becomeFirstResponder() -> Bool {
        return true
    }

    public override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return action == #selector(copy(_:))
    }

    public override func copy(_ sender: Any?) {
        UIPasteboard.general.string = self.text
    }
}

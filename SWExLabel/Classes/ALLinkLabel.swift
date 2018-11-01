//
//  ALLinkLabel.swift
//  ExpressionDemo
//
//  Created by aby on 2018/10/9.
//  Copyright © 2018 aby. All rights reserved.
//

import UIKit

public struct ALDataDetectorTypes: OptionSet {
    public var rawValue: UInt
    /// 链接
    public static let url = ALDataDetectorTypes.init(rawValue: 1 << 1)
    /// 电话
    public static let phoneNumber = ALDataDetectorTypes.init(rawValue: 1 << 0)
    /// 禁用
    public static let none = ALDataDetectorTypes.init(rawValue: 0)
    /// 所有
    public static let all = ALDataDetectorTypes.init(rawValue: UInt.max)
    //上面4个和UIDataDetectorTypes的对应，下面是自己加的
    public static let email = ALDataDetectorTypes.init(rawValue: 1 << 4)
    public static let userHandle = ALDataDetectorTypes.init(rawValue: 1 << 5)
    public static let hashTag = ALDataDetectorTypes.init(rawValue: 1 << 6)
    //这个是对attributedText里带有Link属性的检测，至于为什么30，预留上面空间以添加新的个性化
    //这个东西和dataDetectorTypesOfAttributedLinkValue对应起来，会对带有NSLinkAttributeName区间的value进行检测，匹配则给予对应的LinkType，找不到则为Other
    //注意NSLinkAttributeName所对应的值一定得是NSURL、NSString、NSAttributedString的一种
    public static let attributedLink = ALDataDetectorTypes.init(rawValue: 1 << 30)
    public init(rawValue: ALDataDetectorTypes.RawValue) { self.rawValue = rawValue }
}

public enum ALLinkType: UInt {
    case none = 0
    case url = 1
    case phoneNumber = 2
    case email = 3
    case userHandle = 4
    case hashTag = 5

    case other = 30
}

let kDefaultLinkColorForLinkLabel = UIColor.init(red: 0.061, green: 0.515, blue: 0.862, alpha: 1.000)
let KDefaultActiveLinkBackgroundColorForLinkLabel = UIColor.init(white: 0.215, alpha: 0.300)

public class ALLink: NSObject {
    public var linkType: ALLinkType
    public var linkValue: String
    public var linkRange: NSRange

    // 可以单独设置且覆盖label的3个参数
    public var linkTextAttributes: [NSAttributedString.Key: Any] = [:]
    public var activeLinkTextAttributes: [NSAttributedString.Key: Any] = [:]

    public var didClickLinkBlock: ((ALLink, String, ALLinkLabel) -> Void)?
    public var didLongPressLinkBloc: ((ALLink, String, ALLinkLabel) -> Void)?

    public required init(type: ALLinkType, value: String, range: NSRange) {
        self.linkType = type
        self.linkValue = value
        self.linkRange = range
    }

    public convenience init(type: ALLinkType, value: String, range: NSRange, linkTextAttributes: [NSAttributedString.Key: Any], activeLinkTextAttributes: [NSAttributedString.Key: Any]) {
        self.init(type: type, value: value, range: range)
        self.linkTextAttributes = linkTextAttributes
        self.activeLinkTextAttributes = activeLinkTextAttributes
    }

    public func set(didClickLink block: @escaping ((ALLink, String, ALLinkLabel) -> Void)) -> Void {
        self.didClickLinkBlock = block
    }

    public func set(didLongPressLink block: @escaping ((ALLink, String, ALLinkLabel) -> Void)) -> Void {
        self.didLongPressLinkBloc = block
    }
}

public class ALLinkLabel: ALLabel {
    /// 默认自动检测除了@和#以外的全部话题
    public var dataDetectorTypes: ALDataDetectorTypes = [.url, .phoneNumber, .email, .attributedLink] {
        didSet {
            reSetText()
        }
    }
    public var dataDetectorTypesOfAttributedLinkValue: ALDataDetectorTypes = .none {
        didSet {
            reSetText()
        }
    }
    public var linkTextAttributes: [NSAttributedString.Key: Any] = [:] {
        didSet {
            reSetText()
        }
    }
    public var activeLinkTextAttributes: [NSAttributedString.Key: Any] = [:] {
        didSet {
            reSetText()
        }
    }
    // 这个主要是为了不会在点击非常快的情况下，激活的链接样式没有体现，这个delay可以让其多体现一会，显得有反馈
    public var activeLinkToNilDelay: TimeInterval = 0.3
    public var allowLineBreakInsideLinks: Bool = true {
        didSet {
            if oldValue != allowLineBreakInsideLinks {
                reSetText()
            }
        }
    }
    public var beforeAddLinkBlock: ((ALLink) -> Void)?
    // 优先级比delegate高
    public var didClickLinkBlock: ((ALLink, String, ALLinkLabel) -> Void)?
    public var didLongPressLinkBlock: ((ALLink, String, ALLinkLabel) -> Void)?
    public var delegate: ALLinkLabelDelegate? // 优先级没有block高
    // 私有属性
    var links: Array<ALLink> = [] // 可以遍历针对自定义
    var activeLink: ALLink? {
        didSet {
            if activeLink != oldValue {
                self.reSetText()
                CATransaction.flush()
            }
        }
    }
    var dontReCreateLinks: Bool = false
    // 属于自定义手势
    lazy var longPressGestureRecognizer: UILongPressGestureRecognizer = {
        let longPress = UILongPressGestureRecognizer.init(target: self, action: #selector(longPressGestureDidFire(_:)))
        longPress.delegate = self
        return longPress
    }()
    public override var attributedText: NSAttributedString? {
        willSet {
            // 先提取出来links
            if !self.dontReCreateLinks {
                if let new = newValue {
                    self.links = ALLinkLabel.links(string: new, dataDetectorTypes: self.dataDetectorTypes, dataDetextorTypesOfAttributedLinkValue: self.dataDetectorTypesOfAttributedLinkValue, beforeAddLinkBlock: self.beforeAddLinkBlock)
                    self.activeLink = nil
                }
            }
        }
    }
    public override var text: String? {
        willSet {
            if !self.dontReCreateLinks {
                if let new = newValue {
                    self.links = ALLinkLabel.links(string: new, dataDetectorTypes: self.dataDetectorTypes, beforeAddLinkBlock: self.beforeAddLinkBlock)
                    self.activeLink = nil
                }
            }
        }
    }
    override func reSetText() {
        self.dontReCreateLinks = true
        super.reSetText()
        self.dontReCreateLinks = false
    }

    override func commonInit() {
        super.commonInit()
        self.isExclusiveTouch = true
        self.isUserInteractionEnabled = true
        self.activeLinkToNilDelay = 0.3
        self.addGestureRecognizer(self.longPressGestureRecognizer)
    }
    override func attributedTextForTextStorageFromLabelProperties() -> NSMutableAttributedString {
        let attributedString = super.attributedTextForTextStorageFromLabelProperties()
        // 默认的链接样式不是我们想要的，去除它
        attributedString.removeAttribute(NSAttributedString.Key.link, range: NSMakeRange(0, attributedString.length))
        // 检测是否有链接，有的话，就直接g设置连接样式
        for link in self.links {
            var attributes:[NSAttributedString.Key:Any] = [:]
            if link.isEqual(self.activeLink) {
                attributes = link.activeLinkTextAttributes.count == 0 ? self.activeLinkTextAttributes : link.activeLinkTextAttributes
                if attributes.count == 0 {
                    attributes = [.foregroundColor: kDefaultLinkColorForLinkLabel, NSAttributedString.Key.backgroundColor: KDefaultActiveLinkBackgroundColorForLinkLabel]
                }
            } else {
                attributes = link.linkTextAttributes.count == 0 ? self.linkTextAttributes : link.linkTextAttributes
                if attributes.count == 0 {
                    attributes = [.foregroundColor: kDefaultLinkColorForLinkLabel]
                }
            }
            attributedString.addAttributes(attributes, range: link.linkRange)
        }
        return attributedString
    }
    
    func set(text:String, links: Array<ALLink>) -> Void {
        self.links = links
        self.activeLink = nil
        super.text = text
    }
    func set(text:NSAttributedString, links: Array<ALLink>) -> Void {
        self.links = links
        self.activeLink = nil
        super.attributedText = text
    }
    func linkAtPoint(location: CGPoint) -> ALLink {
        return ALLink.init(type: .none, value: "", range: NSRange.init())
    }
    /// 设置文本后添加link， 注意如果在此之后设置了text、attributeText、dataDetectorTypes或dataDetectorTypesOfAttributedLinkValue属性，添加的link会丢失
    ///
    /// - Parameter link: 要添加的link
    /// - Returns: 是否添加成功
    public func add(link: ALLink) -> Bool {
        return self.addLinks(links: [link]).count > 0
    }
    public func addLink(type: ALLinkType, value: String, range: NSRange) -> ALLink? {
        let link = ALLink.init(type: type, value: value, range: range)
        return self.add(link: link) ? link : nil
    }
    public func addLinks(links: Array<ALLink>) -> Array<ALLink> {
        var validLinks: [ALLink] = []
        for link in links {
            if NSMaxRange(link.linkRange) > self.text?.count ?? -1 {
                continue
            }
            // 检测是否此位置已经有东西占用
            for aLink in self.links {
                if NSMaxRange(NSIntersectionRange(aLink.linkRange, link.linkRange)) > 0 {
                    continue
                }
            }
            self.beforeAddLinkBlock?(link)
            self.links.append(link)
            validLinks.append(link)
        }
        reSetText()
        return validLinks
    }

    /// 一般用在修改了某些link的样式属性之后效果不会立马启用，使用此方法可以启用
    func invalidateDisplayForLinks() -> Void {
        reSetText()
    }

    // MARK: - 布局相关
    public func layoutManager(_ layoutManager: NSLayoutManager, shouldBreakLineByWordBeforeCharacterAt charIndex: Int) -> Bool {
        if self.lineBreakMode == .byCharWrapping {
            return false
        }
        if self.allowLineBreakInsideLinks {
            return true
        }

        //让在林杰区间下，尽量不要break
        for link in self.links {
            if NSLocationInRange(charIndex, link.linkRange) {
                return false
            }
        }
        return true
    }

    public func setDidClickLink(block: @escaping ((ALLink, String, ALLinkLabel) -> Void)) -> Void {
        self.didClickLinkBlock = block
    }

    public func setDidLongPressLink(block: @escaping ((ALLink, String, ALLinkLabel) -> Void)) -> Void {
        self.didLongPressLinkBlock = block
    }

    // MARK: - 类方法
    static func batchLinks(strings: [Any], dataDetectorTypes: ALDataDetectorTypes, dataDetectorTypesOfAttributedLinkValue: ALDataDetectorTypes, beforeAddLinkBlock:((ALLink) -> Void)?, callback: (([[ALLink]]) -> Void)?) {
        var results:[String: Array<ALLink>] = [:]
        let queue = DispatchQueue.init(label: "queue")
        let group = DispatchGroup.init()
        for strAny in strings {
            queue.async(group: group, qos: DispatchQoS.default, flags: DispatchWorkItemFlags.assignCurrentContext) {
                group.enter()
                var links: [ALLink] = []
                var key = ""
                switch strAny {
                case let str as String:
                    links = self.links(string: str, dataDetectorTypes: dataDetectorTypes, beforeAddLinkBlock: beforeAddLinkBlock)
                    key = str
                case let attr as NSAttributedString:
                    links = self.links(string: attr, dataDetectorTypes: dataDetectorTypes, dataDetextorTypesOfAttributedLinkValue: dataDetectorTypesOfAttributedLinkValue, beforeAddLinkBlock: beforeAddLinkBlock)
                    key = attr.string
                default:
                    break
                }
                if links.count == 0 || key.count == 0 {
                    group.leave()
                    return
                }
                objc_sync_enter(results)
                results[key] = links
                group.leave()
                objc_sync_exit(results)
            }
        }
        group.notify(queue: queue) {
            // 重新排列
            var resultArr = [[ALLink]]()
            for strAny in strings {
                var key = ""
                switch strAny {
                case let str as String:
                    key = str
                case let attr as NSAttributedString:
                    key = attr.string
                default:
                    break
                }
                if key.count != 0 && results[key] != nil{
                    resultArr.append(results[key]!)
                }
            }
            DispatchQueue.main.async {
                callback?(resultArr)
            }
        }
    }
    static func links(string: NSAttributedString, dataDetectorTypes:ALDataDetectorTypes, dataDetextorTypesOfAttributedLinkValue: ALDataDetectorTypes, beforeAddLinkBlock: ((ALLink) -> Void)?) -> Array<ALLink> {
        if dataDetectorTypes == .none {
            return []
        }
        if string.length <= 0 {
            return []
        }
        var links: Array<ALLink> = []
        if (dataDetectorTypes.rawValue&ALDataDetectorTypes.attributedLink.rawValue) != 0  {
            string.enumerateAttribute(NSAttributedString.Key.link, in: NSMakeRange(0, string.length), options: NSAttributedString.EnumerationOptions.init(rawValue: 0)) { (value: Any?, range:NSRange, stop:UnsafeMutablePointer<ObjCBool>) in
                guard let value = value else { return }
                var linkValue = ""
                switch value {
                case let someUrl as URL:
                    linkValue = someUrl.absoluteString
                case let someString as String:
                    linkValue = someString
                case let someAttr as NSAttributedString:
                    linkValue = someAttr.string
                default:
                    break
                }
                if linkValue.count > 0 {
                    let link = ALLink.init(type: self.linkTypeOf(string: linkValue, dataDetectorTypes: dataDetextorTypesOfAttributedLinkValue), value: linkValue, range: range)
                    beforeAddLinkBlock?(link)
                    links.append(link)
                }
            }
        }
        let otherLinks = self.links(string: string.string, dataDetectorTypes: dataDetectorTypes, beforeAddLinkBlock: beforeAddLinkBlock)
        links.append(contentsOf: otherLinks)
        return links
    }

    static func links(string: String, dataDetectorTypes:ALDataDetectorTypes, beforeAddLinkBlock: ((ALLink) -> Void)?) -> Array<ALLink> {
        if dataDetectorTypes == .none {
            return []
        }
        if string.count <= 0 {
            return []
        }
        var links: Array<ALLink> = []

        let regexps = ALLinkLabel.regexps(dataDetextorTypes: dataDetectorTypes)
        let textRange = NSMakeRange(0, string.count)
        for regexp in regexps {
            if let reg = try? NSRegularExpression.init(pattern: regexp, options: NSRegularExpression.Options.init(rawValue: 0)) {
                reg.enumerateMatches(in: string, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: textRange) { (result:NSTextCheckingResult?, flags, stop) in
                    guard let result = result else { return }
                    // 去重处理
                    for link in links {
                        if NSMaxRange(NSIntersectionRange(link.linkRange, result.range)) > 0 {
                            return
                        }
                    }
                    // 这个刚好和ALLinkType对应
                    guard let linkTypeRawValue = KAllRegexps.firstIndex(of: regexp) else { return }
                    let linkType = ALLinkType.init(rawValue: UInt(linkTypeRawValue + 1)) ?? .none
                    if linkType != .none {
                        let value = string[Range.init(result.range, in: string) ?? string.startIndex..<string.endIndex]
                        let link = ALLink.init(type: linkType, value:String.init(value), range: result.range)
                        beforeAddLinkBlock?(link)
                        links.append(link)
                    }
                }
            }
        }
        return links
    }

    static func regexps(dataDetextorTypes: ALDataDetectorTypes) -> Array<String> {
        let all: [ALDataDetectorTypes] = [.url, .phoneNumber, .email, .userHandle, .hashTag]
        var regexps: Array<String> = []
        for i in 0..<KAllRegexps.count {
            if dataDetextorTypes.contains(all[i]) {
                regexps.append(KAllRegexps[i])
            }
        }
        // 保证电话号码的优先级最低
        if regexps.contains(KPhoneNumberRegularExpression) {
            regexps = regexps.filter { $0 != KPhoneNumberRegularExpression }
            regexps.append(KPhoneNumberRegularExpression)
        }
        return regexps
    }

    static func linkTypeOf(string: String, dataDetectorTypes: ALDataDetectorTypes) -> ALLinkType {
        if dataDetectorTypes == .none {
            return .other
        }
        let regeps = self.regexps(dataDetextorTypes: dataDetectorTypes)
        let textRange = NSMakeRange(0, string.count)
        for regep in regeps {
            guard let reg = try? NSRegularExpression.init(pattern: regep, options: NSRegularExpression.Options.init(rawValue: 0)) else {
                return .other
            }
            if let result = reg.firstMatch(in: string, options: NSRegularExpression.MatchingOptions.anchored, range: textRange) {
                if NSEqualRanges(result.range, textRange) {
                    // 这个刚好和ALLinkType对应
                    guard let linkTypeRawValue = KAllRegexps.firstIndex(of: regep) else { return .other }
                    let linkType = ALLinkType.init(rawValue: UInt(linkTypeRawValue)) ?? .other
                    return linkType
                }
            }
        }
        return .other
    }

    /// 根据点击的点寻找交互的链接
    ///
    /// - Parameter location: 点击的点
    /// - Returns: 点击的链接
    func linkAtPoint(_ location: CGPoint) -> ALLink? {
        if self.links.count <= 0 || self.text?.count == 0 || self.textContainer.size.width <= 0 || self.textContainer.size.height <= 0 {
            return nil
        }
        var textOffset: CGPoint = CGPoint.zero
        // 在执行usedRectForTextContainer之前最好执行下glyphTangeFTextContainer relayout
        self.layoutManager.glyphRange(for: self.textContainer)
        textOffset = self.textOffset(textSize: self.layoutManager.usedRect(for: self.textContainer).size)

        var _location = CGPoint.zero
        // location转换为在textContainer的绘制区域的坐标
        _location.x = location.x - textOffset.x
        _location.y = location.y - textOffset.y

        // 获取触摸的自行
        let glyphIdx = self.layoutManager.glyphIndex(for: _location, in: self.textContainer)
        // Apple文档上说， 如果location区域没有字形， 可能返回最近字形的index， 所以我们再找到这个自行所处于的rect来确认
        let glyphRect = self.layoutManager.boundingRect(forGlyphRange: NSMakeRange(glyphIdx, 1), in: self.textContainer)
        if !glyphRect.contains(_location) {
            return nil
        }
        let charIndex = self.layoutManager.characterIndexForGlyph(at: glyphIdx)

        // 找到了charIndex，然后再去c寻找是否这个字处于链接内部
        for link in self.links {
            if NSLocationInRange(charIndex, link.linkRange) {
                return link
            }
        }
        return nil
    }
}


// MARK: - UIGestureRecognizerDelegate 及长按事件
extension ALLinkLabel: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let link = self.linkAtPoint(touch.location(in: self)) else {
            return false
        }
        if (self.delegate != nil && self.delegate!.isLongPressNeed) || self.didLongPressLinkBlock != nil || link.didLongPressLinkBloc != nil {
            return true
        }
        return false
    }

    @objc func longPressGestureDidFire(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            guard let link = self.linkAtPoint(gesture.location(in: self)), let text = self.text else { return }
            guard let range = Range.init(link.linkRange, in: text) else { return }
            let linkText = String.init(text[range])
            // 告诉外面已进点击了某链接
            if let block = link.didLongPressLinkBloc {
                block(link, linkText, self)
            } else if let block = self.didLongPressLinkBlock {
                block(link, linkText, self)
            } else {
               self.delegate?.didLongPress(link: link, linkText: linkText, linkLabel: self)
            }
        }
    }
}


// MARK: - touch事件
extension ALLinkLabel {
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        self.activeLink = self.linkAtPoint(touch.location(in: self))
        // 如果触发了消息就拦截点击
        if self.activeLink == nil {
            super.touchesBegan(touches, with: event)
        }
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        if self.activeLink != nil {
            if self.activeLink?.isEqual(self.linkAtPoint(touch.location(in: self))) ?? false {
                self.activeLink = nil
            }
        } else {
            super.touchesMoved(touches, with: event)
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let activeLink = self.activeLink, let text = self.text {
            guard let range = Range.init(activeLink.linkRange, in: text) else { return }
            let linkText = String.init(text[range])
            // 告诉外面已进点击了某链接
            if let block = activeLink.didClickLinkBlock {
                block(activeLink, linkText, self)
            } else if let block = self.didClickLinkBlock {
                 block(activeLink, linkText, self)
            } else {
                self.delegate?.didClick(link: activeLink, linkText: linkText, linkLabel: self)
            }
            self.perform(#selector(setActiveLink(link:)), with: nil, afterDelay: self.activeLinkToNilDelay)
            // 延迟几秒将activeLink 置为空
        } else {
            super.touchesEnded(touches, with: event)
        }
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.activeLink != nil {
            self.activeLink = nil
        } else {
            super.touchesCancelled(touches, with: event)
        }
    }

    @objc
    func setActiveLink(link: ALLink?) -> Void {
        self.activeLink = link
    }
}

public protocol ALLinkLabelDelegate {
    var isLongPressNeed: Bool { get }
    func didClick(link: ALLink, linkText: String, linkLabel: ALLinkLabel) -> Void
    func didLongPress(link: ALLink, linkText: String, linkLabel: ALLinkLabel) -> Void
}

public extension ALLinkLabelDelegate {
    var isLongPessNeed: Bool {
        return false
    }
    func didLongPress(link: ALLink, linkText: String, linkLabel: ALLinkLabel) -> Void {

    }
}

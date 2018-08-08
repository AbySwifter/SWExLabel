//
//  SWTextAttachment.swift
//  Pods-SWExLabel_Example
//
//  Created by aby on 2018/8/8.
//
import Foundation
import UIKit

typealias ImageBlock = (CGRect, NSTextContainer?, Int, SWTextAttachment) -> UIImage

public class SWTextAttachment: NSTextAttachment {

    var width: CGFloat = 0
    var height: CGFloat = 0
    
    /// 高优先级的高度设置，宽度根据imageAspectRatio来决定
    var lineHeightMultiple: CGFloat = 0
    var imageAspectRatio: CGFloat = 0
    
    var imageBlock: ImageBlock?
    
    // MARK: - 初始化方法
    init(width: CGFloat, height: CGFloat, imageBlock: @escaping ImageBlock) {
        super.init(data: nil, ofType: nil)
        self.width = width
        self.height = height
        self.imageBlock = imageBlock
    }
    
    init(lineHeightMultiple: CGFloat, imageAspectRatio: CGFloat, imageBlock: @escaping ImageBlock) {
        super.init(data: nil, ofType: nil)
        assert(lineHeightMultiple > 0, "lineHeightMultiple必须大于0")
        self.lineHeightMultiple = lineHeightMultiple
        self.imageAspectRatio = imageAspectRatio
        self.imageBlock = imageBlock
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override func image(forBounds imageBounds: CGRect, textContainer: NSTextContainer?, characterIndex charIndex: Int) -> UIImage? {
        if let image = self.imageBlock?(imageBounds, textContainer, charIndex, self) {
            return image
        }
        return super.image(forBounds: imageBounds, textContainer: textContainer, characterIndex: charIndex)
    }
    
    public override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        if self.imageBlock != nil {
            var _width = self.width
            var _height = self.height
            // 找到其是否设置字体，如果有，根据字体的descender调整下位置
            let font: UIFont? = textContainer?.layoutManager?.textStorage?.attribute(NSAttributedStringKey.font, at: charIndex, effectiveRange: nil) as? UIFont
            let baseLineHeight = font?.lineHeight ?? lineFrag.size.height
            
            if self.lineHeightMultiple > 0 {
                _height = baseLineHeight*self.lineHeightMultiple;
                if self.imageAspectRatio > 0 {
                    _width = _height * self.imageAspectRatio
                } else {
                    _width = _height
                }
            } else {
                if _width == 0 && _height == 0 {
                    _height = lineFrag.size.height
                    _width = lineFrag.size.height
                } else if _width == 0 && _height != 0 {
                    _width = _height
                } else if (_height == 0 && _width != 0) {
                    _height = _width
                }
            }
            var y = font?.descender ?? 0
            y -= (_height - baseLineHeight) / 2
            
            return CGRect.init(x: 0, y: y, width: _width, height: _height)
        }
        return super.attachmentBounds(for: textContainer, proposedLineFragment: lineFrag, glyphPosition: position, characterIndex: charIndex)
    }
    
}

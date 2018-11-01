//
//  ALTextAttachment.swift
//  ExpressionDemo
//
//  Created by aby on 2018/9/30.
//  Copyright © 2018 aby. All rights reserved.
//

import UIKit

/// 用于处理文本中的附件信息
public class ALTextAttachment: NSTextAttachment {
    var width: CGFloat = 0
    var height: CGFloat = 0

    var lineHeightMultiple: CGFloat = 0 {
        willSet {
            assert(newValue > 0, "lineHeigthMultiple 必须大于 0")
        }
    }
    var imageAspectRatio: CGFloat = 0

    var imageBlock: ((CGRect, NSTextContainer?, Int, ALTextAttachment) -> UIImage)?

    public convenience init(width: CGFloat, height: CGFloat, imageBlock: @escaping (CGRect, NSTextContainer?, Int, ALTextAttachment) -> UIImage) {
        self.init()
        self.width = width
        self.height = height
        self.imageBlock = imageBlock
    }

    public convenience init(lineHeightMultiple:CGFloat, imageAspectRatio:
        CGFloat, imageBlock: @escaping (CGRect, NSTextContainer?, Int, ALTextAttachment) -> UIImage) {
        self.init()
        self.lineHeightMultiple = lineHeightMultiple
        self.imageAspectRatio = imageAspectRatio
        self.imageBlock = imageBlock
    }

    // 重写以便绘制
    override public func image(forBounds imageBounds: CGRect, textContainer: NSTextContainer?, characterIndex charIndex: Int) -> UIImage? {
        if let block = self.imageBlock {
            return block(imageBounds, textContainer, charIndex, self)
        }
        return super.image(forBounds: imageBounds, textContainer: textContainer, characterIndex: charIndex)
    }

    // 重写以返回附件的大小
    override public func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        if let _ = self.imageBlock {
            var width = self.width
            var height = self.height
            let font = textContainer?.layoutManager?.textStorage?.attribute(NSAttributedString.Key.font, at: charIndex, effectiveRange: nil) as? UIFont
            let baseLineHeigth: CGFloat = font?.lineHeight ?? lineFrag.size.height
            if self.lineHeightMultiple > 0 {
                width = baseLineHeigth * self.lineHeightMultiple
                height = width
                if self.imageAspectRatio > 0 {
                    width = height*imageAspectRatio
                }
            } else {
                if width == 0 && height == 0 {
                    width = lineFrag.size.height
                    height = lineFrag.size.height
                } else if width == 0 && height != 0 {
                    width = height
                } else if height == 0 && width != 0 {
                    height = width
                }
            }
            var y = font?.descender ?? 0
            if y != 0 {
                y -= (height - baseLineHeigth)/2
            }
            return CGRect.init(x: 0, y: y, width: width, height: height)
        }
        return  super.attachmentBounds(for: textContainer, proposedLineFragment: lineFrag, glyphPosition: position, characterIndex: charIndex)
    }

}

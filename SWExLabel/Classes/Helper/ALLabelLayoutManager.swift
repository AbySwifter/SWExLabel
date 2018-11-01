//
//  ALLabelLayoutManager.swift
//  ExpressionDemo
//
//  Created by aby on 2018/10/8.
//  Copyright © 2018 aby. All rights reserved.
//
import UIKit

class ALLabelLayoutManager: NSLayoutManager {
    var lastDrawPoint: CGPoint = CGPoint.zero
    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        self.lastDrawPoint = origin
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)
        self.lastDrawPoint = CGPoint.zero
    }

    override func fillBackgroundRectArray(_ rectArray: UnsafePointer<CGRect>, count rectCount: Int, forCharacterRange charRange: NSRange, color: UIColor) {

        guard let ctx = UIGraphicsGetCurrentContext() else {
            super.fillBackgroundRectArray(rectArray, count: rectCount, forCharacterRange: charRange, color: color)
            return
        }
        ctx.saveGState()
        color.setFill()
        let glyphRange = self.glyphRange(forCharacterRange: charRange, actualCharacterRange: nil)
        let textOffset = self.lastDrawPoint
        var lineRange = NSMakeRange(glyphRange.location, 1)
        while NSMaxRange(lineRange)<=NSMaxRange(glyphRange) {
            // 这里防止这行没有用到的区域也绘制上背景色，例如收到word wrap，center alignment影响后，每行文字没有占满的时候
//            var lineBounds = self.lineFragmentRect(forGlyphAt: lineRange.location, effectiveRange: &lineRange)
            var lineBounds = self.lineFragmentUsedRect(forGlyphAt: lineRange.location, effectiveRange: &lineRange)
            lineBounds.origin.x += textOffset.x
            lineBounds.origin.y += textOffset.y

            // 找到这行具有背景色文字的区域
            var glyphRangeInLine = NSIntersectionRange(glyphRange, lineRange)
            let truncatedGlyphRange = self.truncatedGlyphRange(inLineFragmentForGlyphAt: glyphRangeInLine.location)
            if truncatedGlyphRange.location != NSNotFound {
                // 这里的glyphRangeInline本身可能会带有被省略的区间，而我们下面计算最大行高和最小drawY的实现是不需要考虑省略区间的，否则也可能计算有误。所以在这里过滤掉
                let sameRange = NSIntersectionRange(glyphRangeInLine, truncatedGlyphRange)
                if sameRange.length > 0 && NSMaxRange(sameRange)==NSMaxRange(glyphRangeInLine) {
                    //我们这里先只处理tail模式的
                    //而经过测试truncatedGlyphRangeInLineFragmentForGlyphAtIndex暂时只支持NSLineBreakByTruncatingTail模式
                    //其他两种暂时也不会用，即使用，现在通过TextKit的话也没法获取
                    glyphRangeInLine = NSMakeRange(glyphRangeInLine.location, sameRange.location-glyphRangeInLine.location)
                }
            }

            if glyphRangeInLine.length > 0 {
                var startDrawY = CGFloat.greatestFiniteMagnitude
                var maxLineHeigh = 0.0
                for glyphIndex in glyphRangeInLine.location..<NSMaxRange(glyphRangeInLine) {
                    let charIndex = self.characterIndexForGlyph(at: glyphIndex)
                    let font = self.textStorage?.attribute(NSAttributedString.Key.font, at: charIndex, effectiveRange: nil)

                    let location = self.location(forGlyphAt: glyphIndex)
                    let fontAscender = (font as? UIFont)?.ascender ?? 0
                    startDrawY =  fmin(startDrawY, lineBounds.origin.y + location.y - fontAscender)
                    maxLineHeigh = fmax(maxLineHeigh, Double((font as? UIFont)?.lineHeight ?? 0))
                }
                var size = lineBounds.size
                var orgin = lineBounds.origin

                // 调整下高度和绘制y值， 这样做的目的是为了不会受到lineheightMultiple和lineSpcing的影响，引起背景色绘制的不工整
                orgin.y = startDrawY
                size.height = CGFloat(maxLineHeigh)

                lineBounds.size = size
                lineBounds.origin = orgin
            }

            for i in 0..<rectCount {
                let validRect = rectArray[i].intersection(lineBounds)
                if !validRect.isEmpty {
                    ctx.fill(validRect)
                }
            }
            lineRange = NSMakeRange(NSMaxRange(lineRange), 1)
        }
        ctx.restoreGState()
    }
}

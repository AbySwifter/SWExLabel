//
//  SimpleViewController.swift
//  SWExLabel_Example
//
//  Created by aby on 2018/8/8.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import SWExLabel

class SimpleViewController: UIViewController {

    let str: String = "人生若只如初见，[坏笑]何事秋风悲画扇。http://baidu.com等闲变却故人心[亲亲]，dudl@qq.com却道故人心易变。13612341234骊山语罢清宵半[心碎]，泪雨零铃终不怨[左哼哼]。#何如 薄幸@锦衣郎，比翼连枝当日愿。"
    lazy var label: ALLinkLabel = {
        let label = ALLinkLabel.init(frame: CGRect.zero)
        label.backgroundColor = UIColor.init(white: 0.920, alpha: 1.000)
        return label
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        stepLabel()
        let exp = ALExpression.init(regex: "\\[[a-zA-Z0-9\\u4e00-\\u9fa5]+\\]", plistName: "Expression", bundleName: "ClippedExpression")
        let attr = "人生若只如初见，[坏笑]何事秋风悲画扇。http://baidu.com等闲变却故人心[亲亲]，dudl@qq.com却道故人心易变。13612341234骊山语罢清宵半[心碎]，泪雨零铃终不怨[左哼哼]。#何如 薄幸@锦衣郎，比翼连枝当日愿。".expressionAttributedString(expression: exp)
        let m_attr = NSMutableAttributedString.init(attributedString: attr)
        m_attr.addAttribute(NSAttributedString.Key.backgroundColor, value: UIColor.green, range: NSMakeRange(0, m_attr.length))
        m_attr.addAttribute(NSAttributedString.Key.underlineStyle, value: NSUnderlineStyle.styleSingle.rawValue, range: NSMakeRange(0, m_attr.length))
        label.attributedText = m_attr
        label.setDidClickLink { (link, text, label) in
            let alert = UIAlertController.init(title: "点击了", message: "link: \(link.linkType), text: \(text)", preferredStyle: UIAlertController.Style.alert)
            let action = UIAlertAction.init(title: "取消", style: UIAlertAction.Style.cancel, handler: { (action) in
                alert.dismiss(animated: true, completion: nil)
            })
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
        }
        self.label.frame.size.width = view.frame.width - 20
        self.label.sizeToFit()
        self.label.center.x = self.view.center.x
        self.label.frame.origin.y = 340

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func stepLabel() -> Void {
        view.addSubview(label)
        label.textColor = UIColor.red
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textInsets = UIEdgeInsets.init(top: 5, left: 5, bottom: 5, right: 5)
        label.allowLineBreakInsideLinks = false
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

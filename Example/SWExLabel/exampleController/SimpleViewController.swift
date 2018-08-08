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

    @IBOutlet weak var testLabel: UILabel!
    let str: String = "人生若只如初见，[坏笑]何事秋风悲画扇。http://baidu.com等闲变却故人心[亲亲]，dudl@qq.com却道故人心易变。13612341234骊山语罢清宵半[心碎]，泪雨零铃终不怨[左哼哼]。#何如 薄幸@锦衣郎，比翼连枝当日愿。"
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let expression = SWExpression.init(regex: "\\[[a-zA-Z0-9\\u4e00-\\u9fa5]+\\]", plistName: "Expression", bundleName: "ClippedExpression")
        let attributeString = self.str.expressionAttributedString(expression: expression)
        testLabel.attributedText = attributeString
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

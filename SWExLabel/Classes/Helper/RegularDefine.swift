//
//  RegularDefine.swift
//  ExpressionDemo
//
//  Created by aby on 2018/10/10.
//  Copyright © 2018 aby. All rights reserved.
//

import Foundation

let KURLRegularExpression = "((http[s]{0,1}|ftp)://[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,6})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|(www.[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,6})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|(((http[s]{0,1}|ftp)://|)((?:(?:25[0-5]|2[0-4]\\d|((1\\d{2})|([1-9]?\\d)))\\.){3}(?:25[0-5]|2[0-4]\\d|((1\\d{2})|([1-9]?\\d))))(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)"
let KPhoneNumberRegularExpression = "\\d{3}-\\d{8}|\\d{3}-\\d{7}|\\d{4}-\\d{8}|\\d{4}-\\d{7}|1+[3578]+\\d{9}|[+]861+[3578]+\\d{9}|861+[3578]+\\d{9}|1+[3578]+\\d{1}-\\d{4}-\\d{4}|\\d{8}|\\d{7}|400-\\d{3}-\\d{4}|400-\\d{4}-\\d{3}"
let KEmailRegularExpression = "[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,6}"
let KUserHandleRegularExpression = "@[\\u4e00-\\u9fa5\\w\\-]+"
let KHashtagRegularExpression = "#([\\u4e00-\\u9fa5\\w\\-]+)"

let KAllRegexps = [KURLRegularExpression, KPhoneNumberRegularExpression, KEmailRegularExpression, KUserHandleRegularExpression, KHashtagRegularExpression]

//
//  ViewController.swift
//  SWExLabel
//
//  Created by wyx96553@163.com on 08/07/2018.
//  Copyright (c) 2018 wyx96553@163.com. All rights reserved.
//

import UIKit

import SWExLabel

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var dataSource: Array = ["普通文本表情转化"]
    var colorArr  = ["FF0000", "FF7F00", "FFFF00", "00FF00", "00FFFF", "0000FF", "8B00FF"]
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.tableView.rowHeight = 90
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: - delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: MainTableViewCell = tableView.dequeueReusableCell(withIdentifier: "MainTableViewCell", for: indexPath) as! MainTableViewCell
        cell.titleLabel.text = dataSource[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
}


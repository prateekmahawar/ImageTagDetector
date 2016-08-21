//
//  TagsTVC.swift
//  imagga
//
//  Created by Prateek Mahawar on 21/08/16.
//  Copyright © 2016 Prateek Mahawar. All rights reserved.
//

import UIKit

class TagsTVC: UITableViewController {

    var tags = [String]()
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
   
        return 25
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)
               cell.textLabel?.text = "\(indexPath.row + 1) . \(tags[indexPath.row])"
    
            return cell
       
    }

}

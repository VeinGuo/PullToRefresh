//
//  ViewController.swift
//  PullToRefresh
//
//  Created by Vein on 2017/9/21.
//  Copyright © 2017年 Vein. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    var dataSource = [Int]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        tableView.tableFooterView = UIView()
        dataSource = [1, 2, 3, 4, 6, 7, 8, 9, 10, 1, 2, 3, 4, 6, 7, 8, 9, 10]
        
        tableView.vg_addPullToRefresh {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(1.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
                self.dataSource = [1, 2, 3, 4, 6, 7, 8, 9, 10, 1, 2, 3, 4, 6, 7, 8, 9, 10]
                self.tableView.vg_stopLoading()
                self.tableView.reloadData()
            })
        }
        tableView.vg_setPullToRefreshBackgroundColor(#colorLiteral(red: 0.8308480382, green: 0.8308677077, blue: 0.8308570981, alpha: 1))
        tableView.vg_headerIndicatorTintColor(tintColor: #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1))
        
        tableView.vg_addInfiniteScrolling {
            self.delay(time: 2) {
                for item in 21...40 {
                    self.dataSource.append(item)
                }
                self.tableView.vg_stopMoreLoding()
                self.tableView.reloadData()
            }
        }
    }
    
    func delay(time: TimeInterval, completionHandler: @escaping ()-> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + time) {
            completionHandler()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
        cell.textLabel?.text = "Vein\(indexPath.row)"
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}


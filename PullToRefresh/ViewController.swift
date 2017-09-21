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
    fileprivate var indicator = VGPullToRefreshLoadingIndicator()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let rect = CGRect(x: 100, y: 200, width: 30.0, height: 30.0)
        indicator = VGPullToRefreshLoadingIndicator(frame: rect)
        view.addSubview(indicator)
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
        return 20
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
        indicator.stopAnimating()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = max(-scrollView.contentInset.top - scrollView.contentOffset.y, 0)
        let pullProgress: CGFloat = offsetY / 95.0
        indicator.setPullProgress(pullProgress)
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        indicator.startAnimating()
    }
}


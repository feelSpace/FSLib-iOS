//
//  BeltListViewController.swift
//  FSLibIOsDemo
//
//  Created by David on 02.03.20.
//  Copyright © 2020 feelSpace GmbH. All rights reserved.
//

import UIKit

class BeltListViewController: UIViewController {

    // Table view
    @IBOutlet weak var tableView: UITableView!
    
    
    // Reference to the main view controller
    var mainViewController: ViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onBeltFound(_:)),
            name: .beltFound,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onBeltConnectionStateChanged(_:)),
            name: .beltConnectionStateChanged,
            object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(
            self,
            name: .beltFound,
            object: nil)
        NotificationCenter.default.removeObserver(
            self,
            name: .beltConnectionStateChanged,
            object: nil)
    }
    
    /** Handler for connection state change notification. */
    @objc private func onBeltConnectionStateChanged(
        _ notification: Notification) {
        tableView.reloadData()
    }
    
    /** Handler for belt mode change notification. */
    @objc private func onBeltFound(
        _ notification: Notification) {
        tableView.reloadData()
    }

}

extension BeltListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        if let belts = mainViewController?.beltList {
            if (indexPath.row >= 0 && indexPath.row <= belts.count-1) {
                let belt = belts[indexPath.row]
                // Connect and close screen
                mainViewController?.beltController.connectBelt(belt)
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        if let count = mainViewController?.beltList.count {
            return count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "BeltCell") as! BeltCellView
        cell.beltNameLabel.text = "?"
        if let belts = mainViewController?.beltList {
            if (indexPath.row >= 0 && indexPath.row <= belts.count-1) {
                let belt = belts[indexPath.row]
                cell.beltNameLabel.text = belt.name
            }
        }
        return cell
    }
    
    
    
    
}

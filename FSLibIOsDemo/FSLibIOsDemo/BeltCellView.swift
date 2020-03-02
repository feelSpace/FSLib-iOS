//
//  BeltCellView.swift
//  FSLibIOsDemo
//
//  Created by David on 02.03.20.
//  Copyright © 2020 feelSpace GmbH. All rights reserved.
//

import UIKit

class BeltCellView: UITableViewCell {
    
    @IBOutlet weak var beltNameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}

//
//  CryptoCell.swift
//  Crypto
//
//  Created by Никита Бабенко on 11/02/2020.
//  Copyright © 2020 Nikita Babenko. All rights reserved.
//

import UIKit

class CryptoCell: UITableViewCell {

    @IBOutlet weak var symbolLabel: UILabel!
    @IBOutlet weak var volumeLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}

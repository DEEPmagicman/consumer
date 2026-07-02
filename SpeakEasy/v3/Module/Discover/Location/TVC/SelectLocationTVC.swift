//
//  SelectLocationTVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 23/12/25.
//

import UIKit

final class SelectLocationTVC: UITableViewCell {

    @IBOutlet weak var cityName: UILabel!
    @IBOutlet weak var selectedCityImage: UIImageView!

    func configure(with city: MVPCity, isSelected: Bool) {
        cityName.text = city.value
        selectedCityImage.image = isSelected ? Constant.Icon.checkedIcon : Constant.Icon.uncheckedIcon
        
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cityName.text = nil
        selectedCityImage.image = nil
    }
    
}

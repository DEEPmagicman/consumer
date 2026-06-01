//
//  ArtistsTableViewCell.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 01/06/26.
//

import UIKit

final class ArtistsTableViewCell: UITableViewCell {

    // MARK: - Outlets
    @IBOutlet weak var artistImageView: UIImageView!
    @IBOutlet weak var artistNameLabel: UILabel!

    // MARK: - Life Cycle
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    // MARK: - Setup
    private func setupUI() {

        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        artistImageView.clipsToBounds = true
        artistImageView.contentMode = .scaleAspectFill
    }

    // MARK: - Configure
    func configure(name: String, image: UIImage? = nil) {

        artistNameLabel.text = name

        if let image = image {
            artistImageView.image = image
        }
    }

    // MARK: - Actions
    @IBAction func onTapViewAllButton(_ sender: UIButton) {

    }

    // MARK: - Selection
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

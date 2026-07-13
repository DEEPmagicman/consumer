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

    var onViewEvents: (() -> Void)?

    // MARK: - Life Cycle
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        artistImageView.sd_cancelCurrentImageLoad()
        artistImageView.image = nil
        artistNameLabel.text = nil
        onViewEvents = nil
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
    func configure(name: String, image: UIImage? = nil, imageURL: String? = nil) {

        artistNameLabel.text = name
        artistImageView.sd_cancelCurrentImageLoad()

        if let image {
            artistImageView.image = image
        } else if let imageURL,
                  !imageURL.isEmpty,
                  let url = URL(string: imageURL) {
            artistImageView.sd_setImage(
                with: url,
                placeholderImage: UIImage(named: "artistEmptyIcon")
            ) { [weak self] image, _, _, _ in
                guard image == nil else { return }
                self?.artistImageView.image = UIImage(named: "artistEmptyIcon")
            }
        } else {
            artistImageView.image = UIImage(named: "artistEmptyIcon")
        }
    }

    // MARK: - Actions
    @IBAction func onTapViewAllButton(_ sender: UIButton) {
        onViewEvents?()
    }

    // MARK: - Selection
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

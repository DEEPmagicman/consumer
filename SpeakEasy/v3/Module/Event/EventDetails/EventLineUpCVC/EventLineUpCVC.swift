//
//  EventLineUpCVC.swift
//  eventDeatilModule
//
//  Created by MAC on 06/02/26.
//

import UIKit
import SDWebImage

class EventLineUpCVC: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var imageShimmerView: UIView!
    @IBOutlet weak var textSimmerView: UIView!
    
    let artistEmptyIcon = UIImage(named: "artistEmptyIcon")
    private static let imageSide: CGFloat = 60
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configureStaticUI()
    }

    private func configureStaticUI() {
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = UIColor.white.withAlphaComponent(0.12)

        imageView.constraints.forEach { constraint in
            if constraint.firstAttribute == .width || constraint.firstAttribute == .height {
                constraint.constant = Self.imageSide
            }
        }

        nameLbl.font = Constant.Font.geistMedium(size: 12)
        nameLbl.textColor = .white
        nameLbl.textAlignment = .center
        nameLbl.numberOfLines = 2
        nameLbl.lineBreakMode = .byTruncatingTail
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.layer.cornerRadius = imageView.bounds.height / 2
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()

        imageView.sd_cancelCurrentImageLoad()
        imageView.image = artistEmptyIcon
        nameLbl.text = nil
        imageShimmerView.isHidden = true
        textSimmerView.isHidden = true
    }

    deinit {
        imageView.sd_cancelCurrentImageLoad()
    }
    
    func configure(with artistData: ArtistData) {

        let artist = artistData.artist

        imageShimmerView.isHidden = false
        textSimmerView.isHidden = false
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = UIColor.white.withAlphaComponent(0.12)

        nameLbl.text = artist.name
        textSimmerView.isHidden = true

        if let url = artist.lineupImageURL {

            let scale = UIScreen.main.scale
            let targetSize = CGSize(
                width: imageView.bounds.width * scale,
                height: imageView.bounds.height * scale
            )

            imageView.sd_setImage(
                with: url,
                placeholderImage: artistEmptyIcon,
                options: [
                    
                    .continueInBackground,
                    .scaleDownLargeImages
                ],
                context: [
                    .imageThumbnailPixelSize: NSValue(cgSize: targetSize)
                ],
                progress: nil
            ) { [weak self] image, _, _, _ in

                guard let self = self else { return }

                if image == nil {
                    self.imageView.image = artistEmptyIcon
                }

                self.imageShimmerView.isHidden = true
            }

        } else {
            imageView.image = artistEmptyIcon
            imageShimmerView.isHidden = true
        }
    }

    func configureMore() {
        imageView.sd_cancelCurrentImageLoad()
        imageShimmerView.isHidden = true
        textSimmerView.isHidden = true
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        imageView.image = UIImage(named: "addMoreIcon")
        nameLbl.text = "and more.."
    }
}

final class EventLineupBottomSheetVC: UIViewController {

    var artists: [ArtistData] = []

    private let titleLabel = UILabel()
    private let closeButton = AppIconButton()
    private let tableView = UITableView(frame: .zero, style: .plain)

    private let rowHeight: CGFloat = 82
    private let sideInset: CGFloat = 20

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        tableView.reloadData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.applyScreenBgGradient(direction: .bottomToTop)
    }

    deinit {
        tableView.delegate = nil
        tableView.dataSource = nil
        closeButton.removeTarget(nil, action: nil, for: .allEvents)
    }

    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#111111")

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Lineup"
        titleLabel.textColor = .white
        titleLabel.font = Constant.Font.geistRegular(size: 24)

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.iconTypeValue = AppIconType.close.rawValue
        closeButton.iconSize = 14
        closeButton.buttonSize = 40
        closeButton.iconTintColor = .white
        closeButton.addTarget(self, action: #selector(dismissSheet), for: .touchUpInside)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear

        view.addSubview(titleLabel)
        view.addSubview(closeButton)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: sideInset),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor, constant: -12),

            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -sideInset),
            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40),

            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func setupTableView() {
        tableView.register(EventLineupSheetCell.self, forCellReuseIdentifier: EventLineupSheetCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.rowHeight = rowHeight
        tableView.estimatedRowHeight = rowHeight
        tableView.contentInset = .zero
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.alwaysBounceVertical = false
        tableView.isScrollEnabled = true
        tableView.showsVerticalScrollIndicator = true
    }

    @objc private func dismissSheet() {
        dismiss(animated: true)
    }

    private func openInstagram(for artist: Artists) {
        let webUrl = artist.instagramUsername.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !webUrl.isEmpty,
              let url = URL(string: webUrl) else {
            return
        }

        AppHaptic.navigation()
        UIApplication.shared.open(url)
    }
}

extension EventLineupBottomSheetVC: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        artists.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: EventLineupSheetCell.identifier,
            for: indexPath
        ) as? EventLineupSheetCell else {
            return UITableViewCell()
        }

        let artistData = artists[indexPath.row]
        cell.configure(with: artistData.artist, isLast: indexPath.row == artists.count - 1)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard artists.indices.contains(indexPath.row) else { return }
        openInstagram(for: artists[indexPath.row].artist)
    }
}

private final class EventLineupSheetCell: UITableViewCell {

    private let artistImageView = UIImageView()
    private let nameLabel = UILabel()
    private let separatorView = UIView()
    private let artistEmptyIcon = UIImage(named: "artistEmptyIcon")

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        artistImageView.sd_cancelCurrentImageLoad()
        artistImageView.image = artistEmptyIcon
        nameLabel.text = nil
        separatorView.isHidden = false
    }

    deinit {
        artistImageView.sd_cancelCurrentImageLoad()
    }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        artistImageView.translatesAutoresizingMaskIntoConstraints = false
        artistImageView.contentMode = .scaleAspectFill
        artistImageView.clipsToBounds = true
        artistImageView.layer.cornerRadius = 29
        artistImageView.backgroundColor = UIColor.white.withAlphaComponent(0.10)

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.textColor = .white
        nameLabel.font = Constant.Font.geistRegular(size: 20)
        nameLabel.numberOfLines = 2
        nameLabel.lineBreakMode = .byTruncatingTail

        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.backgroundColor = UIColor.white.withAlphaComponent(0.10)

        contentView.addSubview(artistImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(separatorView)

        NSLayoutConstraint.activate([
            artistImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            artistImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            artistImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            artistImageView.widthAnchor.constraint(equalToConstant: 58),
            artistImageView.heightAnchor.constraint(equalToConstant: 58),

            nameLabel.leadingAnchor.constraint(equalTo: artistImageView.trailingAnchor, constant: 19),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            nameLabel.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 12),
            nameLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),

            separatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    func configure(with artist: Artists, isLast: Bool) {
        nameLabel.text = artist.name
        separatorView.isHidden = isLast

        guard let url = artist.lineupImageURL else {
            artistImageView.image = artistEmptyIcon
            return
        }

        let scale = UIScreen.main.scale
        let targetSize = CGSize(width: 58 * scale, height: 58 * scale)

        artistImageView.sd_setImage(
            with: url,
            placeholderImage: artistEmptyIcon,
            options: [.continueInBackground, .scaleDownLargeImages],
            context: [.imageThumbnailPixelSize: NSValue(cgSize: targetSize)],
            progress: nil
        ) { [weak self] image, _, _, _ in
            if image == nil {
                self?.artistImageView.image = self?.artistEmptyIcon
            }
        }
    }
}

private extension Artists {

    var lineupImageURL: URL? {
        let imageKey = artistImage?.key ?? ""
        guard !imageKey.isEmpty else { return nil }

        let finalURLString = imageKey.lowercased().hasPrefix("http")
        ? imageKey
        : "\(SharedURL.amazonStorage)\(imageKey)"

        return URL(string: finalURLString)
    }
}

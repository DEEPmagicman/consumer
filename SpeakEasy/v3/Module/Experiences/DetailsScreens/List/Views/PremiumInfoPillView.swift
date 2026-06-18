//
//  PremiumInfoPillView.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 18/06/26.
//

import UIKit

final class PremiumInfoPillView: UIView {
    
    // MARK: Views
    
    private let glassView = LiquidGlassBackgroundView(
        cornerRadius: 11,
        fillColor: UIColor.white.withAlphaComponent(0.05),
        borderColor: UIColor.white.withAlphaComponent(0.10),
        borderWidth: 0.8
    )
    
    private let iconView = UIImageView()
    
    private let titleLabel = UILabel()
    
    // MARK:
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        glassView.cornerRadius = bounds.height / 2
    }
    
    func setupUI() {
        
        translatesAutoresizingMaskIntoConstraints = false
        
        glassView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(glassView)
        
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .white
        addSubview(iconView)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = Constant.Font.geistRegular(size: 9)
        titleLabel.textColor = UIColor.white
        titleLabel.numberOfLines = 1
        addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            
            heightAnchor.constraint(equalToConstant: 22),
            
            glassView.topAnchor.constraint(equalTo: topAnchor),
            glassView.leadingAnchor.constraint(equalTo: leadingAnchor),
            glassView.trailingAnchor.constraint(equalTo: trailingAnchor),
            glassView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 10),
            iconView.heightAnchor.constraint(equalToConstant: 10),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 5),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    enum Style {
        case guests
        case time
    }
    
    func configure(
        style: Style,
        text: String
    ) {
        
        titleLabel.text = text
        
        switch style {
            
        case .guests:
            iconView.image = UIImage(resource: .guestIcon)
            
        case .time:
            iconView.image = UIImage(resource: .icClock1)
        }
    }
}

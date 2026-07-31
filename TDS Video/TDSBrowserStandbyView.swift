import UIKit

final class TDSBrowserStandbyView: UIView {
    private let gradient = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false

        gradient.colors = [
            UIColor(red: 0.05, green: 0.06, blue: 0.14, alpha: 1).cgColor,
            UIColor(red: 0.18, green: 0.08, blue: 0.31, alpha: 1).cgColor,
            UIColor(red: 0.05, green: 0.20, blue: 0.30, alpha: 1).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        layer.addSublayer(gradient)

        let icon = UIImageView(image: UIImage(systemName: "safari.fill"))
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 42, weight: .medium)

        let title = makeLabel("Your browser is ready", size: 29, weight: .bold, color: .white)
        title.adjustsFontSizeToFitWidth = true
        title.minimumScaleFactor = 0.7

        let subtitle = makeLabel(
            "Choose how you want to send something to the car.",
            size: 16,
            weight: .medium,
            color: UIColor.white.withAlphaComponent(0.76)
        )

        let shareCard = makeCard(
            icon: "square.and.arrow.up",
            title: "Share a URL",
            detail: "Tap Share in Safari or another app, then choose TDS CarPlay."
        )
        let controlCard = makeCard(
            icon: "iphone.gen3.radiowaves.left.and.right",
            title: "Use the iPhone app",
            detail: "Open Browser to enter a URL, choose a favourite, and control the page."
        )

        let cards = UIStackView(arrangedSubviews: [shareCard, controlCard])
        cards.axis = .horizontal
        cards.distribution = .fillEqually
        cards.spacing = 14

        let stack = UIStackView(arrangedSubviews: [icon, title, subtitle, cards])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.setCustomSpacing(22, after: subtitle)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 34),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -34),
            icon.widthAnchor.constraint(equalToConstant: 60),
            icon.heightAnchor.constraint(equalToConstant: 50),
            cards.widthAnchor.constraint(lessThanOrEqualToConstant: 650),
            cards.heightAnchor.constraint(equalToConstant: 106)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
    }

    private func makeCard(icon: String, title: String, detail: String) -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        card.layer.cornerRadius = 18
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor

        let image = UIImageView(image: UIImage(systemName: icon))
        image.tintColor = UIColor(red: 0.60, green: 0.88, blue: 1, alpha: 1)
        image.contentMode = .scaleAspectFit
        image.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)

        let heading = makeLabel(title, size: 17, weight: .bold, color: .white)
        heading.textAlignment = .left

        let explanation = makeLabel(detail, size: 12, weight: .medium, color: UIColor.white.withAlphaComponent(0.72))
        explanation.textAlignment = .left
        explanation.numberOfLines = 3

        let text = UIStackView(arrangedSubviews: [heading, explanation])
        text.axis = .vertical
        text.spacing = 4

        let row = UIStackView(arrangedSubviews: [image, text])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 13
        row.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(row)

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 17),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -17),
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
            image.widthAnchor.constraint(equalToConstant: 34)
        ])
        return card
    }

    private func makeLabel(_ text: String, size: CGFloat, weight: UIFont.Weight, color: UIColor) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = color
        label.font = .systemFont(ofSize: size, weight: weight)
        label.textAlignment = .center
        return label
    }
}

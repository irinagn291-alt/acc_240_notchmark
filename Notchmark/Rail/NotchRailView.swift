import UIKit

/// Role: Rail. UIKit balance bar with CAShapeLayer teeth. Carve commits through a closure, never target-action.
final class NotchRailView: UIView {
    var purchasePrice: Double = 0 {
        didSet { setNeedsLayout() }
    }

    var perNotchShare: Double = 1 {
        didSet { setNeedsLayout() }
    }

    var balance: Double = 0 {
        didSet {
            if didDraw {
                animateTeeth(from: oldValue, to: balance)
            } else {
                setNeedsLayout()
            }
        }
    }

    var onCarve: (() -> Void)?

    private let barLayer = CAShapeLayer()
    private let teethLayer = CAShapeLayer()
    private let carveControl = UIView()
    private let carveLabel = UILabel()
    private var didDraw = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        backgroundColor = .clear
        barLayer.fillColor = LedgerPalette.surfaceUI.cgColor
        barLayer.strokeColor = LedgerPalette.inkUI.cgColor
        barLayer.lineWidth = 1
        layer.addSublayer(barLayer)

        teethLayer.fillColor = LedgerPalette.accentUI.cgColor
        teethLayer.strokeColor = LedgerPalette.inkUI.cgColor
        teethLayer.lineWidth = 0.5
        layer.addSublayer(teethLayer)

        carveControl.backgroundColor = LedgerPalette.accentUI.withAlphaComponent(0.15)
        carveControl.layer.borderColor = LedgerPalette.inkUI.cgColor
        carveControl.layer.borderWidth = 1
        carveLabel.text = "Notch"
        carveLabel.textColor = LedgerPalette.inkUI
        carveLabel.textAlignment = .center
        carveLabel.adjustsFontForContentSizeCategory = true
        if let typeface = LedgerTypeface.uiFont(.footnote) {
            carveLabel.font = typeface
        }
        carveLabel.isUserInteractionEnabled = false
        carveControl.addSubview(carveLabel)
        addSubview(carveControl)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleCarve))
        carveControl.addGestureRecognizer(tap)
        carveControl.isAccessibilityElement = true
        carveControl.accessibilityLabel = "Notch"
        carveControl.accessibilityTraits = .button
    }

    @objc private func handleCarve() {
        onCarve?()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let inset = LedgerPalette.space(1)
        let barHeight = max(28, bounds.height - inset * 2 - LedgerPalette.tap)
        let barRect = CGRect(
            x: inset,
            y: inset,
            width: bounds.width - inset * 2 - LedgerPalette.tap - LedgerPalette.space(1),
            height: barHeight
        )
        barLayer.path = UIBezierPath(rect: barRect).cgPath
        teethLayer.path = teethPath(in: barRect, balance: balance).cgPath

        carveControl.frame = CGRect(
            x: bounds.width - inset - LedgerPalette.tap,
            y: bounds.height - inset - LedgerPalette.tap,
            width: LedgerPalette.tap,
            height: LedgerPalette.tap
        )
        carveLabel.frame = carveControl.bounds
        didDraw = true
    }

    private func animateTeeth(from oldBalance: Double, to newBalance: Double) {
        guard let barPath = barLayer.path else {
            setNeedsLayout()
            return
        }
        let barRect = barPath.boundingBox
        let path = teethPath(in: barRect, balance: newBalance).cgPath
        if UIAccessibility.isReduceMotionEnabled {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            teethLayer.path = path
            CATransaction.commit()
            return
        }
        CATransaction.begin()
        CATransaction.setAnimationDuration(LedgerChrome.motionDuration)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
        teethLayer.path = path
        CATransaction.commit()
    }

    private func teethPath(in barRect: CGRect, balance: Double) -> UIBezierPath {
        let path = UIBezierPath()
        guard purchasePrice > 0, perNotchShare > 0 else { return path }
        let totalTeeth = max(1, Int(ceil(purchasePrice / perNotchShare)))
        let remaining = max(0, min(totalTeeth, Int(ceil(balance / perNotchShare))))
        guard remaining > 0 else { return path }
        let toothWidth = barRect.width / CGFloat(totalTeeth)
        let toothDepth = min(barRect.height * 0.45, 14)
        for index in 0 ..< remaining {
            let x = barRect.minX + CGFloat(index) * toothWidth
            let tooth = UIBezierPath()
            tooth.move(to: CGPoint(x: x + toothWidth * 0.15, y: barRect.minY))
            tooth.addLine(to: CGPoint(x: x + toothWidth * 0.85, y: barRect.minY))
            tooth.addLine(to: CGPoint(x: x + toothWidth * 0.5, y: barRect.minY + toothDepth))
            tooth.close()
            path.append(tooth)
        }
        return path
    }
}

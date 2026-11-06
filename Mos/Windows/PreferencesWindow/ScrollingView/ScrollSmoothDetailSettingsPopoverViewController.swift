import Cocoa

class ScrollSmoothDetailSettingsPopoverViewController: AdaptivePopover, ScrollOptionsContextProviding {

    @IBOutlet weak var verticalSmoothCheckBox: NSButton?
    @IBOutlet weak var horizontalSmoothCheckBox: NSButton?
    @IBOutlet weak var simulateTrackpadCheckBox: NSButton?

    var currentTargetApplication: Application?
    var onOptionsChanged: (() -> Void)?
    private let deadZoneLabel = NSTextField(labelWithString: NSLocalizedString(
        "Dead Zone",
        comment: "Minimum scroll output threshold for the current application"
    ))
    private let deadZoneInput = NSTextField()
    private let deadZoneStepper = NSStepper()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureDeadZoneControls()
        syncViewWithOptions()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        syncViewWithOptions()
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        updatePreferredContentSize()
    }

    override func updatePreferredContentSize() {
        preferredContentSize = NSSize(width: 260, height: 156)
    }

    @IBAction func verticalSmoothToggle(_ sender: NSButton) {
        getTargetApplicationScrollOptions().smoothVertical = sender.state == .on
        syncViewWithOptions()
        onOptionsChanged?()
    }

    @IBAction func horizontalSmoothToggle(_ sender: NSButton) {
        getTargetApplicationScrollOptions().smoothHorizontal = sender.state == .on
        syncViewWithOptions()
        onOptionsChanged?()
    }

    @IBAction func simulateTrackpadToggle(_ sender: NSButton) {
        let scrollOptions = getTargetApplicationScrollOptions()
        let isOn = sender.state == .on
        let wasOn = scrollOptions.smoothSimTrackpad
        scrollOptions.smoothSimTrackpad = isOn
        if isOn {
            if !wasOn {
                scrollOptions.durationBeforeSimTrackpadLock = scrollOptions.duration
            }
            scrollOptions.duration = ScrollDurationLimits.simulateTrackpadDefault
        } else {
            if wasOn, let previous = scrollOptions.durationBeforeSimTrackpadLock {
                scrollOptions.duration = previous
            }
            if wasOn {
                scrollOptions.durationBeforeSimTrackpadLock = nil
            }
        }
        syncViewWithOptions()
        onOptionsChanged?()
    }

    @objc private func deadZoneInputChanged(_ sender: NSTextField) {
        setDeadZone(sender.doubleValue)
    }

    @objc private func deadZoneStepperChanged(_ sender: NSStepper) {
        setDeadZone(sender.doubleValue)
    }

    private func configureDeadZoneControls() {
        guard
            let descriptionLabel = view.subviews.compactMap({ $0 as? NSTextField }).first,
            let simulateTrackpadCheckBox = simulateTrackpadCheckBox
        else {
            return
        }

        deadZoneLabel.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        deadZoneLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        deadZoneInput.alignment = .right
        deadZoneInput.controlSize = .small
        deadZoneInput.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        (deadZoneInput.cell as? NSTextFieldCell)?.sendsActionOnEndEditing = true
        deadZoneInput.target = self
        deadZoneInput.action = #selector(deadZoneInputChanged(_:))
        deadZoneInput.translatesAutoresizingMaskIntoConstraints = false
        deadZoneInput.widthAnchor.constraint(equalToConstant: 58).isActive = true

        deadZoneStepper.minValue = ScrollDeadZoneLimits.minimum
        deadZoneStepper.maxValue = ScrollDeadZoneLimits.maximum
        deadZoneStepper.increment = ScrollDeadZoneLimits.increment
        deadZoneStepper.valueWraps = false
        deadZoneStepper.autorepeat = true
        deadZoneStepper.controlSize = .small
        deadZoneStepper.target = self
        deadZoneStepper.action = #selector(deadZoneStepperChanged(_:))

        let deadZoneRow = NSStackView(views: [deadZoneLabel, deadZoneInput, deadZoneStepper])
        deadZoneRow.orientation = .horizontal
        deadZoneRow.alignment = .centerY
        deadZoneRow.spacing = 8
        deadZoneRow.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(deadZoneRow)

        if let descriptionBottomConstraint = view.constraints.first(where: {
            ($0.firstItem as? NSView) === descriptionLabel && $0.firstAttribute == .bottom
        }) {
            descriptionBottomConstraint.isActive = false
        }

        NSLayoutConstraint.activate([
            deadZoneRow.leadingAnchor.constraint(equalTo: simulateTrackpadCheckBox.leadingAnchor),
            deadZoneRow.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            deadZoneRow.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 8),
            view.bottomAnchor.constraint(equalTo: deadZoneRow.bottomAnchor, constant: 20)
        ])
    }

    private func setDeadZone(_ value: Double) {
        let clampedValue = min(
            max(value, ScrollDeadZoneLimits.minimum),
            ScrollDeadZoneLimits.maximum
        )
        getTargetApplicationScrollOptions().deadZone = clampedValue
        syncViewWithOptions()
        onOptionsChanged?()
    }

    private func syncViewWithOptions() {
        updateSimulateTrackpadControl(simulateTrackpadCheckBox)
        let scroll = getTargetApplicationScrollOptions()
        updateSmoothDependentControl(verticalSmoothCheckBox, isOn: scroll.smoothVertical)
        updateSmoothDependentControl(horizontalSmoothCheckBox, isOn: scroll.smoothHorizontal)

        let isDeadZoneEnabled = !isTargetApplicationInheritOptions() && scroll.smooth
        deadZoneLabel.isEnabled = isDeadZoneEnabled
        deadZoneInput.isEnabled = isDeadZoneEnabled
        deadZoneStepper.isEnabled = isDeadZoneEnabled
        deadZoneInput.stringValue = String(format: "%.2f", scroll.deadZone)
        deadZoneStepper.doubleValue = scroll.deadZone
    }
}

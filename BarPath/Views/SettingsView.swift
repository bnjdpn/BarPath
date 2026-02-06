import SwiftUI

/// Settings screen providing controls for recording preferences, display options,
/// calibration configuration, and app information.
struct SettingsView: View {

    // MARK: - Properties

    @State private var viewModel = SettingsViewModel()

    /// Local state for the calibration reference value text field.
    @State private var calibrationReferenceText = ""

    /// Local state for the calibration method picker.
    @State private var selectedCalibrationMethod: CalibrationMethod = .plateSize

    // MARK: - Body

    var body: some View {
        Form {
            recordingSection
            displaySection
            calibrationSection
            aboutSection
        }
        .navigationTitle(
            NSLocalizedString("settings_title", comment: "Settings screen title")
        )
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let calibration = viewModel.settings.calibrationData {
                selectedCalibrationMethod = calibration.method
                calibrationReferenceText = String(
                    format: "%.2f",
                    calibration.referenceValueMeters
                )
            }
        }
    }

    // MARK: - Recording Section

    private var recordingSection: some View {
        Section {
            Picker(
                NSLocalizedString(
                    "settings_fps",
                    comment: "Recording FPS setting"
                ),
                selection: Binding(
                    get: { viewModel.settings.recordingFPS },
                    set: { viewModel.updateRecordingFPS($0) }
                )
            ) {
                ForEach(RecordingFPS.allCases, id: \.self) { fps in
                    Text(fps.displayName).tag(fps)
                }
            }

            Picker(
                NSLocalizedString(
                    "settings_preferred_lift",
                    comment: "Preferred lift type setting"
                ),
                selection: Binding(
                    get: { viewModel.settings.preferredLiftType },
                    set: { viewModel.updatePreferredLiftType($0) }
                )
            ) {
                ForEach(LiftType.allCases) { liftType in
                    Label(liftType.displayName, systemImage: liftType.icon)
                        .tag(liftType)
                }
            }
        } header: {
            Text(
                NSLocalizedString(
                    "settings_section_recording",
                    comment: "Recording settings section header"
                )
            )
        }
    }

    // MARK: - Display Section

    private var displaySection: some View {
        Section {
            Picker(
                NSLocalizedString(
                    "settings_path_color",
                    comment: "Path color mode setting"
                ),
                selection: Binding(
                    get: { viewModel.settings.pathColor },
                    set: { viewModel.updatePathColor($0) }
                )
            ) {
                ForEach(PathColorOption.allCases, id: \.self) { option in
                    Text(option.displayName).tag(option)
                }
            }

            Toggle(
                NSLocalizedString(
                    "settings_show_velocity",
                    comment: "Show velocity overlay toggle"
                ),
                isOn: Binding(
                    get: { viewModel.settings.showVelocityOverlay },
                    set: { viewModel.updateShowVelocityOverlay($0) }
                )
            )

            Toggle(
                NSLocalizedString(
                    "settings_show_drift",
                    comment: "Show drift lines toggle"
                ),
                isOn: Binding(
                    get: { viewModel.settings.showDriftLines },
                    set: { viewModel.updateShowDriftLines($0) }
                )
            )
        } header: {
            Text(
                NSLocalizedString(
                    "settings_section_display",
                    comment: "Display settings section header"
                )
            )
        }
    }

    // MARK: - Calibration Section

    private var calibrationSection: some View {
        Section {
            Picker(
                NSLocalizedString(
                    "settings_calibration_method",
                    comment: "Calibration method picker"
                ),
                selection: $selectedCalibrationMethod
            ) {
                Text(
                    NSLocalizedString(
                        "calibration_plate_size",
                        comment: "Plate size calibration method"
                    )
                )
                .tag(CalibrationMethod.plateSize)

                Text(
                    NSLocalizedString(
                        "calibration_user_height",
                        comment: "User height calibration method"
                    )
                )
                .tag(CalibrationMethod.userHeight)

                Text(
                    NSLocalizedString(
                        "calibration_manual",
                        comment: "Manual calibration method"
                    )
                )
                .tag(CalibrationMethod.manual)
            }

            HStack {
                Text(
                    NSLocalizedString(
                        "settings_reference_value",
                        comment: "Calibration reference value label"
                    )
                )

                Spacer()

                TextField(
                    NSLocalizedString(
                        "settings_reference_placeholder",
                        comment: "Reference value placeholder"
                    ),
                    text: $calibrationReferenceText
                )
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 100)
                .onChange(of: calibrationReferenceText) { _, newValue in
                    updateCalibration(referenceText: newValue)
                }
            }
        } header: {
            Text(
                NSLocalizedString(
                    "settings_section_calibration",
                    comment: "Calibration settings section header"
                )
            )
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section {
            HStack {
                Text(
                    NSLocalizedString(
                        "settings_version",
                        comment: "App version label"
                    )
                )
                Spacer()
                Text(appVersion)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text(
                NSLocalizedString(
                    "settings_section_about",
                    comment: "About section header"
                )
            )
        }
    }

    // MARK: - Helpers

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func updateCalibration(referenceText: String) {
        guard let referenceValue = Double(referenceText), referenceValue > 0 else {
            viewModel.updateCalibration(nil)
            return
        }

        // A default pixels-per-meter estimate; real calibration would be computed from
        // the reference object detection in the video frame.
        let defaultPixelsPerMeter = 500.0

        let calibration = CalibrationData(
            method: selectedCalibrationMethod,
            referenceValueMeters: referenceValue,
            pixelsPerMeter: defaultPixelsPerMeter
        )
        viewModel.updateCalibration(calibration)
    }
}

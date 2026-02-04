//
//  NotificationViewController.swift
//  NotificationContent
//
//  Created by Richard Liu on 2026-02-03.
//

import UIKit
import UserNotifications
import UserNotificationsUI

final class NotificationViewController: UIViewController, UNNotificationContentExtension {

    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let slider = UISlider()
    private let minLabel = UILabel()
    private let maxLabel = UILabel()
    private let confirmButton = UIButton(type: .system)

    private let appGroupIdentifier = "group.cupicelemon.tongzinumber-demo"
    private let nextReminderSecondsKey = "nextReminderSeconds"

    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground

        titleLabel.text = "选择下一次提醒时间"
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        valueLabel.text = "60 秒"
        valueLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 48, weight: .bold)
        valueLabel.textAlignment = .center
        valueLabel.textColor = .label
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        slider.minimumValue = 10
        slider.maximumValue = 300
        slider.value = 60
        slider.isContinuous = true
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        slider.translatesAutoresizingMaskIntoConstraints = false

        minLabel.text = "10秒"
        minLabel.font = UIFont.systemFont(ofSize: 12)
        minLabel.textColor = .secondaryLabel
        minLabel.translatesAutoresizingMaskIntoConstraints = false

        maxLabel.text = "300秒"
        maxLabel.font = UIFont.systemFont(ofSize: 12)
        maxLabel.textColor = .secondaryLabel
        maxLabel.textAlignment = .right
        maxLabel.translatesAutoresizingMaskIntoConstraints = false

        confirmButton.setTitle("确认并设置下一次提醒", for: .normal)
        confirmButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        confirmButton.backgroundColor = .systemBlue
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.layer.cornerRadius = 12
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        confirmButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(titleLabel)
        view.addSubview(valueLabel)
        view.addSubview(slider)
        view.addSubview(minLabel)
        view.addSubview(maxLabel)
        view.addSubview(confirmButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            valueLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            valueLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            slider.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 24),
            slider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            slider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            minLabel.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 4),
            minLabel.leadingAnchor.constraint(equalTo: slider.leadingAnchor),

            maxLabel.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 4),
            maxLabel.trailingAnchor.constraint(equalTo: slider.trailingAnchor),

            confirmButton.topAnchor.constraint(equalTo: minLabel.bottomAnchor, constant: 24),
            confirmButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            confirmButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            confirmButton.heightAnchor.constraint(equalToConstant: 50),
            confirmButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])

        preferredContentSize = CGSize(width: view.bounds.width, height: 250)
    }

    func didReceive(_ notification: UNNotification) {
        if let previousSeconds = notification.request.content.userInfo["scheduledSeconds"] as? Int {
            slider.value = Float(previousSeconds)
            updateValueLabel()
        }
    }

    @objc private func sliderValueChanged(_ sender: UISlider) {
        updateValueLabel()
    }

    private func updateValueLabel() {
        let seconds = Int(slider.value)
        valueLabel.text = "\(seconds) 秒"
    }

    @objc private func confirmTapped() {
        let selectedSeconds = Int(slider.value)

        userDefaults?.set(selectedSeconds, forKey: nextReminderSecondsKey)

        scheduleNextNotification(seconds: selectedSeconds)

        extensionContext?.dismissNotificationContentExtension()
    }

    private func scheduleNextNotification(seconds: Int) {
        let content = UNMutableNotificationContent()
        content.title = "定时提醒"
        content.body = "时间到了！下拉或长按选择下一次提醒时间"
        content.sound = .default
        content.categoryIdentifier = "TIMER_REMINDER"
        content.userInfo = ["scheduledSeconds": seconds]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(seconds),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
}

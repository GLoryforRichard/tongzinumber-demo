//
//  ContentView.swift
//  tongzinumber-demo
//
//  Created by Richard Liu on 2026-02-03.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var selectedSeconds: Double = 60
    @State private var isScheduling = false
    @State private var showSuccessMessage = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                timerDisplay

                sliderSection

                scheduleButton

                Spacer()

                permissionStatus
            }
            .padding()
            .navigationTitle("定时提醒")
            .task {
                await notificationManager.updateAuthorizationStatus()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                Task {
                    await notificationManager.updateAuthorizationStatus()
                }
            }
        }
    }

    private var timerDisplay: some View {
        VStack(spacing: 8) {
            Text("\(Int(selectedSeconds))")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
                .animation(.snappy, value: selectedSeconds)

            Text("秒")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }

    private var sliderSection: some View {
        VStack(spacing: 12) {
            Slider(
                value: $selectedSeconds,
                in: 10...300,
                step: 1
            )
            .tint(.blue)

            HStack {
                Text("10秒")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("300秒")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
    }

    private var scheduleButton: some View {
        Button {
            scheduleReminder()
        } label: {
            HStack {
                if isScheduling {
                    ProgressView()
                        .tint(.white)
                } else if showSuccessMessage {
                    Image(systemName: "checkmark.circle.fill")
                    Text("已设置！")
                } else {
                    Image(systemName: "bell.fill")
                    Text("设置提醒")
                }
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(buttonBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isScheduling || notificationManager.authorizationStatus == .denied)
        .padding(.horizontal)
    }

    private var buttonBackgroundColor: Color {
        if notificationManager.authorizationStatus == .denied {
            return .gray
        }
        if showSuccessMessage {
            return .green
        }
        return .blue
    }

    private var permissionStatus: some View {
        Group {
            switch notificationManager.authorizationStatus {
            case .notDetermined:
                Button("请求通知权限") {
                    Task {
                        await notificationManager.requestAuthorization()
                    }
                }
                .font(.subheadline)
            case .denied:
                VStack(spacing: 8) {
                    Label("通知权限已关闭", systemImage: "bell.slash.fill")
                        .foregroundStyle(.red)
                    Button("打开设置") {
                        openSettings()
                    }
                    .font(.subheadline)
                }
            case .authorized, .provisional, .ephemeral:
                Label("通知权限已开启", systemImage: "bell.badge.fill")
                    .foregroundStyle(.green)
            @unknown default:
                EmptyView()
            }
        }
        .font(.footnote)
    }

    private func scheduleReminder() {
        guard !isScheduling else { return }

        isScheduling = true

        Task {
            if notificationManager.authorizationStatus == .notDetermined {
                let granted = await notificationManager.requestAuthorization()
                if !granted {
                    isScheduling = false
                    return
                }
            }

            do {
                try await notificationManager.scheduleNotification(seconds: Int(selectedSeconds))

                await MainActor.run {
                    isScheduling = false
                    showSuccessMessage = true
                }

                try? await Task.sleep(for: .seconds(2))

                await MainActor.run {
                    showSuccessMessage = false
                }
            } catch {
                await MainActor.run {
                    isScheduling = false
                }
            }
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    ContentView()
}

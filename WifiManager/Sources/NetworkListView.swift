import SwiftUI
import CoreWLAN

extension CWNetwork: @retroactive Identifiable {
    public var id: String { bssid ?? ssid ?? "unknown-\(hashValue)" }
}

private struct NetworkGroup: Identifiable {
    let id: String       // ssid
    let ssid: String
    let best: CWNetwork  // highest RSSI
    let apCount: Int
}

struct NetworkListView: View {
    @EnvironmentObject var monitor: WiFiMonitor
    @EnvironmentObject var lang: LanguageManager
    @State private var promptingSSID: String?
    @State private var passwordInput = ""
    @State private var failedSSID: String?

    private var groupedNetworks: [NetworkGroup] {
        var dict: [String: [CWNetwork]] = [:]
        for n in monitor.availableNetworks {
            let key = n.ssid ?? ""
            guard !key.isEmpty else { continue }
            dict[key, default: []].append(n)
        }
        return dict.compactMap { ssid, networks -> NetworkGroup? in
            guard let best = networks.max(by: { $0.rssiValue < $1.rssiValue }) else { return nil }
            return NetworkGroup(id: ssid, ssid: ssid, best: best, apCount: networks.count)
        }.sorted { $0.best.rssiValue > $1.best.rssiValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            if monitor.isScanning {
                HStack(spacing: 8) {
                    ProgressView().scaleEffect(0.7)
                    Text(lang.s.scanning)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            } else if groupedNetworks.isEmpty {
                Text(lang.s.noNetworks)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            } else {
                let groups = Array(groupedNetworks.prefix(8))
                ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
                    NetworkRow(
                        network: group.best,
                        apCount: group.apCount,
                        isCurrentNetwork: group.ssid == monitor.metrics?.ssid,
                        isPrompting: promptingSSID == group.ssid,
                        passwordInput: $passwordInput
                    ) {
                        Task {
                            failedSSID = nil
                            await monitor.connect(to: group.best)
                            if monitor.connectionError != nil {
                                failedSSID = group.ssid
                                promptingSSID = group.ssid
                                passwordInput = ""
                            }
                        }
                    } onConnect: { pwd in
                        promptingSSID = nil
                        failedSSID = nil
                        Task { await monitor.connect(to: group.best, password: pwd.isEmpty ? nil : pwd) }
                    } onCancel: {
                        promptingSSID = nil
                        failedSSID = nil
                    }

                    if index < groups.count - 1 {
                        Divider().padding(.leading, 36)
                    }
                }
            }

            if let err = monitor.connectionError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
        }
    }
}

private struct NetworkRow: View {
    let network: CWNetwork
    let apCount: Int
    let isCurrentNetwork: Bool
    let isPrompting: Bool
    @Binding var passwordInput: String
    let onTap: () -> Void
    let onConnect: (String) -> Void
    let onCancel: () -> Void
    @EnvironmentObject var lang: LanguageManager

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 8) {
                    wifiSignalImage
                        .frame(width: 20)

                    Text(network.ssid ?? lang.s.unknownNetwork)
                        .font(.callout)
                        .lineLimit(1)

                    if isCurrentNetwork {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color.accentColor)
                            .font(.caption.weight(.semibold))
                    }

                    if apCount > 1 {
                        Text("\(apCount)")
                            .font(.system(size: 9).monospacedDigit())
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.18))
                            .clipShape(Capsule())
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if !network.supportsSecurity(.none) {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.tertiary)
                            .font(.caption)
                    }

                    rssiLabel
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(isCurrentNetwork ? Color.accentColor.opacity(0.07) : Color.clear)

            if isPrompting {
                HStack(spacing: 6) {
                    SecureField(lang.s.wifiPassword, text: $passwordInput)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { onConnect(passwordInput) }

                    Button(lang.s.join) { onConnect(passwordInput) }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(passwordInput.isEmpty)

                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        }
    }

    @ViewBuilder
    private var wifiSignalImage: some View {
        if network.rssiValue < -75 {
            Image(systemName: "wifi.slash")
                .foregroundStyle(.secondary.opacity(0.6))
        } else {
            let strength = Double(max(-75, min(-30, network.rssiValue)) + 75) / 45.0
            Image(systemName: "wifi", variableValue: strength)
                .foregroundStyle(isCurrentNetwork ? Color.accentColor : .secondary)
        }
    }

    private var rssiLabel: some View {
        Text("\(network.rssiValue) dBm")
            .font(.system(size: 10).monospacedDigit())
            .foregroundStyle(.tertiary)
    }
}

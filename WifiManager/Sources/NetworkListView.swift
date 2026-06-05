import SwiftUI
import CoreWLAN

extension CWNetwork: @retroactive Identifiable {
    public var id: String { bssid ?? ssid ?? "unknown-\(hashValue)" }
}

struct NetworkListView: View {
    @EnvironmentObject var monitor: WiFiMonitor
    @State private var promptingID: String?
    @State private var passwordInput = ""
    @State private var failedID: String?

    var body: some View {
        VStack(spacing: 0) {
            if monitor.isScanning {
                HStack(spacing: 8) {
                    ProgressView().scaleEffect(0.7)
                    Text("Recherche des réseaux…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            } else if monitor.availableNetworks.isEmpty {
                Text("Aucun réseau trouvé")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            } else {
                ForEach(monitor.availableNetworks.prefix(8)) { network in
                    NetworkRow(
                        network: network,
                        isCurrentNetwork: network.ssid == monitor.metrics?.ssid,
                        isPrompting: promptingID == network.id,
                        passwordInput: $passwordInput
                    ) {
                        // Tente nil d'abord (keychain ou réseau ouvert)
                        // Si échec → affiche le prompt mot de passe
                        Task {
                            failedID = nil
                            await monitor.connect(to: network)
                            if monitor.connectionError != nil {
                                failedID = network.id
                                promptingID = network.id
                                passwordInput = ""
                            }
                        }
                    } onConnect: { pwd in
                        promptingID = nil
                        failedID = nil
                        Task { await monitor.connect(to: network, password: pwd.isEmpty ? nil : pwd) }
                    } onCancel: {
                        promptingID = nil
                        failedID = nil
                    }

                    if network != monitor.availableNetworks.prefix(8).last {
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
    let isCurrentNetwork: Bool
    let isPrompting: Bool
    @Binding var passwordInput: String
    let onTap: () -> Void
    let onConnect: (String) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 8) {
                    Image(systemName: signalIcon)
                        .foregroundStyle(isCurrentNetwork ? Color.accentColor : .secondary)
                        .frame(width: 20)

                    Text(network.ssid ?? "Réseau inconnu")
                        .font(.callout)
                        .lineLimit(1)

                    if isCurrentNetwork {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color.accentColor)
                            .font(.caption.weight(.semibold))
                    }

                    Spacer()

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
                    SecureField("Mot de passe WiFi", text: $passwordInput)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { onConnect(passwordInput) }

                    Button("Rejoindre") { onConnect(passwordInput) }
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

    private var signalIcon: String {
        switch network.rssiValue {
        case (-50)...:      return "wifi"
        case (-65)...(-51): return "wifi"
        case (-75)...(-66): return "wifi"
        default:            return "wifi.slash"
        }
    }

    private var rssiLabel: some View {
        Text("\(network.rssiValue) dBm")
            .font(.system(size: 10).monospacedDigit())
            .foregroundStyle(.tertiary)
    }
}

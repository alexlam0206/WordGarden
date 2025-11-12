import SwiftUI

struct Dependency: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let url: String
}

struct CreditsView: View {
    let dependencies: [Dependency] = [
        .init(name: "abseil-cpp-binary", url: "https://github.com/google/abseil-cpp-binary.git"),
        .init(name: "app-check", url: "https://github.com/google/app-check.git"),
        .init(name: "appauth-ios", url: "https://github.com/openid/AppAuth-iOS.git"),
        .init(name: "firebase-ios-sdk", url: "https://github.com/firebase/firebase-ios-sdk.git"),
        .init(name: "google-ads-on-device-conversion-ios-sdk", url: "https://github.com/googleads/google-ads-on-device-conversion-ios-sdk"),
        .init(name: "googleappmeasurement", url: "https://github.com/google/GoogleAppMeasurement.git"),
        .init(name: "googledatatransport", url: "https://github.com/google/GoogleDataTransport.git"),
        .init(name: "googlesignin-ios", url: "https://github.com/google/GoogleSignIn-iOS.git"),
        .init(name: "googleutilities", url: "https://github.com/google/GoogleUtilities.git"),
        .init(name: "grpc-binary", url: "https://github.com/google/grpc-binary.git"),
        .init(name: "gtm-session-fetcher", url: "https://github.com/google/gtm-session-fetcher.git"),
        .init(name: "gtmappauth", url: "https://github.com/google/GTMAppAuth.git"),
        .init(name: "interop-ios-for-google-sdks", url: "https://github.com/google/interop-ios-for-google-sdks.git"),
        .init(name: "leveldb", url: "https://github.com/firebase/leveldb.git"),
        .init(name: "nanopb", url: "https://github.com/firebase/nanopb.git"),
        .init(name: "promises", url: "https://github.com/google/promises.git"),
        .init(name: "swift-protobuf", url: "https://github.com/apple/swift-protobuf.git"),
    ].sorted { $0.name.lowercased() < $1.name.lowercased() }

    var body: some View {
        List {
            Section(header: Text("Dependencies").font(.headline)) {
                ForEach(dependencies) { dependency in
                    if let url = URL(string: dependency.url) {
                        Link(destination: url) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(dependency.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(dependency.url)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "safari")
                                    .foregroundColor(.accentColor)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Credits")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CreditsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CreditsView()
        }
    }
}
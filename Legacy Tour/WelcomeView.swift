import SwiftUI

struct WelcomeView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Image("HU")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("Welcome to Legacy Park")
                        .font(.largeTitle).bold()
                        .multilineTextAlignment(.center)
                        .padding()
                        .foregroundColor(.white)

                    Text("Explore our monuments in VR")
                        .font(.title2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .foregroundColor(.white)

                    Spacer()

                    NavigationLink(destination: ContentView()) {
                        Text("Begin the Tour of Legacies")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.blue.opacity(0.85))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

#Preview {
    WelcomeView()
}

import SwiftUI

struct OnboardingView: View {
    @State private var isShowingLogin = false

    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Spacer()
                // App branding (can be logo or text)
                Image(systemName: "star.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.blue)

                Text("Welcome to MyApp")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Text("Your journey starts here. Enjoy the experience!")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                Spacer()

                NavigationLink(destination: LoginView(), isActive: $isShowingLogin) {
                    Button(action: {
                        isShowingLogin = true
                    }) {
                        Text("Get Started")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
        }
    }
}

struct LoginView: View {
    var body: some View {
        Text("Login View")
            .font(.title)
            .navigationBarTitle("Login", displayMode: .inline)
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}

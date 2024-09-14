import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = Settings.shared
    @Binding var navigationPath: NavigationPath

    var body: some View {
        ZStack {
            // Background color filling the entire safe area
            Image("red_curtain")
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0)
                .edgesIgnoringSafeArea(.all)

            VStack {

                // Box that wraps the settings buttons
                VStack(spacing: 40) {
                    Text("Settings")
                        .font(.largeTitle)
                        .foregroundColor(.gray)

                    // Music Button
                    Button(action: {
                        settings.musicEnabled.toggle()
                    }) {
                        Text("Music: \(settings.musicEnabled ? "On" : "Off")")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .frame(width: 200, height: 50)
                            .background(Color.gray.opacity(0.4))
                            .cornerRadius(10)
                    }

                    // Effects Button
                    Button(action: {
                        settings.soundEffectsEnabled.toggle()
                    }) {
                        Text("Effects: \(settings.soundEffectsEnabled ? "On" : "Off")")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .frame(width: 200, height: 50)
                            .background(Color.gray.opacity(0.4))
                            .cornerRadius(10)
                    }

                    // Back Button
                    Button(action: {
                        navigationPath.removeLast() // Navigate back to the previous view
                    }) {
                        Text("Back")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.teal)
                            .frame(width: 150, height: 50)
                            .background(Color.gray.opacity(0.4))
                            .cornerRadius(10)
                    }
                    .padding(.bottom, 20)
                }
                .padding(50)
                .background(Color.brown.opacity(0.8)) // Box background color
                .cornerRadius(15) // Rounded corners
                .overlay( // Box border
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.black, lineWidth: 3)
                )
            }
        }
    }
}

// Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(navigationPath: .constant(NavigationPath()))
    }
}


// Preview
#Preview {
    SettingsView(navigationPath: .constant(NavigationPath()))
}

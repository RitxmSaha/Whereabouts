import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        NavigationView {
            VStack {
                Text("Login")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 50)
                
                VStack(alignment: .leading) {
                    Text("Email")
                        .font(.headline)
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Text("Password")
                        .font(.headline)
                        .padding(.top, 20)
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .padding(.horizontal, 24)
                
                Button(action: {
                    appViewModel.signIn(email: email, password: password)
                }) {
                    Text("Log in")
                        .frame(maxWidth: .infinity)
                        .frame(height: 45)
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 24)
                .padding(.top, 30)
                NavigationLink(destination: SignUpView()) {
                    Text("Create Account")
                        .frame(maxWidth: .infinity)
                        .frame(height: 45)
                        .foregroundColor(.white)
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                Spacer()
            }
            .padding(.top, 100)
        }
    }
}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
            .environmentObject(AppViewModel())
    }
}

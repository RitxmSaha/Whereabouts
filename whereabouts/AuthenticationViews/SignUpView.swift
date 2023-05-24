import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingImagePicker = false
    @State private var profileImage = UIImage()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create Account")
                .font(.largeTitle)
                .bold()
            
            Text("Name")
                .font(.headline)
                .padding(.top, 20)
            TextField("Name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 24)
            
            Text("Email")
                .font(.headline)
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding(.horizontal, 24)
            Text("Password")
                .font(.headline)
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 24)
            
            Text("Confirm Password")
                .font(.headline)
            SecureField("Confirm Password", text: $confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 24)
            Button(action: {
                self.showingImagePicker = true
            }) {
                HStack {
                    Image(systemName: "photo")
                        .font(.system(size: 20))
                    
                    Text("Profle Picture")
                        .font(.headline)
                }
                .frame(minWidth: 0, maxWidth: 250, minHeight: 0, maxHeight: 50)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(20)
                .padding(.horizontal)
                
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(sourceType: .photoLibrary, selectedImage: self.$profileImage)
        }
        Button(action: {
            if password == confirmPassword {
                appViewModel.createAccount(name: name, email: email, password: password, profilePicture: profileImage)
            } else {
                print("Passwords do not match")
            }
        }) {
            Text("Create Account")
                .frame(maxWidth: .infinity)
                .frame(height: 45)
                .foregroundColor(.white)
                .background(Color.green)
                .cornerRadius(10)
        }
        .padding(.horizontal, 24)
        .padding(.top, 15)
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}

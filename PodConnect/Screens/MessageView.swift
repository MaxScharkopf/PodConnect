//
//  MessageView.swift
//  PodConnect
//
//  Created by Kaitlyn Cox on 3/31/26.
//

import SwiftUI
import FirebaseAuth

struct MessageView: View {
    @State private var TextMessage: String = ""
    //@StateObject private var authServ = AuthService()
    //@StateObject private var MessageVM = MessageViewModel(messageRepository: MessageRepository(firestoreService: <#FirestoreService#>, authService: <#AuthService#>)) // Fix this?
    var body: some View {
        //let ChannelClay = Color(red: 173/250.0, green: 68/250.0, blue: 33/250.0)
        let IslandsBlue = Color(red: 21/250.0, green: 62/250.0, blue: 74/250.0)
        
        
        ZStack {
            VStack(spacing: 0){
                IslandsBlue
                    .frame(height: 130)
                Spacer()
                IslandsBlue
                    .frame(height: 130)
            }
            .ignoresSafeArea()
            
            VStack(){
                HStack(){
                    Button(action: {}){
                        Image(systemName: "chevron.backward.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                }
                Spacer()

            }
            
            VStack{
                HStack(){
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
                Text("username") // need to get actual uesrname
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                Spacer()
                
            }
            
            
            
            
            
            VStack() {
                /*
                ScrollView{ // having problems with this
                    LazyVStack{
                        ForEach(MessageVM.messages){ message in
                            TextBubbles(message: message, Sender: message.sender == authServ.currentUser?.uid)
                            
                        }
                    }
                }
                 */
                
                Spacer()
                HStack{
                    Spacer()
                    TextField("Message...", text: $TextMessage){
                    
                    }
                    .padding()
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white, lineWidth: 1))
                    .foregroundStyle(Color.white)
                    Button(action: {}){
                        Text("Send")
                            .padding(6)
                            .foregroundColor(Color.white)
                            .background(.white.opacity(0.2))
                            .clipShape(Capsule())
                            .font(.system(size: 17))
                            .shadow(color: .black, radius: 5)
                            
                    }
                    .padding()
                    
                }
                
            }
            .padding()
            
        }
    }
}

#Preview{
    MessageView()
}

//
//  SeedRepository.swift
//  PodConnect
//
//  Created by Kassidy Barbara-Rose Saffa on 4/14/26.
//
import Foundation
import FirebaseFirestore

final class SeedRepository {
    private let db = Firestore.firestore()
    
    /*
    func seedClubs() async {
        let clubs = [
            "DÍA: Diversity Inclusivity Accessibility",
                    "Accounting Club",
                    "Alpha Delta Psi",
                    "American Medical Student Association CI",
                    "Animal Welfare & Pre-Veterinary Club",
                    "Anthropology Club",
                    "ASI Student Government",
                    "ASI Student Programming Board",
                    "Associated Students Inc.",
                    "Ballet Folklorico De CI",
                    "Beta Gamma Nu Fraternity",
                    "Campus Rec Fitness",
                    "Campus Recreation Staff",
                    "Career Development and Alumni Engagement",
                    "Center for Community Engagement",
                    "Channel Islands Black Student Union",
                    "Channel Islands Boating Center",
                    "Channel Islands Communication Club",
                    "Channel Islands Mechatronics Engineering Club",
                    "Channel Islands Sociology Club",
                    "CI Bee Club",
                    "CI Bird Club",
                    "CI Business Club",
                    "CI Cheer Club",
                    "CI Finance Club",
                    "CI Hiking Club",
                    "CI Intramural Sports",
                    "CI Journaling Club",
                    "CI Karaoke Club",
                    "CI Line Dance",
                    "CI Math Club",
                    "CI MD/Ph.D. Club",
                    "CI Men's Soccer",
                    "CI Music Club",
                    "CI Neuroscience Society",
                    "CI Outdoor Adventures",
                    "CI Pre-Dental Society",
                    "CI Roller-Skating Club",
                    "CI Run Club",
                    "CI Solutions",
                    "CI Women In STEM",
                    "CI Women in Tech",
                    "CSUCI Astronomy Club",
                    "CSUCI Baseball",
                    "CSUCI Esports",
                    "CSUCI Film Club",
                    "CSUCI Mock Trial",
                    "CSUCI Student Amateur Radio Club",
                    "CSUCI Swifties",
                    "Data Science Club",
                    "Delta Alpha Pi",
                    "Disability Accommodations & Support Services",
                    "Dolphin Guardian Scholar",
                    "Early Childhood Studies Student Organization",
                    "English Club",
                    "Everyone is Our Priority Club",
                    "Free Radicals Chemistry Club",
                    "Furries at CI",
                    "Gamma Beta Phi National Honor Society",
                    "Green Generation Club",
                    "Hillel Channel Islands",
                    "Indian Student Association",
                    "InterVarsity Christian Fellowship",
                    "Investing/Trading Club",
                    "Kilusan Pilipino",
                    "League of United Latin American Citizens",
                    "MEChA de CI - Movimiento Estudiantil Chicanx de Aztlán (M.E.Ch.A.)",
                    "Media Arts Club",
                    "Mental Health Peer Program (MHPP)",
                    "Multicultural Dream Center (MDC)",
                    "Music Pedagogy Club",
                    "Native American and Indigenous Student Alliance",
                    "New Student Orientation",
                    "Phi Alpha Theta",
                    "Physician Assistant Student Club",
                    "Pi Sigma Alpha",
                    "Pre-Nursing Club",
                    "Programming Club",
                    "Psi Chi, International Honor Society in Psychology",
                    "Psychology Club",
                    "Public Impact Collective",
                    "Rack n Roll",
                    "Restoration and Environmental Stewardship through Outreach, Research and Education",
                    "Sailing Club",
                    "Sigma Delta Pi",
                    "Sigma Iota Rho",
                    "Sigma Omega Nu",
                    "Soccer Club (CI Women's Soccer)",
                    "Society for Advancement of Chicanos and Native Americans in Science",
                    "Spanish Club",
                    "Sports Club Officers",
                    "Student Nurses' Association",
                    "Student Union",
                    "Student Veteran Organization",
                    "Students for Housing Equity",
                    "Students for Justice in Palestine",
                    "Study Abroad (International Programs)",
                    "Sustainability CI (Facilities Services)",
                    "TableTop Games Club",
                    "The Acting & Writing Workshop Club",
                    "The CI View student news",
                    "The Ethical Hackers of Channel Islands",
                    "Trenza de CI",
                    "Unión de Hermanos",
                    "Vice President for Student Affairs Office",
                    "Vietnamese Student Association",
                    "Volleyball Sports Club",
                    "Wellness Promotion & Education",
                    "Zeta Pi Omega"
        ]
        
        for club in clubs {
            do {
                try await db.collection("clubs").addDocument(data: [
                    "name": club
                ])
                print("Added \(club)")
            } catch {
                print("Error adding \(club): \(error)")
            }
        }
    }*/
    
    func seedUserVisibilityDefaults() async {
        do {
            let snapshot = try await db.collection("users").getDocuments()

            for document in snapshot.documents {
                let data = document.data()
                let userId = document.documentID

                let username = data["username"] as? String ?? ""
                let usernameLower = data["username_lowercase"] as? String ?? username.lowercased()
                let name = data["name"] as? String ?? ""
                let email = data["email"] as? String ?? ""
                let uid = data["uid"] as? String ?? userId
                let bio = data["bio"] as? String ?? ""
                let profileImageURL = data["profileImageURL"] as? String
                let friends = data["friends"] as? [String] ?? []

                var fixedClasses: [String] = []
                if let arr = data["classes"] as? [String] {
                    fixedClasses = arr
                } else if let arrAny = data["classes"] as? [Any] {
                    fixedClasses = arrAny.compactMap { $0 as? String }
                } else if let map = data["classes"] as? [String: Any] {
                    fixedClasses = map.values.compactMap { $0 as? String }
                }

                var fixedClubs: [String] = []
                if let arr = data["clubs"] as? [String] {
                    fixedClubs = arr
                } else if let arrAny = data["clubs"] as? [Any] {
                    fixedClubs = arrAny.compactMap { $0 as? String }
                } else if let map = data["clubs"] as? [String: Any] {
                    fixedClubs = map.values.compactMap { $0 as? String }
                }

                // First delete the bad fields entirely
                try await db.collection("users").document(userId).updateData([
                    "classes": FieldValue.delete(),
                    "clubs": FieldValue.delete(),
                    "classesVisibility": FieldValue.delete(),
                    "clubsVisibility": FieldValue.delete()
                ])

                // Then write them back cleanly
                try await db.collection("users").document(userId).setData([
                    "username": username,
                    "username_lowercase": usernameLower,
                    "name": name,
                    "classes": fixedClasses,
                    "clubs": fixedClubs,
                    "friends": friends,
                    "email": email,
                    "uid": uid,
                    "bio": bio,
                    "profileImageURL": profileImageURL as Any,
                    "classesVisibility": "Public",
                    "clubsVisibility": "Public"
                ], merge: true)

                print("Rebuilt user \(userId)")
            }

            print("Finished full migration")
        } catch {
            print("Error seeding user visibility: \(error)")
        }
    }

    func migrateThreadsToHaveOwners() async {
        do {
            let snapshot = try await db.collection("messages").getDocuments()
            var count = 0
            
            for document in snapshot.documents {
                let data = document.data()
                // If ownerId is missing or empty
                if data["ownerId"] == nil || (data["ownerId"] as? String)?.isEmpty == true {
                    let participants = data["participants"] as? [String] ?? []
                    let pending = data["pendingParticipants"] as? [String] ?? []
                    
                    // Pick the first active participant, or first pending if active is empty
                    if let newOwner = participants.first ?? pending.first {
                        try await db.collection("messages").document(document.documentID).updateData([
                            "ownerId": newOwner
                        ])
                        count += 1
                        print("Assigned owner \(newOwner) to thread \(document.documentID)")
                    }
                }
            }
            print("Successfully migrated \(count) threads.")
        } catch {
            print("Error migrating threads: \(error)")
        }
    }
}

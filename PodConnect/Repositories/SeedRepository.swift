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

    func seedSchoolEvents() async {
        for event in schoolEvents {
            do {
                try db.collection("schoolEvents").addDocument(from: event)
                print("Seeded: \(event.title)")
            } catch {
                print("Error seeding \(event.title): \(error)")
            }
        }
    }

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
    }
}

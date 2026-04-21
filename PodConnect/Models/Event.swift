//
//  Event.swift
//  PodConnect
//

import Foundation
import FirebaseFirestore

// School-provided campus event
struct SchoolEvent: Identifiable, Codable {
    @DocumentID var id: String?
    let title: String
    let date: Date
    let duration: TimeInterval
    let notes: String
    let category: String
}

// User-created personal event
struct UserEvent: Identifiable, Codable {
    var id = UUID()
    var uid: String = ""
    var title: String
    var startDate: Date
    var endDate: Date
    var notes: String
    var category: EventCategory
}

enum EventCategory: String, CaseIterable, Codable {
    case academic = "Academic"
    case arts = "Arts"
    case campusLife = "Campus Life"
    case wellness = "Wellness"
    case personal = "Personal"
    case work = "Work"
    case other = "Other"
}

// Helper to build dates cleanly
func makeDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    components.minute = minute
    return Calendar.current.date(from: components) ?? Date()
}

// MARK: - School Events Data
let schoolEvents: [SchoolEvent] = [
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 4, 8, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "MS Biotech Spring Mixer", date: makeDate(2026, 4, 8, 16, 0), duration: 3600, notes: "Grand Salon", category: "Campus Life"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 4, 9, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "Campus to Career Workshop", date: makeDate(2026, 4, 9, 12, 0), duration: 3600, notes: "Broome Library 1360", category: "Academic"),
    SchoolEvent(title: "NCLEX Review", date: makeDate(2026, 4, 10, 7, 0), duration: 3600, notes: "del Norte Hall 1500", category: "Academic"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 4, 10, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "Senior Music Rehearsal", date: makeDate(2026, 4, 10, 15, 0), duration: 3600, notes: "Malibu Hall 100", category: "Arts"),
    SchoolEvent(title: "NCLEX Review", date: makeDate(2026, 4, 11, 7, 0), duration: 3600, notes: "del Norte Hall 1500", category: "Academic"),
    SchoolEvent(title: "CSULB Social Work Program", date: makeDate(2026, 4, 11, 8, 0), duration: 3600, notes: "Bell Tower 1621, Bell Tower 2688, Bell Tower 2704", category: "Campus Life"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 4, 11, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 4, 12, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 4, 13, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 4, 14, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "Sigma Omega Nu Fundraiser", date: makeDate(2026, 4, 14, 11, 30), duration: 3600, notes: "Other Location", category: "Campus Life"),
    SchoolEvent(title: "Campus to Career Workshop", date: makeDate(2026, 4, 14, 12, 0), duration: 3600, notes: "Broome Library 1360", category: "Academic"),
    SchoolEvent(title: "PA 494 with MiRi Park", date: makeDate(2026, 4, 14, 13, 0), duration: 3600, notes: "Bell Tower East 2810 - Conference Room", category: "Academic"),
    SchoolEvent(title: "CHEM 122 Drop In Session", date: makeDate(2026, 4, 14, 17, 0), duration: 3600, notes: "Broome Library 1750", category: "Academic"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 4, 15, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "Future DGS Campus Visit Day", date: makeDate(2026, 4, 15, 8, 0), duration: 3600, notes: "Grand Salon", category: "Campus Life"),
    SchoolEvent(title: "Biol 433 - Computer Lab Session", date: makeDate(2026, 4, 15, 9, 0), duration: 3600, notes: "del Norte Hall 2535", category: "Academic"),
    SchoolEvent(title: "Career & Internship Fair - Spring 2026", date: makeDate(2026, 4, 15, 10, 0), duration: 3600, notes: "Broome Library Plaza", category: "Academic"),
    SchoolEvent(title: "ASI Elections: Lock In & Vote", date: makeDate(2026, 4, 15, 11, 0), duration: 3600, notes: "Student Union Dolphin Deck, Student Union Seabreeze Lawn", category: "Campus Life"),
    SchoolEvent(title: "Biol 433 - Computer Lab Session", date: makeDate(2026, 4, 15, 15, 0), duration: 3600, notes: "del Norte Hall 2535", category: "Academic"),
    SchoolEvent(title: "Wellness Workshop: Sexual Health", date: makeDate(2026, 4, 15, 15, 0), duration: 3600, notes: "Bell Tower 1602", category: "Wellness"),
    SchoolEvent(title: "Roller Skating Club Dolphin Disco", date: makeDate(2026, 4, 15, 17, 0), duration: 3600, notes: "Aliso Hall Plaza", category: "Campus Life"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 4, 16, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "Biol 433 - Computer Lab Session", date: makeDate(2026, 4, 16, 9, 0), duration: 3600, notes: "del Norte Hall 2535", category: "Academic"),
    SchoolEvent(title: "Echoes of Land Album Release Celebration", date: makeDate(2026, 4, 16, 15, 0), duration: 3600, notes: "Other Location", category: "Arts"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 4, 17, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "Admitted Dolphin Day | North Quad", date: makeDate(2026, 4, 18, 7, 0), duration: 3600, notes: "North Quad", category: "Campus Life"),
    SchoolEvent(title: "CSULB Social Work Program", date: makeDate(2026, 4, 18, 8, 0), duration: 3600, notes: "Bell Tower 1621, Bell Tower 2688, Bell Tower 2704", category: "Campus Life"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 4, 18, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 4, 19, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 4, 20, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "MATH 300 EXAM", date: makeDate(2026, 4, 20, 9, 0), duration: 3600, notes: "Bell Tower 2515", category: "Academic"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 4, 21, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "AAPI Panel Discussion", date: makeDate(2026, 4, 21, 12, 30), duration: 3600, notes: "Other Location", category: "Academic"),
    SchoolEvent(title: "PA 494 with MiRi Park", date: makeDate(2026, 4, 21, 13, 0), duration: 3600, notes: "Bell Tower East 2810 - Conference Room", category: "Academic"),
    SchoolEvent(title: "AAPI Signature Lecture", date: makeDate(2026, 4, 21, 14, 30), duration: 3600, notes: "Broome Library 2330", category: "Academic"),
    SchoolEvent(title: "CHEM 122 Drop In Session", date: makeDate(2026, 4, 21, 17, 0), duration: 3600, notes: "Broome Library 1750", category: "Academic"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 4, 22, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "Lecture - Centering Native Hawaiian Sovereignty", date: makeDate(2026, 4, 22, 13, 30), duration: 3600, notes: "Broome Library 2325", category: "Academic"),
    SchoolEvent(title: "Senior Music Recital", date: makeDate(2026, 4, 22, 15, 0), duration: 3600, notes: "Malibu Hall 100", category: "Arts"),
    SchoolEvent(title: "DolphinPalooza", date: makeDate(2026, 4, 22, 17, 0), duration: 3600, notes: "Central Mall East, Central Mall West, Central Mall South", category: "Campus Life"),
    SchoolEvent(title: "Sociology Alumni Event #4", date: makeDate(2026, 4, 22, 17, 30), duration: 3600, notes: "Broome Library 1750", category: "Campus Life"),
    SchoolEvent(title: "Asian Americans and Agriculture in Ventura County", date: makeDate(2026, 4, 22, 18, 0), duration: 3600, notes: "Broome Library 1360", category: "Campus Life"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 4, 23, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "HIST Seminar with Dr. Celest Menchaca", date: makeDate(2026, 4, 23, 16, 30), duration: 3600, notes: "Broome Library 2325", category: "Academic"),
    SchoolEvent(title: "AAPI Night Market", date: makeDate(2026, 4, 23, 18, 0), duration: 3600, notes: "Central Mall South", category: "Campus Life"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 4, 24, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "ESRM Field Methods Class", date: makeDate(2026, 4, 24, 8, 30), duration: 3600, notes: "CI Boating Center 001, CI Boating Center 002", category: "Academic"),
    SchoolEvent(title: "Art Film Festival", date: makeDate(2026, 4, 24, 16, 30), duration: 3600, notes: "Aliso Hall 150", category: "Arts"),
    SchoolEvent(title: "Psi Chi Induction Ceremony", date: makeDate(2026, 4, 24, 17, 0), duration: 3600, notes: "Petit Salon", category: "Campus Life"),
    SchoolEvent(title: "CSULB Social Work Program", date: makeDate(2026, 4, 25, 8, 0), duration: 3600, notes: "Bell Tower 2688, Bell Tower 2704", category: "Campus Life"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 4, 25, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 4, 26, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "ESRM Capstone", date: makeDate(2026, 4, 27, 8, 0), duration: 3600, notes: "Grand Salon", category: "Academic"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 4, 27, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 4, 28, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "Modoc Harvest Days", date: makeDate(2026, 4, 28, 9, 0), duration: 3600, notes: "Other Location", category: "Campus Life"),
    SchoolEvent(title: "PA 494 with MiRi Park", date: makeDate(2026, 4, 28, 13, 0), duration: 3600, notes: "Bell Tower East 2810 - Conference Room", category: "Academic"),
    SchoolEvent(title: "CHEM 122 Drop In Session", date: makeDate(2026, 4, 28, 17, 0), duration: 3600, notes: "Broome Library 1750", category: "Academic"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 4, 29, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "Zeta Pi Omega Denim Day Tabling", date: makeDate(2026, 4, 29, 11, 30), duration: 3600, notes: "Central Mall South", category: "Campus Life"),
    SchoolEvent(title: "Trivia Throwdown", date: makeDate(2026, 4, 29, 20, 0), duration: 3600, notes: "Student Union Dolphin Den", category: "Campus Life"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 4, 30, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "Celebration of Service 2026 Poster Session", date: makeDate(2026, 4, 30, 9, 0), duration: 3600, notes: "Grand Salon", category: "Academic"),
    SchoolEvent(title: "Lecture: Jess Gutierrez - Chicano Organic Intellectual", date: makeDate(2026, 4, 30, 12, 0), duration: 3600, notes: "Broome Library 1360", category: "Academic"),
    SchoolEvent(title: "Women of Color Association Community Gathering", date: makeDate(2026, 4, 30, 12, 0), duration: 3600, notes: "Petit Salon", category: "Campus Life"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 5, 1, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "Mucha Michele Day", date: makeDate(2026, 5, 1, 10, 0), duration: 3600, notes: "Broome Library 1320 - Exhibition Hall", category: "Campus Life"),
    SchoolEvent(title: "Delta Alpha Pi Induction and Award Ceremony", date: makeDate(2026, 5, 1, 12, 0), duration: 3600, notes: "Aliso Hall 150", category: "Campus Life"),
    SchoolEvent(title: "Yardi Scholars End of Year Celebration", date: makeDate(2026, 5, 1, 13, 0), duration: 3600, notes: "El Dorado Hall Park", category: "Campus Life"),
    SchoolEvent(title: "CI Student Research Symposium Classrooms", date: makeDate(2026, 5, 2, 8, 0), duration: 3600, notes: "del Norte Hall 1550, del Norte Hall 1530", category: "Academic"),
    SchoolEvent(title: "CSULB Social Work Program", date: makeDate(2026, 5, 2, 8, 0), duration: 3600, notes: "Bell Tower 1621, Bell Tower 2688, Bell Tower 2704", category: "Campus Life"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 5, 2, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "CI Student Research Symposium", date: makeDate(2026, 5, 2, 9, 0), duration: 3600, notes: "Grand Salon", category: "Academic"),
    SchoolEvent(title: "CI Student Research Symposium", date: makeDate(2026, 5, 2, 11, 0), duration: 3600, notes: "North Quad", category: "Academic"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 5, 3, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 5, 4, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "Phi Alpha Theta Induction Ceremony", date: makeDate(2026, 5, 4, 16, 0), duration: 3600, notes: "Broome Library - J. Handel Evans Conference Room", category: "Campus Life"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 5, 5, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "Registration Celebration", date: makeDate(2026, 5, 5, 10, 0), duration: 3600, notes: "Student Union Dolphin Deck, Student Union Seabreeze Lawn", category: "Academic"),
    SchoolEvent(title: "SPB Together We Craft - Senior Special", date: makeDate(2026, 5, 5, 12, 0), duration: 3600, notes: "Student Union Building 1080, Student Union Game Lounge", category: "Campus Life"),
    SchoolEvent(title: "Wellness Workshop: Sleep Hygiene", date: makeDate(2026, 5, 5, 12, 0), duration: 3600, notes: "Bell Tower 1602", category: "Wellness"),
    SchoolEvent(title: "PA 494 with MiRi Park", date: makeDate(2026, 5, 5, 13, 0), duration: 3600, notes: "Bell Tower East 2810 - Conference Room", category: "Academic"),
    SchoolEvent(title: "CHEM 122 Drop In Session", date: makeDate(2026, 5, 5, 17, 0), duration: 3600, notes: "Broome Library 1750", category: "Academic"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 5, 6, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "ASI Student Government Swearing In & Recognition Ceremony", date: makeDate(2026, 5, 6, 11, 0), duration: 3600, notes: "Student Union Dolphin Deck", category: "Campus Life"),
    SchoolEvent(title: "Teach Me Music Series", date: makeDate(2026, 5, 6, 12, 0), duration: 3600, notes: "Malibu Hall 100", category: "Arts"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 5, 7, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "Culminating Experience 2026 - Masters in Education", date: makeDate(2026, 5, 7, 15, 0), duration: 3600, notes: "Aliso Hall 150, Broome Library 2325, del Norte Hall 1500", category: "Academic"),
    SchoolEvent(title: "Music Student Showcase", date: makeDate(2026, 5, 7, 16, 0), duration: 3600, notes: "Other Location", category: "Arts"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 5, 8, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "Culminating Experience 2026", date: makeDate(2026, 5, 8, 15, 0), duration: 3600, notes: "Aliso Hall 150, del Norte Hall 1500, del Norte Hall 1530", category: "Academic"),
    SchoolEvent(title: "CSULB Social Work Program", date: makeDate(2026, 5, 9, 8, 0), duration: 3600, notes: "Bell Tower 1621, Bell Tower 2688, Bell Tower 2704", category: "Campus Life"),
    SchoolEvent(title: "Culminating Experience 2026 - Masters Students", date: makeDate(2026, 5, 9, 8, 0), duration: 3600, notes: "Aliso Hall 150", category: "Academic"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 5, 9, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "A&S STEAM Carnival", date: makeDate(2026, 5, 9, 13, 0), duration: 3600, notes: "North Quad, Gateway Hall, Gateway Paseo", category: "Campus Life"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 5, 10, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 5, 11, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 5, 12, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "ASI Dolphin Drop-In", date: makeDate(2026, 5, 12, 12, 0), duration: 3600, notes: "Student Union Dolphin Deck, Student Union Seabreeze Lawn", category: "Campus Life"),
    SchoolEvent(title: "PA 494 with MiRi Park", date: makeDate(2026, 5, 12, 13, 0), duration: 3600, notes: "Bell Tower East 2810 - Conference Room", category: "Academic"),
    SchoolEvent(title: "CHEM 122 Drop In Session", date: makeDate(2026, 5, 12, 17, 0), duration: 3600, notes: "Broome Library 1750", category: "Academic"),
    SchoolEvent(title: "English Capstone Presentations", date: makeDate(2026, 5, 12, 17, 30), duration: 3600, notes: "del Norte Hall 1500", category: "Academic"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 5, 13, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "Historiography Student Poster Presentations", date: makeDate(2026, 5, 13, 15, 0), duration: 3600, notes: "Malibu Hall 100", category: "Academic"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 5, 14, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "Nursing Pinning Ceremony", date: makeDate(2026, 5, 14, 13, 0), duration: 3600, notes: "North Quad", category: "Campus Life"),
    SchoolEvent(title: "Spring 2026 Communication Gala", date: makeDate(2026, 5, 14, 16, 30), duration: 3600, notes: "Petit Salon", category: "Campus Life"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 5, 15, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "PSY 301 Spring '26 Poster Session", date: makeDate(2026, 5, 15, 12, 0), duration: 3600, notes: "Grand Salon", category: "Academic"),
    SchoolEvent(title: "Computer Science Capstone Gala", date: makeDate(2026, 5, 15, 14, 0), duration: 3600, notes: "Petit Salon", category: "Academic"),
    SchoolEvent(title: "Honors Convocation", date: makeDate(2026, 5, 15, 16, 30), duration: 3600, notes: "North Quad", category: "Campus Life"),
    SchoolEvent(title: "CSULB Social Work Program", date: makeDate(2026, 5, 16, 8, 0), duration: 3600, notes: "Bell Tower 1621, Bell Tower 2688, Bell Tower 2704", category: "Campus Life"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 5, 16, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 5, 17, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "Affinity Celebrations Hold", date: makeDate(2026, 5, 18, 8, 0), duration: 3600, notes: "Grand Salon, Petit Salon, North Quad, Dullam Courtyard", category: "Campus Life"),
]

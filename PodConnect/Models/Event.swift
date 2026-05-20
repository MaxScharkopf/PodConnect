//
//  Event.swift
//  PodConnect
//

import Foundation

// School-provided campus event
struct SchoolEvent: Identifiable {
    let id = UUID()
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
    var recurrenceGroupId: String? = nil
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

    // May 20
    SchoolEvent(title: "Affinity Celebrations Hold", date: makeDate(2026, 5, 20, 8, 0), duration: 3600, notes: "Grand Salon, Petit Salon, North Quad, Dullam Courtyard", category: "Campus Life"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 5, 20, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "CAPS Director Search Open Forum - Dr. Michael Wetter", date: makeDate(2026, 5, 20, 14, 15), duration: 3600, notes: "Broome Library - J. Handel Evans Conference Room", category: "Academic"),
    SchoolEvent(title: "Affinity - Dullam Courtyard", date: makeDate(2026, 5, 20, 15, 0), duration: 3600, notes: "Dullam Courtyard", category: "Campus Life"),
    SchoolEvent(title: "Veterans Medallion Ceremony", date: makeDate(2026, 5, 20, 15, 0), duration: 3600, notes: "Dullam Courtyard", category: "Campus Life"),
    SchoolEvent(title: "Lavender Stoling Ceremony", date: makeDate(2026, 5, 20, 18, 0), duration: 3600, notes: "Petit Salon", category: "Campus Life"),

    // May 21
    SchoolEvent(title: "Affinity Celebrations Hold", date: makeDate(2026, 5, 21, 8, 0), duration: 3600, notes: "Grand Salon, Petit Salon, North Quad, Dullam Courtyard", category: "Campus Life"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 5, 21, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "Dance Studies Culmination Event", date: makeDate(2026, 5, 21, 16, 0), duration: 3600, notes: "Other Location", category: "Arts"),
    SchoolEvent(title: "AAPI (Asian American & Pacific Islander) Stoling Ceremony", date: makeDate(2026, 5, 21, 18, 0), duration: 3600, notes: "Grand Salon", category: "Campus Life"),

    // May 22
    SchoolEvent(title: "Affinity Celebrations Hold", date: makeDate(2026, 5, 22, 8, 0), duration: 3600, notes: "Grand Salon, Petit Salon, North Quad, Dullam Courtyard", category: "Campus Life"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 5, 22, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "Spanish Capstone Celebration", date: makeDate(2026, 5, 22, 9, 30), duration: 3600, notes: "Bell Tower 2515", category: "Academic"),
    SchoolEvent(title: "Dolphins of Turtle Island", date: makeDate(2026, 5, 22, 12, 0), duration: 3600, notes: "Petit Salon", category: "Campus Life"),
    SchoolEvent(title: "Black Student Stoling", date: makeDate(2026, 5, 22, 15, 0), duration: 3600, notes: "Grand Salon", category: "Campus Life"),
    SchoolEvent(title: "Si Se Pudo", date: makeDate(2026, 5, 22, 18, 0), duration: 3600, notes: "North Quad", category: "Campus Life"),

    // May 23
    SchoolEvent(title: "CSULB Social Work Program", date: makeDate(2026, 5, 23, 8, 0), duration: 3600, notes: "Bell Tower 1621, Bell Tower 2688, Bell Tower 2704", category: "Campus Life"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 5, 23, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),

    // May 24
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 5, 24, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),

    // May 25
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 5, 25, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),

    // May 26
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 5, 26, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),

    // May 27
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 5, 27, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),

    // May 28
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 5, 28, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),

    // May 29
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 5, 29, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
    SchoolEvent(title: "¡Ay Chihuahua! Auditions", date: makeDate(2026, 5, 29, 16, 0), duration: 3600, notes: "Malibu Hall 140", category: "Arts"),
    SchoolEvent(title: "Auditions for the Fall 2026 Musical", date: makeDate(2026, 5, 29, 19, 0), duration: 3600, notes: "Malibu Hall 140", category: "Arts"),

    // May 30
    SchoolEvent(title: "CSULB Social Work Program", date: makeDate(2026, 5, 30, 7, 0), duration: 3600, notes: "Bell Tower 1621, Bell Tower 2688, Bell Tower 2704", category: "Campus Life"),
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 5, 30, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),

    // May 31
    SchoolEvent(title: "Exhibition of Bobi Bosson Artwork", date: makeDate(2026, 5, 31, 8, 0), duration: 3600, notes: "Broome Library 2537 - Art Gallery", category: "Arts"),
]

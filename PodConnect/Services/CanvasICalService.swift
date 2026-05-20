//
//  CanvasICalService.swift
//  PodConnect
//
//  Created by Kassidy Barbara-Rose Saffa on 5/9/26.
//

import Foundation

final class CanvasICalService {

    func fetchAssignments(from urlString: String) async throws -> [CanvasAssignment] {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)

        guard let text = String(data: data, encoding: .utf8) else {
            return []
        }

        return parseICS(text)
    }

    private func parseICS(_ text: String) -> [CanvasAssignment] {
        var assignments: [CanvasAssignment] = []

        // Unfold ICS lines (RFC 5545: CRLF + space/tab = continuation)
        let unfolded = text
            .replacingOccurrences(of: "\r\n ", with: "")
            .replacingOccurrences(of: "\r\n\t", with: "")

        let events = unfolded.components(separatedBy: "BEGIN:VEVENT")

        for event in events {
            guard event.contains("SUMMARY") else { continue }

            // Split on \r\n or \n
            let lines = event.components(separatedBy: "\r\n").flatMap {
                $0.components(separatedBy: "\n")
            }

            var title: String = ""
            var date: Date?
            var id: String = UUID().uuidString

            for line in lines {
                if line.starts(with: "SUMMARY:") {
                    title = line.replacingOccurrences(of: "SUMMARY:", with: "")
                }

                if line.starts(with: "DTSTART") {
                    let value = line.components(separatedBy: ":").last ?? ""
                    date = parseDate(value)
                }

                if line.starts(with: "UID:") {
                    id = line.replacingOccurrences(of: "UID:", with: "")
                }
            }

            if let date {
                let assignment = CanvasAssignment(
                    id: id,
                    title: title,
                    dueDate: date,
                    courseName: nil
                )
                assignments.append(assignment)
            }
        }

        return assignments
    }

    private func parseDate(_ string: String) -> Date? {
        let cleaned = string.trimmingCharacters(in: .whitespacesAndNewlines)

        let formats = [
            "yyyyMMdd'T'HHmmss'Z'",
            "yyyyMMdd'T'HHmmss",
            "yyyyMMdd"
        ]

        for format in formats {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.timeZone = format.contains("'Z'") ? TimeZone(secondsFromGMT: 0) : .current

            if format == "yyyyMMdd",
               let date = formatter.date(from: cleaned) {
                return Calendar.current.date(bySettingHour: 23, minute: 59, second: 0, of: date)
            }
            
            if let date = formatter.date(from: cleaned) {
                return date
            }
            
            
        }

        return nil
    }
}

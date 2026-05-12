//
//  WeatherCardView.swift
//  PodConnect
//

import SwiftUI

private struct OpenMeteoResponse: Decodable {
    let current: Current
    let hourly: Hourly

    struct Current: Decodable {
        let temperature2m: Double
        let weathercode: Int

        enum CodingKeys: String, CodingKey {
            case temperature2m = "temperature_2m"
            case weathercode   = "weather_code"
        }
    }

    struct Hourly: Decodable {
        let time: [String]
        let temperature2m: [Double]
        let weathercode: [Int]

        enum CodingKeys: String, CodingKey {
            case time
            case temperature2m = "temperature_2m"
            case weathercode   = "weather_code"
        }
    }
}

private struct HourSlot: Identifiable {
    let id = UUID()
    let label: String
    let temp: String
    let symbol: String
}

struct WeatherCardView: View {
    @State private var tempF: Double? = nil
    @State private var weatherCode: Int? = nil
    @State private var nextHours: [HourSlot] = []
    @State private var failed = false

    private let skyBlue = Color(red: 100/255, green: 180/255, blue: 230/255)

    private var tempString: String {
        guard let tempF else { return "--" }
        return "\(Int(tempF.rounded()))°F"
    }

    private var conditionLabel: String { label(for: weatherCode) }
    private var symbolName: String { symbol(for: weatherCode) }

    var body: some View {
        HStack(spacing: 16) {
            // Current conditions
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: symbolName)
                    .font(.title2)
                    .foregroundColor(.white.opacity(tempF == nil ? 0.5 : 1))

                Spacer()

                Text(failed ? "Unavailable" : tempString)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(failed ? "" : conditionLabel)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(1)
            }

            if !nextHours.isEmpty {
                Divider()
                    .overlay(.white.opacity(0.4))

                // Hourly forecast
                HStack(spacing: 0) {
                    ForEach(nextHours) { slot in
                        VStack(spacing: 5) {
                            Text(slot.label)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                            Image(systemName: slot.symbol)
                                .font(.callout)
                                .foregroundColor(.white)
                            Text(slot.temp)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(skyBlue)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
        .task { await fetchWeather() }
    }

    private func fetchWeather() async {
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=34.1636&longitude=-119.0425&current=temperature_2m,weather_code&hourly=temperature_2m,weather_code&temperature_unit=fahrenheit&timezone=America%2FLos_Angeles&forecast_days=2"
        guard let url = URL(string: urlString) else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            tempF = response.current.temperature2m
            weatherCode = response.current.weathercode
            nextHours = buildHourSlots(from: response.hourly)
        } catch {
            failed = true
            print("Weather fetch error:", error)
        }
    }

    private func buildHourSlots(from hourly: OpenMeteoResponse.Hourly) -> [HourSlot] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        formatter.timeZone = TimeZone(identifier: "America/Los_Angeles")

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "ha"
        displayFormatter.timeZone = TimeZone(identifier: "America/Los_Angeles")

        let now = Date()
        var slots: [HourSlot] = []

        for (i, timeStr) in hourly.time.enumerated() {
            guard let date = formatter.date(from: timeStr), date > now else { continue }
            let temp = "\(Int(hourly.temperature2m[i].rounded()))°"
            let sym = symbol(for: hourly.weathercode[i])
            let lbl = displayFormatter.string(from: date).lowercased()
            slots.append(HourSlot(label: lbl, temp: temp, symbol: sym))
            if slots.count == 4 { break }
        }
        return slots
    }

    private func label(for code: Int?) -> String {
        guard let code else { return "Loading..." }
        switch code {
        case 0:          return "Clear Sky"
        case 1:          return "Mostly Clear"
        case 2:          return "Partly Cloudy"
        case 3:          return "Overcast"
        case 45, 48:     return "Foggy"
        case 51, 53, 55: return "Drizzle"
        case 61, 63, 65: return "Rain"
        case 71, 73, 75: return "Snow"
        case 80, 81, 82: return "Rain Showers"
        case 95:         return "Thunderstorm"
        default:         return "Cloudy"
        }
    }

    private func symbol(for code: Int?) -> String {
        guard let code else { return "cloud" }
        switch code {
        case 0:          return "sun.max.fill"
        case 1:          return "sun.haze.fill"
        case 2:          return "cloud.sun.fill"
        case 3:          return "cloud.fill"
        case 45, 48:     return "cloud.fog.fill"
        case 51, 53, 55: return "cloud.drizzle.fill"
        case 61, 63, 65: return "cloud.rain.fill"
        case 71, 73, 75: return "cloud.snow.fill"
        case 80, 81, 82: return "cloud.heavyrain.fill"
        case 95:         return "cloud.bolt.rain.fill"
        default:         return "cloud.fill"
        }
    }
}

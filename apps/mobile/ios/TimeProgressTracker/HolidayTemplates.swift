import Foundation

struct HolidayTemplate: Identifiable, Codable {
    let id: String
    let name: String
    let flag: String
    let holidays: [Holiday]
}

struct HolidayTemplateLibrary {
    static let shared = HolidayTemplateLibrary()

    var templates: [HolidayTemplate] {
        [usa2026, india2026, dubai2026, germany2026, france2026, spain2026, italy2026, netherlands2026, japan2026, china2026, korea2026, brazil2026, russia2026]
    }

    private func h(_ name: String, _ date: String) -> Holiday { Holiday(name: name, dateString: date) }

    private var usa2026: HolidayTemplate {
        HolidayTemplate(
            id: "usa_2026",
            name: "USA 2026",
            flag: "🇺🇸",
            holidays: [
                h("New Year's Day", "2026-01-01"), h("Martin Luther King Jr. Day", "2026-01-19"), h("Valentine's Day", "2026-02-14"), h("Washington's Birthday", "2026-02-16"), h("St. Patrick's Day", "2026-03-17"), h("Easter Sunday", "2026-04-05"), h("Tax Day", "2026-04-15"), h("Administrative Professionals Day", "2026-04-22"), h("Mother's Day", "2026-05-10"), h("Memorial Day", "2026-05-25"), h("Juneteenth", "2026-06-19"), h("Father's Day", "2026-06-21"), h("Independence Day (sub)", "2026-07-03"), h("Independence Day", "2026-07-04"), h("Labor Day", "2026-09-07"), h("Columbus Day", "2026-10-12"), h("Halloween", "2026-10-31"), h("Veterans Day", "2026-11-11"), h("Thanksgiving Day", "2026-11-26"), h("Day after Thanksgiving", "2026-11-27"), h("Christmas Eve", "2026-12-24"), h("Christmas Day", "2026-12-25"), h("New Year's Eve", "2026-12-31")
            ]
        )
    }

    private var india2026: HolidayTemplate {
        HolidayTemplate(
            id: "india_2026",
            name: "India 2026",
            flag: "🇮🇳",
            holidays: [
                h("New Year's Day", "2026-01-01"), h("Pongal", "2026-01-15"), h("Thiruvalluvar Day", "2026-01-16"), h("Republic Day", "2026-01-26"), h("Good Friday", "2026-04-03"), h("Tamil New Year", "2026-04-14"), h("May Day", "2026-05-01"), h("Bakrid", "2026-05-28"), h("Milad-un-Nabi", "2026-08-26"), h("Krishna Jayanthi", "2026-09-04"), h("Vinayagar Chaturthi", "2026-09-14"), h("Gandhi Jayanthi", "2026-10-02"), h("Ayutha Pooja", "2026-10-19"), h("Vijayadasami", "2026-10-20"), h("Deepavali Next Day", "2026-11-09"), h("Christmas", "2026-12-25")
            ]
        )
    }

    private var dubai2026: HolidayTemplate {
        HolidayTemplate(
            id: "dubai_2026",
            name: "Dubai/UAE 2026",
            flag: "🇦🇪",
            holidays: [
                h("New Year's Day", "2026-01-01"), h("Eid Al Fitr", "2026-03-20"), h("Eid Al Fitr Day 2", "2026-03-21"), h("Eid Al Fitr Day 3", "2026-03-22"), h("Arafat Day", "2026-05-26"), h("Eid Al Adha", "2026-05-27"), h("Eid Al Adha Day 2", "2026-05-28"), h("Eid Al Adha Day 3", "2026-05-29"), h("Islamic New Year", "2026-06-16"), h("Prophet's Birthday", "2026-08-25"), h("UAE National Day", "2026-12-02"), h("UAE National Day 2", "2026-12-03")
            ]
        )
    }

    private var germany2026: HolidayTemplate { HolidayTemplate(id: "germany_2026", name: "Germany 2026", flag: "🇩🇪", holidays: [h("New Year's Day", "2026-01-01"), h("International Women's Day", "2026-03-08"), h("Good Friday", "2026-04-03"), h("Easter Monday", "2026-04-06"), h("Labor Day", "2026-05-01"), h("Ascension Day", "2026-05-14"), h("Whit Monday", "2026-05-25"), h("Corpus Christi", "2026-06-04"), h("German Unity Day", "2026-10-03"), h("All Saints' Day", "2026-11-01"), h("Christmas Day", "2026-12-25"), h("St. Stephen's Day", "2026-12-26")] ) }

    private var france2026: HolidayTemplate { HolidayTemplate(id: "france_2026", name: "France 2026", flag: "🇫🇷", holidays: [h("New Year's Day", "2026-01-01"), h("Easter Monday", "2026-04-06"), h("Labor Day", "2026-05-01"), h("Victory Day", "2026-05-08"), h("Ascension Day", "2026-05-14"), h("Whit Monday", "2026-05-25"), h("Bastille Day", "2026-07-14"), h("Assumption of Mary", "2026-08-15"), h("All Saints' Day", "2026-11-01"), h("Armistice Day", "2026-11-11"), h("Christmas Day", "2026-12-25")] ) }

    private var spain2026: HolidayTemplate { HolidayTemplate(id: "spain_2026", name: "Spain 2026", flag: "🇪🇸", holidays: [h("New Year's Day", "2026-01-01"), h("Epiphany", "2026-01-06"), h("Good Friday", "2026-04-03"), h("Labor Day", "2026-05-01"), h("Assumption of Mary", "2026-08-15"), h("Hispanic Day", "2026-10-12"), h("All Saints' Day", "2026-11-01"), h("Constitution Day", "2026-12-06"), h("Immaculate Conception", "2026-12-08"), h("Christmas Day", "2026-12-25")] ) }

    private var italy2026: HolidayTemplate { HolidayTemplate(id: "italy_2026", name: "Italy 2026", flag: "🇮🇹", holidays: [h("New Year's Day", "2026-01-01"), h("Epiphany", "2026-01-06"), h("Easter Monday", "2026-04-06"), h("Liberation Day", "2026-04-25"), h("Labor Day", "2026-05-01"), h("Republic Day", "2026-06-02"), h("Ferragosto", "2026-08-15"), h("All Saints' Day", "2026-11-01"), h("Immaculate Conception", "2026-12-08"), h("Christmas Day", "2026-12-25"), h("St. Stephen's Day", "2026-12-26")] ) }

    private var netherlands2026: HolidayTemplate { HolidayTemplate(id: "netherlands_2026", name: "Netherlands 2026", flag: "🇳🇱", holidays: [h("New Year's Day", "2026-01-01"), h("Easter Sunday", "2026-04-05"), h("Easter Monday", "2026-04-06"), h("King's Day", "2026-04-27"), h("Liberation Day", "2026-05-05"), h("Ascension Day", "2026-05-14"), h("Whit Monday", "2026-05-25"), h("Christmas Day", "2026-12-25"), h("Second Day of Christmas", "2026-12-26")] ) }

    private var japan2026: HolidayTemplate { HolidayTemplate(id: "japan_2026", name: "Japan 2026", flag: "🇯🇵", holidays: [h("New Year's Day", "2026-01-01"), h("Coming of Age Day", "2026-01-12"), h("Foundation Day", "2026-02-11"), h("Emperor's Birthday", "2026-02-23"), h("Vernal Equinox", "2026-03-21"), h("Showa Day", "2026-04-29"), h("Constitution Memorial Day", "2026-05-03"), h("Greenery Day", "2026-05-04"), h("Children's Day", "2026-05-05"), h("Marine Day", "2026-07-20"), h("Mountain Day", "2026-08-11"), h("Respect for the Aged Day", "2026-09-21"), h("Autumnal Equinox", "2026-09-23"), h("Sports Day", "2026-10-12"), h("Culture Day", "2026-11-03"), h("Labor Thanksgiving Day", "2026-11-23")] ) }

    private var china2026: HolidayTemplate { HolidayTemplate(id: "china_2026", name: "China 2026", flag: "🇨🇳", holidays: [h("New Year's Day", "2026-01-01"), h("Chinese New Year", "2026-02-17"), h("Qingming Festival", "2026-04-05"), h("Labor Day", "2026-05-01"), h("Dragon Boat Festival", "2026-06-19"), h("Mid-Autumn Festival", "2026-09-25"), h("National Day", "2026-10-01")] ) }

    private var korea2026: HolidayTemplate { HolidayTemplate(id: "southkorea_2026", name: "South Korea 2026", flag: "🇰🇷", holidays: [h("New Year's Day", "2026-01-01"), h("Seollal (Day 1)", "2026-02-16"), h("Seollal (Day 2)", "2026-02-17"), h("Seollal (Day 3)", "2026-02-18"), h("Independence Movement Day", "2026-03-01"), h("Children's Day", "2026-05-05"), h("Buddha's Birthday", "2026-05-24"), h("Memorial Day", "2026-06-06"), h("Liberation Day", "2026-08-15"), h("Chuseok (Day 1)", "2026-09-24"), h("Chuseok (Day 2)", "2026-09-25"), h("Chuseok (Day 3)", "2026-09-26"), h("National Foundation Day", "2026-10-03"), h("Hangeul Day", "2026-10-09"), h("Christmas Day", "2026-12-25")] ) }

    private var brazil2026: HolidayTemplate { HolidayTemplate(id: "brazil_2026", name: "Brazil 2026", flag: "🇧🇷", holidays: [h("New Year's Day", "2026-01-01"), h("Carnival Monday", "2026-02-16"), h("Carnival Tuesday", "2026-02-17"), h("Good Friday", "2026-04-03"), h("Tiradentes Day", "2026-04-21"), h("Labor Day", "2026-05-01"), h("Corpus Christi", "2026-06-04"), h("Independence Day", "2026-09-07"), h("Our Lady of Aparecida", "2026-10-12"), h("All Souls' Day", "2026-11-02"), h("Republic Day", "2026-11-15"), h("Christmas Day", "2026-12-25")] ) }

    private var russia2026: HolidayTemplate { HolidayTemplate(id: "russia_2026", name: "Russia 2026", flag: "🇷🇺", holidays: [h("New Year's Day", "2026-01-01"), h("Orthodox Christmas", "2026-01-07"), h("Defender of the Fatherland Day", "2026-02-23"), h("International Women's Day", "2026-03-08"), h("Spring and Labor Day", "2026-05-01"), h("Victory Day", "2026-05-09"), h("Russia Day", "2026-06-12"), h("Unity Day", "2026-11-04")] ) }
}

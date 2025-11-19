import Foundation
import Combine



struct DailyLog: Codable, Identifiable {
    var id = UUID()
    let date: Date
    var logs: [String]
}

// Manages the storage of words and daily logs using UserDefaults.
class WordStorage: ObservableObject {
    @Published var dailyLogs: [DailyLog] = [] {
        didSet {
            saveLogs()
        }
    }
    @Published var words: [Word] {
        didSet {
            saveWords()
        }
    }

    private let wordsKey = "words"
    private let logsKey = "dailyLogs"

    init() {
        self.words = WordStorage.loadWords()
        self.dailyLogs = WordStorage.loadLogs()
        cleanOldLogs()
        updateSharedDefaults()
        loadLocalDictionary()
    }

    // Loads words from UserDefaults.
    private static func loadWords() -> [Word] {
        if let data = UserDefaults.standard.data(forKey: "words") {
            if let decodedWords = try? JSONDecoder().decode([Word].self, from: data) {
                return decodedWords
            }
        }
        return []
    }

    // Loads daily logs from UserDefaults.
    private static func loadLogs() -> [DailyLog] {
        if let data = UserDefaults.standard.data(forKey: "dailyLogs") {
            if let decodedLogs = try? JSONDecoder().decode([DailyLog].self, from: data) {
                return decodedLogs
            }
        }
        return []
    }

    // Saves the current array of words to UserDefaults.
    private func saveWords() {
        if let encodedWords = try? JSONEncoder().encode(words) {
            UserDefaults.standard.set(encodedWords, forKey: "words")
        }
        // Also save to shared UserDefaults for widgets
        updateSharedDefaults()
    }

    // Saves the current array of daily logs to UserDefaults.
    private func saveLogs() {
        if let encodedLogs = try? JSONEncoder().encode(dailyLogs) {
            UserDefaults.standard.set(encodedLogs, forKey: "dailyLogs")
        }
    }

    // Updates shared UserDefaults for widgets
    private func updateSharedDefaults() {
        let sharedDefaults = UserDefaults(suiteName: "group.com.nok.WordGarden")
        sharedDefaults?.set(words.count, forKey: "wordCount")
        // Also save completed tasks if we have them
        // This would be managed by the DiscoverView, but we can save the current state
    }

    // Retrieves the index for today's log, creating a new log if one doesn't exist.
    private func getTodaysLogIndex() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        if let index = dailyLogs.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            return index
        } else {
            let newLog = DailyLog(date: today, logs: [])
            dailyLogs.append(newLog)
            return dailyLogs.count - 1
        }
    }

    // Adds a new string entry to the log for the current day.
    func addLogEntry(_ entry: String) {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timestamp = timeFormatter.string(from: Date())
        let entryWithTime = "[\(timestamp)] \(entry)"
        
        let index = getTodaysLogIndex()
        dailyLogs[index].logs.append(entryWithTime)
    }

    // Removes log entries that are older than seven days.
    private func cleanOldLogs() {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        dailyLogs = dailyLogs.filter { $0.date >= sevenDaysAgo }
    }

    // Responds to changes in the ubiquitous key-value store.
    @objc private func ubiquitousKeyValueStoreDidChange(notification: Notification) {
        self.words = WordStorage.loadWords()
    }

    // Adds a new Word object to the words array.
    func addWord(text: String, definition: String, example: String) {
        let newWord = Word(text: text, definition: definition, example: example)
        words.append(newWord)
    }

    // Increases the growth level of a word by reviewing it.
    func reviewWord(wordID: UUID) {
        if let index = words.firstIndex(where: { $0.id == wordID }) {
            words[index].growthLevel = min(words[index].growthLevel + 1, 5) // Max level 5
        }
    }

    // Exports the current words array to a JSON string.
    func exportData() -> String? {
        if let data = try? JSONEncoder().encode(words) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }

    // Imports words from a JSON string, merging them with existing words while avoiding duplicates.
    func importData(json: String) -> Bool {
        guard let data = json.data(using: .utf8),
              let importedWords = try? JSONDecoder().decode([Word].self, from: data) else {
            return false
        }

        let existingWordTexts = Set(words.map { $0.text.lowercased() })

        for word in importedWords {
            if !existingWordTexts.contains(word.text.lowercased()) {
                words.append(word)
            }
        }
        return true
    }

    // Generates words suitable for flashcards using local data only.
    func generateWordsForFlashcards() -> [Word] {
        words.filter { !$0.definition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    // MARK: - Local Dictionary
    private var localDictionary: [String: String] = [:]

    func lookupDefinition(for text: String) -> String? {
        let key = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return localDictionary[key]
    }

    private func loadLocalDictionary() {
        if let url = Bundle.main.url(forResource: "common_words", withExtension: "csv"),
           let data = try? Data(contentsOf: url),
           let csv = String(data: data, encoding: .utf8) {
            parseCSV(csv)
            return
        }
        parseCSV(WordStorage.embeddedCommonWordsCSV)
    }

    private func parseCSV(_ csv: String) {
        var dict: [String: String] = [:]
        for line in csv.split(separator: "\n") {
            let parts = line.split(separator: ",", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespaces) }
            if parts.count == 2 {
                let word = parts[0].lowercased()
                let def = parts[1]
                dict[word] = def
            }
        }
        localDictionary = dict
    }

    private static let embeddedCommonWordsCSV = """
ability,skill to do something well
accept,agree to receive or undertake
active,engaging in action or activity
advice,recommendation offered about future action
allow,permit or give permission
answer,response to a question
arrive,reach a place
artist,person who creates art
balance,even distribution ensuring stability
beautiful,pleasing the senses or mind
believe,accept as true
benefit,advantage or profit gained
begin,start to do something
better,more excellent or effective
bridge,structure carrying a path over a gap
build,construct by putting parts together
calm,free from excitement or disturbance
care,serious attention or consideration
center,point equally distant from edges
change,make or become different
clean,free from dirt, marks or stains
clear,easy to understand; transparent
close,shut something or nearby
collect,bring together and gather
common,frequent; shared by many
connect,join together
create,bring something into existence
decide,make a choice
deep,extending far down
define,explain the meaning
detail,individual fact or item
develop,grow or cause to grow
easy,achieved without great effort
edge,line where a surface ends
energy,capacity for activity or work
enjoy,take pleasure in
example,representative item or case
exercise,activity to improve health
family,group related by blood or marriage
focus,center of interest or activity
friend,person attached by affection
future,time yet to come
garden,plot for growing plants
goal,desired result or outcome
grow,increase in size or maturity
happy,feeling or showing pleasure
help,make easier for someone
idea,thought or suggestion
important,of great significance or value
improve,make better
include,make part of a whole
interest,curiosity or stake in something
kind,considerate or type of thing
learn,gain knowledge or skill
light,illumination; not heavy
listen,give attention to sound
love,deep affection
make,form or produce
manage,be in charge of; handle
measure,ascertain size or amount
memory,capacity to remember
money,medium of exchange
nature,physical world and life
need,require something essential
open,allow access; not closed
order,arrangement; command
parent,father or mother
peace,freedom from disturbance
people,human beings in general
plan,decide on and arrange
practice,repeat to improve skill
present,existing or gift
protect,keep safe from harm
quick,fast; prompt
read,look at and understand text
reduce,make smaller in amount
repeat,do again
respect,admiration due to qualities
safe,protected from danger
school,place for education
simple,easy to understand or do
slow,not fast
smart,intelligent or neat
space,area available; cosmos
special,different from usual; important
start,beginning of an activity
strong,powerful; not weak
study,apply the mind to learning
support,back up or help
teach,give knowledge or skill
team,group working together
think,have ideas or opinions
time,continued progress of existence
travel,go from one place to another
use,apply for a purpose
value,importance; worth
voice,sound produced in speaking
water,clear liquid essential for life
word,a unit of language
work,activity involving effort
write,compose text
"""
}

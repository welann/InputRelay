import Foundation
import Testing
@testable import InputRelay

struct AppRuleTests {
    @Test func addingRulesTrimsWhitespaceAndRejectsEmptyOrDuplicates() {
        var profile = Profile(name: "Anki")
        let emptyName = profile.addAppRule(.appName(" \n "))
        let emptyID = profile.addAppRule(.bundleID(""))
        let addedID = profile.addAppRule(.bundleID("  net.ankiweb.dtop \n"))
        let duplicateID = profile.addAppRule(.bundleID("NET.ANKIWEB.DTOP"))
        #expect(!emptyName && !emptyID && addedID && !duplicateID)
        #expect(profile.appRules == [.bundleID("net.ankiweb.dtop")])
        let addedName = profile.addAppRule(.appName(" Anki "))
        let duplicateName = profile.addAppRule(.appName("anki"))
        #expect(addedName && !duplicateName)
        #expect(profile.appRules.count == 2)
    }

    @Test func bundleIDsAreExactAndNamesRemainPartialCaseInsensitive() {
        #expect(AppRule.bundleID("net.ankiweb.dtop").matches(bundleID: "net.ankiweb.dtop", appName: "Anki"))
        #expect(!AppRule.bundleID("net.ankiweb.dtop").matches(bundleID: "net.ankiweb.dtop.helper", appName: "Anki Helper"))
        #expect(AppRule.appName(" CHROME ").matches(bundleID: "com.google.Chrome", appName: "Google Chrome"))
        #expect(!AppRule.appName(" ").matches(bundleID: "com.inputrelay.app", appName: "InputRelay"))
        #expect(!AppRule.bundleID("").matches(bundleID: "", appName: "InputRelay"))
    }

    @Test func specificProfileWinsEvenWhenGlobalComesFirst() {
        let global = Profile(name: "全局配置")
        let nameMatch = Profile(name: "Name match", appRules: [.appName("anki")])
        let exactMatch = Profile(name: "Anki", appRules: [.bundleID("net.ankiweb.dtop")])
        let profiles = [global, nameMatch, exactMatch]
        #expect(Profile.preferredProfile(in: profiles, bundleID: "net.ankiweb.dtop", appName: "Anki")?.id == exactMatch.id)
        #expect(Profile.preferredProfile(in: profiles, bundleID: "net.ankiweb.other", appName: "Anki Beta")?.id == nameMatch.id)
        #expect(Profile.preferredProfile(in: profiles, bundleID: "com.apple.finder", appName: "Finder")?.id == global.id)
        #expect(Profile.preferredProfile(in: [exactMatch], bundleID: "com.apple.finder", appName: "Finder") == nil)
    }

    @Test func savedApplicationRulesReloadAndMatch() throws {
        var profile = Profile(name: "Anki")
        let added = profile.addAppRule(.bundleID("net.ankiweb.dtop"))
        #expect(added)
        let reloaded = try JSONDecoder().decode(Profile.self, from: JSONEncoder().encode(profile))
        #expect(reloaded.matches(bundleID: "net.ankiweb.dtop", appName: "Anki"))
        #expect(!reloaded.matches(bundleID: "com.inputrelay.app", appName: "InputRelay"))
        #expect(reloaded.appRules == profile.appRules)
    }
}

import Foundation

@main
enum MordeHostNavigationTests {
    static func main() {
        let origin = URL(string: "https://host.example")!
        precondition(isAllowedMordeHostNavigation(URL(string: "https://HOST.example:443/tasks/1"), relativeTo: origin))
        precondition(isAllowedMordeHostNavigation(URL(string: "https://host.example/tasks/1"), relativeTo: URL(string: "https://HOST.example:443")!))
        precondition(!isAllowedMordeHostNavigation(URL(string: "https://other.example/tasks"), relativeTo: origin))
        precondition(!isAllowedMordeHostNavigation(URL(string: "https://host.example:444/tasks"), relativeTo: origin))
        precondition(!isAllowedMordeHostNavigation(URL(string: "http://host.example/tasks"), relativeTo: origin))
        precondition(!isAllowedMordeHostNavigation(URL(string: "https://user@host.example/tasks"), relativeTo: origin))
        precondition(canStartMordeAction(busy: false))
        precondition(!canStartMordeAction(busy: true))
        precondition(canRetryMordeBatchItem(taskStatus: "failed", itemStatus: "failed"))
        precondition(!canRetryMordeBatchItem(taskStatus: "running", itemStatus: "failed"))
        precondition(!canRetryMordeBatchItem(taskStatus: "failed", itemStatus: "succeeded"))
        print("Morde host navigation and action busy checks passed")
    }
}

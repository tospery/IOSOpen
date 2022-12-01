import SwiftUI

@main
struct ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                List {
                    NavigationLink("Default", destination: DefaultView())
                    NavigationLink("Change selected index", destination: SelectedIndexView())
                    NavigationLink("Lifecycle events", destination: LifecycleView())
                    NavigationLink("Change items", destination: ChangeItemsView())
                }
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

import Parchment
import SwiftUI
import UIKit

struct SelectedIndexView: View {
    var items = [
        PagingIndexItem(index: 0, title: "View 0"),
        PagingIndexItem(index: 1, title: "View 1"),
        PagingIndexItem(index: 2, title: "View 2"),
        PagingIndexItem(index: 3, title: "View 3"),
    ]
    @State var selectedIndex: Int = 2

    var body: some View {
        PageView(items: items, selectedIndex: $selectedIndex) { item in
            Text(item.title)
                .font(.largeTitle)
                .foregroundColor(.gray)
                .onTapGesture {
                    selectedIndex = 0
                }
        }
    }
}

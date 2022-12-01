import Parchment
import SwiftUI
import UIKit

struct LifecycleView: View {
    let items = [
        PagingIndexItem(index: 0, title: "View 0"),
        PagingIndexItem(index: 1, title: "View 1"),
        PagingIndexItem(index: 2, title: "View 2"),
        PagingIndexItem(index: 3, title: "View 3"),
    ]

    var body: some View {
        PageView(items: items) { item in
            Text(item.title)
                .font(.largeTitle)
                .foregroundColor(.gray)
        }
        .willScroll { pagingItem in
            print("will scroll: ", pagingItem)
        }
        .didScroll { pagingItem in
            print("did scroll: ", pagingItem)
        }
        .didSelect { pagingItem in
            print("did select: ", pagingItem)
        }
    }
}

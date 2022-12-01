import Foundation
@testable import Parchment

final class MockPagingControllerSizeDelegate: PagingControllerSizeDelegate {
    var pagingItemWidth: (() -> CGFloat?)?

    func width(for _: PagingItem, isSelected _: Bool) -> CGFloat {
        return pagingItemWidth?() ?? 0
    }
}

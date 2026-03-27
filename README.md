# InAppKit

**InAppKit** là một framework iOS giúp tích hợp StoreKit 2 một cách nhanh chóng và an toàn. Framework cung cấp API rõ ràng theo mô hình **Permission-centric** — thay vì quản lý từng product ID rời rạc, bạn map các sản phẩm vào các *quyền* (permission) của ứng dụng, rồi kiểm tra quyền đó để mở/khoá tính năng.

---

## Yêu cầu môi trường

| Mục             | Yêu cầu tối thiểu |
|-----------------|-------------------|
| iOS             | 15.0+             |
| Swift           | 5.9+              |
| Xcode           | 15.0+             |
| StoreKit        | 2 (tích hợp sẵn)  |
| Combine         | Tích hợp sẵn      |

---

## Cài đặt — Swift Package Manager

### Thêm package vào Xcode

1. Mở Xcode → chọn project của bạn → **Package Dependencies** → nhấn **"+"**
2. Nhập URL của SPM repo:

```
https://github.com/trinhxuanminh/InAppKit-SPM
```

3. Chọn phiên bản (Exact Version) → **Add Package**
4. Thêm `InAppKit` vào target của bạn → **Add Package**

### Hoặc thêm vào `Package.swift`

```swift
dependencies: [
    .package(url: "https://github.com/trinhxuanminh/InAppKit-SPM", from: "1.0.0")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: ["InAppKit"]
    )
]
```

---



## Hướng dẫn sử dụng

### Bước 1 — Khai báo sản phẩm

Tạo một `enum` conform `BaseProduct` để đại diện cho các sản phẩm trong App Store Connect.

```swift
import InAppKit

enum AppProduct: CaseIterable, BaseProduct {
    // Auto-renewable subscriptions
    case weekly
    case monthly
    case yearly
    // Non-consumable
    case lifetime
    // Non-renewable subscription
    case proMonthly
    // Consumable (vật phẩm tiêu hao)
    case coins5
    case coins25
    case coins100

    var id: String {
        switch self {
        case .weekly:    return "com.yourapp.weekly"
        case .monthly:   return "com.yourapp.monthly"
        case .yearly:    return "com.yourapp.yearly"
        case .lifetime:  return "com.yourapp.lifetime"
        case .proMonthly: return "com.yourapp.pro.monthly"
        case .coins5:    return "com.yourapp.coins.5"
        case .coins25:   return "com.yourapp.coins.25"
        case .coins100:  return "com.yourapp.coins.100"
        }
    }

    // Chỉ cần khai báo với sản phẩm Non-Renewable. Các loại khác để nil.
    var nonRenewableDuration: Duration? {
        switch self {
        case .proMonthly: return .months(1)
        default:          return nil
        }
    }

    // Tuỳ chọn: config giá trị mặc định khi người dùng mua sản phẩm này.
    // Các gói renew (subscription) không tặng quà, chỉ consumable mới có.
    var metadata: [String: Any]? {
        switch self {
        case .coins5:   return ["coins": 5]
        case .coins25:  return ["coins": 25]
        case .coins100: return ["coins": 100]
        default:        return nil
        }
    }
}
```

---

### Bước 2 — Khai báo quyền (Permission)

Mỗi `Permission` đại diện cho một tính năng của ứng dụng. Một permission có thể được mở khoá bởi nhiều sản phẩm khác nhau.

```swift
import InAppKit

enum AppPermission: String, CaseIterable, BasePermission {
    case premium

    var id: String { rawValue }

    // Danh sách sản phẩm nào mở khoá quyền này
    var products: [BaseProduct] {
        switch self {
        case .premium:
            return [AppProduct.weekly, .monthly, .yearly, .lifetime, .proMonthly]
        }
    }
}
```

---

### Bước 3 — Cấu hình `InAppService`

- Khởi tạo **một lần duy nhất** khi ứng dụng khởi động (trong `AppDelegate` hoặc `@main` struct).
- Gọi `PermissionManager.shared.sync()` ngay sau để bắt đầu lắng nghe permissions.
- `isReady` dùng riêng để biết khi nào register ads / hiển thị UI.

```swift
import UIKit
import InAppKit
import Combine

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var cancellables = Set<AnyCancellable>()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        InAppService.configureShared(
            products: AppProduct.allCases,
            permissions: AppPermission.allCases,
            permissionTimeout: 10
        )

        PermissionManager.shared.sync()

        InAppService.shared.isReady
            .filter { $0 }
            .prefix(1)
            .sink { _ in
                // Launch / Register Ads
            }
            .store(in: &cancellables)

        return true
    }
}
```

---

### Lấy thông tin sản phẩm (`retrieveInfo`)

```swift
// Lấy 1 sản phẩm
Task {
    do {
        let info = try await InAppService.shared.retrieveInfo(AppProduct.monthly)
        print(info.displayName)     // "Monthly Premium"
        print(info.displayPrice)    // "$4.99"
        print(info.price)           // 4.99 (Decimal)
        
        // Thông tin subscription (chỉ có với auto-renewable)
        if let sub = info.subscriptionInfo {
            print(sub.period)       // Product.SubscriptionPeriod
            print(sub.offerInfos)   // [OfferInfo] — intro, promo, win-back
        }
    } catch {
        print("Error:", error)
    }
}

// Lấy nhiều sản phẩm cùng lúc (có cache tự động)
Task {
    let infos = try await InAppService.shared.retrieveInfo([
        AppProduct.monthly,
        AppProduct.yearly
    ])
}
```

> **Lưu ý:** Kết quả được cache tự động trong `productInfos`. Lần gọi tiếp theo sẽ trả về ngay mà không gọi StoreKit.

---

### Mua sản phẩm (`purchase`)

```swift
Task {
    do {
        let productInfo = try await InAppService.shared.purchase(AppProduct.monthly)
        print("Mua thành công:", productInfo.displayName)
        // permissions sẽ tự động được cập nhật
    } catch InAppError.userCancelled {
        print("Người dùng huỷ")
    } catch InAppError.pending {
        print("Giao dịch đang chờ duyệt (Ask to Buy)")
    } catch InAppError.productNotExist {
        print("Sản phẩm không tồn tại trên App Store Connect")
    } catch {
        print("Lỗi:", error)
    }
}
```

Theo dõi trạng thái đang xử lý giao dịch:

```swift
InAppService.shared.isPurchasing
    .sink { isPurchasing in
        loadingButton.isEnabled = !isPurchasing
    }
    .store(in: &cancellables)
```

---

### Kiểm tra quyền — Tích hợp với `PermissionManager` (khuyến nghị)

`permissions` là một `CurrentValueSubject` phát danh sách quyền hiện tại. Trong thực tế, nên tạo một lớp trung gian `PermissionManager` để bridge `InAppService` với phần còn lại của app, chuyển đổi sang các flag `@Published` đơn giản cho UI dùng.

```swift
import Foundation
import Combine
import InAppKit

class PermissionManager {
    static let shared = PermissionManager()

    @Published private(set) var isPremium = false
    private var subscriptions: Set<AnyCancellable> = []
}

extension PermissionManager {
    /// Gọi khi khởi động app để bắt đầu lắng nghe permissions.
    func sync() {
        InAppService.shared.permissions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] permissions in
                guard let self else { return }
                unlock(permissions: permissions)
            }
            .store(in: &subscriptions)
    }

    /// Xử lý phần thưởng khi mua consumable (ví dụ: cộng coin từ metadata).
    func consumable(product: BaseProduct) {
        if let coins = product.metadata?["coins"] as? Int {
            CoinManager.shared.add(coins)
        }
        // Thêm các loại phần thưởng khác tại đây
    }
}

extension PermissionManager {
    private func unlock(permissions: [PermissionInfo]) {
        for permission in permissions {
            switch permission.originalPermission as! AppPermission {
            case .premium:
                isPremium = true
            }
        }
    }
}
```

Sau mỗi lần mua **consumable**, gọi thêm để xử lý phần thưởng:

```swift
let productInfo = try await InAppService.shared.purchase(AppProduct.coins25)
PermissionManager.shared.consumable(product: productInfo.product)
```

---

### Khôi phục giao dịch (`restore`)

```swift
Task {
    await InAppService.shared.restore()
    // permissions sẽ được cập nhật sau khi restore xong
}
```

---

### Kiểm tra tính đủ điều kiện nhận offer (`checkEligibility`)

```swift
Task {
    // Lấy offerInfos từ productInfo
    let productInfo = try await InAppService.shared.retrieveInfo(AppProduct.monthly)
    
    guard let introOffer = productInfo.subscriptionInfo?.offerInfos.first(where: { $0.type == .introductory }) else {
        return
    }
    
    let eligibility = await InAppService.shared.checkEligibility(for: introOffer)
    
    switch eligibility {
    case .eligible:
        showIntroOfferBadge()
    case .ineligible:
        hideIntroOfferBadge()
    case .unknown:
        break
    }
}
```

---

### Xem lịch sử giao dịch (`history`)

```swift
// Lấy tất cả lịch sử
Task {
    let all = await InAppService.shared.history()
}

// Chỉ lấy giao dịch còn hiệu lực
Task {
    let active = await InAppService.shared.history(filter: .active)
}

// Tuỳ chỉnh filter
Task {
    let filter = HistoryFilter(includeRevoked: false, includeExpired: true)
    let history = await InAppService.shared.history(filter: filter)
    
    for tx in history {
        print(tx.product.id, tx.purchaseDate, tx.expiration, tx.isRefunded)
    }
}
```

---

### Yêu cầu hoàn tiền (`requestRefund`)

```swift
@MainActor
func requestRefund(for transaction: TransactionInfo, scene: UIWindowScene) async {
    do {
        try await InAppService.shared.requestRefund(for: transaction, in: scene)
        print("Sheet hoàn tiền đã hiển thị")
    } catch InAppError.userCancelled {
        print("Người dùng đóng sheet")
    } catch InAppError.duplicateRequest {
        print("Đã gửi yêu cầu hoàn tiền trước đó")
    } catch {
        print("Lỗi:", error)
    }
}
```

---

## Tham khảo API

### `InAppServiceType` — Protocol

| Thuộc tính / Phương thức | Mô tả |
|--------------------------|-------|
| `permissions` | `CurrentValueSubject<[PermissionInfo], Never>` — danh sách quyền hiện tại |
| `isPurchasing` | `CurrentValueSubject<Bool, Never>` — `true` khi đang xử lý giao dịch |
| `productInfos` | `CurrentValueSubject<[String: ProductInfo], Never>` — cache thông tin sản phẩm |
| `isReady` | `CurrentValueSubject<Bool, Never>` — `true` khi bước init permission hoàn tất |
| `retrieveInfo(_:)` | Lấy thông tin 1 sản phẩm (có cache) |
| `retrieveInfo(_:)` | Lấy thông tin nhiều sản phẩm (có cache) |
| `checkEligibility(for:)` | Kiểm tra điều kiện nhận offer |
| `history(filter:)` | Lấy lịch sử giao dịch |
| `purchase(_:)` | Thực hiện mua sản phẩm |
| `restore()` | Khôi phục giao dịch đã mua |
| `requestRefund(for:in:)` | Mở sheet yêu cầu hoàn tiền (MainActor) |

### `InAppError`

| Case | Ý nghĩa |
|------|---------|
| `userCancelled` | Người dùng huỷ giao dịch / sheet |
| `pending` | Giao dịch đang chờ duyệt (Ask to Buy) |
| `productNotExist` | Product ID không tồn tại trên App Store Connect |
| `unverified` | StoreKit không xác minh được giao dịch |
| `duplicateRequest` | Gửi yêu cầu hoàn tiền trùng lặp |
| `unknown` | Lỗi không xác định |

### `Expiration`

| Case | Ý nghĩa |
|------|---------|
| `.lifetime` | Không bao giờ hết hạn (non-consumable) |
| `.expires(on: Date)` | Có ngày hết hạn cụ thể |
| `.unknown` | Không xác định được |

### `HistoryFilter`

| Preset | Ý nghĩa |
|--------|---------|
| `.all` | Toàn bộ lịch sử |
| `.active` | Chỉ giao dịch còn hiệu lực (chưa refund, chưa hết hạn) |

---

## Lưu ý đặc biệt

### ⚠️ Phải gọi `configureShared` trước khi dùng `shared`

Truy cập `InAppService.shared` trước khi gọi `configureShared(...)` sẽ gây `fatalError`. Hãy cấu hình tại điểm khởi động ứng dụng.

### ⚠️ Non-Renewable Subscription bắt buộc khai báo `nonRenewableDuration`

Đây là loại sản phẩm mà StoreKit 2 **không** tự theo dõi thời hạn. InAppKit sử dụng `nonRenewableDuration` để tính ngày hết hạn từ `purchaseDate`. Nếu không khai báo, ứng dụng sẽ `assertionFailure` ở môi trường Debug.

```swift
// ✅ Đúng
case .proMonthly: return .months(1)

// ❌ Sai — sẽ crash ở DEBUG
case .proMonthly: return nil
```

### ⚠️ `isReady` cần được chờ trước khi hiển thị paywall

Ngay sau khi `InAppService` được khởi tạo, nó bắt đầu kiểm tra quyền bất đồng bộ. `permissions.value` sẽ là `[]` cho đến khi `isReady` phát `true`. Nếu bỏ qua bước này, paywall sẽ nghĩ người dùng chưa mua gì trong khi thực tế đã mua.

### ℹ️ Tự động theo dõi giao dịch hậu cảnh

InAppService lắng nghe `Transaction.updates` liên tục để xử lý các trường hợp:
- Giao dịch được hoàn tất từ một thiết bị khác
- Ask-to-Buy được chấp thuận
- Subscription được gia hạn hoặc bị thu hồi

`permissions` sẽ tự động cập nhật mà không cần thêm code.

### ℹ️ Vòng lặp kiểm tra hết hạn (Expiry Check Loop)

Cứ **30 giây**, InAppKit quét danh sách permission hiện tại. Nếu phát hiện có permission đã hết hạn, nó sẽ gọi lại `updatePermissions()` để đảm bảo trạng thái luôn chính xác khi người dùng không rời khỏi ứng dụng. Vòng lặp này tự động dừng khi ứng dụng vào nền và tiếp tục khi ứng dụng hoạt động trở lại.

### ℹ️ `checkEligibility` yêu cầu iOS 17.2+ cho Promotional & Win-Back Offers

Với **Introductory Offer**, framework hỗ trợ từ iOS 15. Với **Promotional** và **Win-Back Offers**, cần iOS 17.2+ để kiểm tra chính xác. Trên các phiên bản cũ hơn, hàm trả về `.unknown`.

### ℹ️ Logging chỉ hoạt động ở DEBUG build

Tất cả log nội bộ của InAppKit chỉ in ra ở **DEBUG** configuration với prefix `[InAppKit]`. Không có log nào rò rỉ ra production build.

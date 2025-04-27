# Hướng dẫn Xác thực trong ShopLite

Tài liệu này mô tả cách triển khai logic xác thực trong ứng dụng ShopLite, cho phép người dùng chưa đăng nhập xem sản phẩm nhưng yêu cầu đăng nhập cho các chức năng khác.

## Tổng quan

Hệ thống xác thực của chúng ta được thiết kế với các nguyên tắc sau:

1. Người dùng chưa đăng nhập có thể duyệt và xem sản phẩm
2. Các chức năng khác (giỏ hàng, mua hàng, yêu thích, bình luận) yêu cầu đăng nhập
3. Khi người dùng cố gắng truy cập chức năng cần xác thực, họ sẽ được nhắc đăng nhập
4. Trải nghiệm người dùng mượt mà với thông báo phù hợp

## Widget có sẵn

Chúng tôi cung cấp các widget bọc (wrapper) để dễ dàng thực hiện việc kiểm tra xác thực:

### 1. AuthRequiredWrapper

Bọc nội dung cần xác thực và tự động hiển thị nội dung thay thế nếu chưa đăng nhập.

```dart
AuthRequiredWrapper(
  featureDescription: 'bình luận và đánh giá sản phẩm',
  child: YourProtectedWidget(),
  // Tùy chọn: Cung cấp nội dung thay thế
  alternativeContent: CustomNotLoggedInWidget(),
)
```

### 2. AuthRequiredButton

Button có sẵn kiểm tra xác thực khi được nhấp vào.

```dart
AuthRequiredButton(
  featureDescription: 'thêm sản phẩm vào giỏ hàng',
  onAuthenticated: () {
    // Code chỉ chạy khi đã đăng nhập
    addToCart(productId);
  },
  child: Text('Thêm vào giỏ hàng'),
)
```

### 3. AuthRequiredIconButton

IconButton có sẵn kiểm tra xác thực khi được nhấp vào.

```dart
AuthRequiredIconButton(
  icon: Icons.favorite_border,
  color: Colors.red,
  featureDescription: 'thêm vào danh sách yêu thích',
  onAuthenticated: () {
    // Code chỉ chạy khi đã đăng nhập
    toggleFavorite(productId);
  },
)
```

## Sử dụng programmatically

Nếu bạn cần kiểm tra xác thực trong mã, sử dụng phương thức `handleProtectedFeature` từ `authStateProvider`:

```dart
final canProceed = await ref.read(authStateProvider.notifier).handleProtectedFeature(
  context,
  featureDescription: 'thanh toán đơn hàng',
);

if (canProceed) {
  // Người dùng đã đăng nhập, tiến hành thao tác
  proceedToCheckout();
}
```

## Lưu ý về trải nghiệm người dùng

1. Sử dụng `featureDescription` rõ ràng để cho người dùng biết họ đang cố làm gì
2. Các thông báo nên ngắn gọn và hữu ích
3. Cung cấp nội dung thay thế có ý nghĩa khi có thể
4. Thống nhất trong toàn bộ ứng dụng

## Ví dụ thực tế

### Giỏ hàng

```dart
ElevatedButton(
  onPressed: () async {
    final canProceed = await ref.read(authStateProvider.notifier).handleProtectedFeature(
      context,
      featureDescription: 'xem giỏ hàng',
    );
    
    if (canProceed) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => CartScreen()));
    }
  },
  child: Text('Xem giỏ hàng'),
)
```

### Bình luận

```dart
AuthRequiredWrapper(
  featureDescription: 'bình luận về sản phẩm',
  child: CommentForm(productId: product.id),
)
```

### Yêu thích

```dart
AuthRequiredIconButton(
  icon: isInWishlist ? Icons.favorite : Icons.favorite_border,
  color: Colors.red,
  featureDescription: 'thêm sản phẩm vào yêu thích',
  onAuthenticated: () => toggleWishlist(product.id),
)
``` 
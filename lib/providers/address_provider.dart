import 'package:flutter/material.dart';
import '../repositories/address_repository.dart';
import 'package:shoplite/models/Address.dart';

class AddressProvider extends ChangeNotifier {
  final AddressRepository _addressRepository = AddressRepository();

  List<Address> _addressList = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Address> get addressList => _addressList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Cập nhật trạng thái loading
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Cập nhật thông báo lỗi
  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Lấy danh sách AddressBook
  Future<void> fetchAddressBook(String token) async {
    _setLoading(true);
    _setError(null);

    try {
      print("📩 Đang tải danh sách AddressBook với token...");
      _addressList = await _addressRepository.getAddressBook(token);

      if (_addressList.isEmpty) {
        print("⚠️ AddressBook trống.");
      } else {
        print("✅ Danh sách AddressBook đã tải thành công: ${_addressList.map((item) => item.fullName).toList()}");
      }
    } catch (e) {
      _setError("❌ Không thể tải danh sách AddressBook: ${e.toString()}");
      print("❌ Lỗi khi tải danh sách AddressBook: ${e.toString()}");
    } finally {
      _setLoading(false);
    }
  }

  // Thêm địa chỉ mới vào AddressBook
  Future<void> addAddress(String token, Address address) async {
    _setLoading(true);
    _setError(null);

    try {
      print("📥 Đang thêm địa chỉ mới vào AddressBook: ${address.fullName}...");
      await _addressRepository.addAddress(token, address);
      print("✅ Thêm địa chỉ mới thành công!");

      // Cập nhật lại danh sách AddressBook sau khi thêm
      await fetchAddressBook(token);
    } catch (e) {
      _setError("❌ Không thể thêm địa chỉ mới: ${e.toString()}");
      print("❌ Lỗi khi thêm địa chỉ mới: ${e.toString()}");
    } finally {
      _setLoading(false);
    }
  }

  // Xóa địa chỉ khỏi AddressBook
  Future<void> deleteAddress(String token, int addressId) async {
    _setLoading(true);
    _setError(null);

    try {
      print("🗑️ Đang xóa địa chỉ khỏi AddressBook: Address ID $addressId...");
      await _addressRepository.deleteAddress(token, addressId);
      print("✅ Xóa địa chỉ thành công!");

      // Cập nhật lại danh sách AddressBook sau khi xóa
      await fetchAddressBook(token);
    } catch (e) {
      _setError("❌ Không thể xóa địa chỉ: ${e.toString()}");
      print("❌ Lỗi khi xóa địa chỉ: ${e.toString()}");
    } finally {
      _setLoading(false);
    }
  }

  // Kiểm tra nếu AddressBook trống
  bool isAddressBookEmpty() {
    return _addressList.isEmpty;
  }

  // Log danh sách AddressBook để debug
  void logAddressBook() {
    print("📜 Danh sách địa chỉ trong AddressBook:");
    if (_addressList.isEmpty) {
      print("⚠️ Không có địa chỉ nào trong AddressBook.");
    } else {
      for (var address in _addressList) {
        print("- ${address.fullName}, 📞 ${address.phone}, 🏠 ${address.address}");
      }
    }
  }
}

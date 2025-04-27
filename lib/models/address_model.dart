// ignore: file_names
class AddressModel {
  int? id;
  String? location;
  String? name;
  String? phoneNumber;
  String? type;
  final String street;
  final String city;
  final String state;
  final String zipCode;

  AddressModel({
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
  });

  String get fullAddress {
    return '$street, $city, $state $zipCode';
  }
}

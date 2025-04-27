class ModelCart {
  int? id;
  String? title;
  String? subTitle;
  String? image;
  String? price;
  String? quantity;
  String? token; // Thêm trường token để xác định người dùng

  ModelCart(
      this.id, this.title, this.subTitle, this.image, this.price, this.quantity, this.token);
}

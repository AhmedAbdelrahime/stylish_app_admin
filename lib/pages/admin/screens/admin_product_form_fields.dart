// ignore_for_file: invalid_use_of_protected_member

part of 'admin_product_screen.dart';

extension _AdminProductFormFields on _AdminProductViewState {
  Widget _buildNumberRow() {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(
            controller: _priceController,
            label: 'Original price',
            hintText: 'Optional',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTextField(
            controller: _salePriceController,
            label: 'Current price',
            hintText: 'Required',
            validator: _requiredValidator,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTextField(
            controller: _ratingController,
            label: 'Rating',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryRow() {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(
            controller: _stockController,
            label: 'Stock quantity',
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTextField(
            controller: _lowStockController,
            label: 'Low stock threshold',
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: _inputDecoration(label, hintText: hintText),
    );
  }

  InputDecoration _inputDecoration(String label, {String? hintText}) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      filled: true,
      fillColor: AppColors.primaryColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.redColor, width: 1.4),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }
}

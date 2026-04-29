// ignore_for_file: invalid_use_of_protected_member

part of 'admin_product_screen.dart';

extension _AdminProductComposerSection on _AdminProductViewState {
  Widget _buildComposerCard(AdminProductState productState) {
    return AdminSurfaceCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionIntro(
            title: _editingProduct == null ? 'Create Product' : 'Edit Product',
            subtitle:
                'Manage core catalog details, current pricing, inventory, status, and uploaded imagery from one admin form.',
          ),
          const SizedBox(height: 22),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'Product name',
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _titleController,
                  label: 'Short title',
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 14),
                _buildNumberRow(),
                const SizedBox(height: 14),
                _buildInventoryRow(),
                const SizedBox(height: 14),
                _buildTextField(controller: _skuController, label: 'SKU'),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _sizesController,
                  label: 'Sizes',
                  hintText: '38,39,40,41',
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId,
                  decoration: _inputDecoration('Category'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Uncategorized'),
                    ),
                    ...productState.categories.map(
                      (category) => DropdownMenuItem<String>(
                        value: category.id,
                        child: Text(category.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedCategoryId = value);
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
                  decoration: _inputDecoration('Status'),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'draft', child: Text('Draft')),
                    DropdownMenuItem(value: 'hidden', child: Text('Hidden')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedStatus = value);
                    }
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _isFeatured,
                  onChanged: (value) => setState(() => _isFeatured = value),
                  title: const Text('Featured product'),
                  subtitle: const Text(
                    'Highlight this product in curated storefront sections.',
                  ),
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _mainImageUrlController,
                  label: 'Main image URL',
                  hintText: 'Optional fallback URL',
                ),
                const SizedBox(height: 14),
                _ProductImageUploadCard(
                  bytes: _selectedImageBytes,
                  fileName:
                      _selectedImage?.name ?? _editingProduct?.mainImageUrl,
                  isPickingImage: _isPickingImage,
                  onPickImage: _pickImage,
                  title: 'Upload main product image',
                  description:
                      'Use upload for the hero image, or keep a direct image URL above as a fallback.',
                  onRemoveImage: () {
                    setState(() {
                      _selectedImage = null;
                      _selectedImageBytes = null;
                    });
                  },
                ),
                const SizedBox(height: 14),
                _ProductGalleryUploadCard(
                  existingUrls: _galleryImageUrls,
                  selectedBytes: _selectedGalleryImageBytes,
                  selectedNames: _selectedGalleryImages
                      .map((image) => image.name)
                      .toList(growable: false),
                  isPickingImages: _isPickingImage,
                  onPickImages: _pickGalleryImages,
                  onRemoveExisting: (index) {
                    setState(() => _galleryImageUrls.removeAt(index));
                  },
                  onRemoveSelected: (index) {
                    setState(() {
                      _selectedGalleryImages.removeAt(index);
                      _selectedGalleryImageBytes.removeAt(index);
                    });
                  },
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  maxLines: 4,
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: (productState.isSaving || productState.isDeleting)
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.redColor,
                              ),
                            )
                          : FilledButton(
                              onPressed: _saveProduct,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.redColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                _editingProduct == null
                                    ? 'Create Product'
                                    : 'Save Changes',
                              ),
                            ),
                    ),
                    if (_editingProduct != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _resetForm,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

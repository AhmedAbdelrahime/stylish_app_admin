// ignore_for_file: invalid_use_of_protected_member

part of 'admin_category_screen.dart';

extension _AdminCategoryScreenSections on _AdminCategoryScreenState {
  Widget _buildComposerCard() {
    return AdminSurfaceCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionIntro(
            title: _editingCategory == null
                ? 'Create Category'
                : 'Edit Category',
            subtitle:
                'Built for desktop admin work. Add a category name, then either upload artwork or paste a trusted image URL for the storefront card.',
          ),
          const SizedBox(height: 22),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel(text: 'Category Name'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Category name is required';
                    }
                    return null;
                  },
                  decoration: _inputDecoration(
                    hintText: 'Example: New Arrivals',
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _sortOrderController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(
                          hintText: 'Sort order',
                        ).copyWith(labelText: 'Sort Order'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _isVisible,
                        onChanged: (value) =>
                            setState(() => _isVisible = value),
                        title: const Text('Visible'),
                        subtitle: Text(
                          _isVisible
                              ? 'Shown in storefront'
                              : 'Hidden from storefront',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: _inputDecoration(
                    hintText: 'Optional image URL',
                  ).copyWith(labelText: 'Image URL'),
                ),
                const SizedBox(height: 18),
                const _SectionLabel(text: 'Category Image'),
                const SizedBox(height: 10),
                _ImageUploadCard(
                  bytes: _selectedImageBytes,
                  fileName: _selectedImage?.name ?? _editingCategory?.imageUrl,
                  isPickingImage: _isPickingImage,
                  onPickImage: _pickImage,
                  onRemoveImage: () {
                    setState(() {
                      _selectedImage = null;
                      _selectedImageBytes = null;
                    });
                  },
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: (_isSaving || _isDeleting)
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.redColor,
                              ),
                            )
                          : FilledButton(
                              onPressed: _saveCategory,
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
                                _editingCategory == null
                                    ? 'Publish Category'
                                    : 'Save Changes',
                              ),
                            ),
                    ),
                    if (_editingCategory != null) ...[
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
                if (_saveStatusMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.redColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _saveStatusMessage!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.blackColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard() {
    return const AdminSurfaceCard(
      backgroundColor: AppColors.blackColor,
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminTag(
            label: 'Web Workflow',
            backgroundColor: Color(0x1AFFFFFF),
            foregroundColor: Colors.white,
          ),
          SizedBox(height: 18),
          Text(
            'Use wide visuals, strong names, and one clean image per category.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          SizedBox(height: 18),
          _GuidePoint(
            title: 'Use horizontal-friendly artwork',
            description:
                'Choose images that still read well in desktop cards and grids.',
          ),
          SizedBox(height: 14),
          _GuidePoint(
            title: 'Keep names short',
            description:
                'Strong names like Bags, Shoes, and Electronics scan faster.',
          ),
          SizedBox(height: 14),
          _GuidePoint(
            title: 'Use upload or URL',
            description:
                'You can now upload artwork directly or paste a trusted CDN image URL when your team already hosts category art.',
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryHeader() {
    return AdminSectionIntro(
      title: 'Category Library',
      subtitle:
          'Search categories, control storefront visibility, and tune the sort order from one compact admin view.',
      trailing: SizedBox(
        width: 260,
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search categories',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid({required bool isWide}) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _filteredCategories.map((category) {
        return SizedBox(
          width: isWide ? 260 : double.infinity,
          child: _CategoryCard(
            category: category,
            linkedProductsCount: _linkedProductsCount(category.id),
            onEdit: () => _startEditing(category),
            onDelete: () => _deleteCategory(category),
            onToggleVisibility: () => _toggleCategoryVisibility(category),
            onMoveUp: () => _moveCategorySort(category, -1),
            onMoveDown: () => _moveCategorySort(category, 1),
          ),
        );
      }).toList(),
    );
  }

  InputDecoration _inputDecoration({required String hintText}) {
    return InputDecoration(
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
}

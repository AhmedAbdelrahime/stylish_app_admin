// ignore_for_file: invalid_use_of_protected_member

part of 'admin_product_screen.dart';

extension _AdminProductLibrarySection on _AdminProductViewState {
  Widget _buildLibraryCard(AdminProductState productState) {
    final filteredProducts = _filterProducts(productState.products);

    return AdminSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionIntro(
            title: 'Product Library',
            subtitle:
                'Search products, filter by category, and keep the catalog organized with fast edit and delete actions.',
            trailing: SizedBox(
              width: 230,
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search products',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: AppColors.primaryColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildImportSection(productState),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _categoryFilter,
            decoration: _inputDecoration('Filter by category'),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('All categories'),
              ),
              ...productState.categories.map(
                (category) => DropdownMenuItem<String>(
                  value: category.id,
                  child: Text(category.name),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _categoryFilter = value),
          ),
          const SizedBox(height: 14),
          if (filteredProducts.isNotEmpty) ...[
            _buildBulkActionBar(productState, filteredProducts),
            const SizedBox(height: 14),
          ],
          if (productState.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(color: AppColors.redColor),
              ),
            )
          else if (filteredProducts.isEmpty)
            const AdminEmptyPanel(
              icon: Icons.inventory_2_outlined,
              title: 'No products found',
              description:
                  'Create your first product or adjust the current search and filter settings.',
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredProducts.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 340,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                return _ProductCard(
                  product: product,
                  categoryName: _categoryName(
                    productState.categories,
                    product.categoryId,
                  ),
                  isSelected: productState.selectedProductIds.contains(
                    product.id,
                  ),
                  onSelectionChanged: (value) =>
                      _toggleProductSelection(product.id, value),
                  onEdit: () => _startEditing(product),
                  onDelete: () => _deleteProduct(product),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildImportSection(AdminProductState productState) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Import or download products',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blackColor,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _isExporting || productState.products.isEmpty
                    ? null
                    : _downloadAllProducts,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  side: const BorderSide(color: Colors.black12),
                ),
                icon: _isExporting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded, size: 18),
                label: Text(_isExporting ? 'Preparing...' : 'Download all'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Upload a CSV or XLSX sheet, or export the full catalog to Excel. Imports are audited before saving so missing categories and invalid rows can be reviewed safely.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: AppColors.hintColor,
            ),
          ),
          const SizedBox(height: 10),
          if (_importedFileName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AdminTag(
                label: _importedFileName!,
                backgroundColor: Colors.white,
                foregroundColor: AppColors.blackColor,
                isCompact: true,
              ),
            ),
          if (_importPreview != null) ...[
            _ProductImportPreviewCard(
              preview: _importPreview!,
              isBusy: _isImporting,
              onCreateCategories: () => _confirmSheetImport(
                AdminMissingCategoryImportStrategy.createCategories,
              ),
              onImportAsDraft: () => _confirmSheetImport(
                AdminMissingCategoryImportStrategy.importAsDraftUncategorized,
              ),
              onSkipRows: () => _confirmSheetImport(
                AdminMissingCategoryImportStrategy.skipRows,
              ),
              onCancel: _clearImportPreview,
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isImporting ? null : _pickImportSheet,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blackColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              icon: _isImporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.upload_file_outlined),
              label: Text(
                _isImporting
                    ? 'Preparing import...'
                    : _importPreview != null
                    ? 'Choose another CSV / XLSX sheet'
                    : 'Upload CSV / XLSX sheet',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActionBar(
    AdminProductState productState,
    List<ProductModel> filteredProducts,
  ) {
    final selectedCount = productState.selectedProductIds.length;
    final isBulkUpdating = productState.isBulkUpdating;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: _allFilteredSelected(
                  filteredProducts,
                  productState.selectedProductIds,
                ),
                onChanged: isBulkUpdating
                    ? null
                    : (value) => _toggleSelectAllFiltered(
                        filteredProducts,
                        value ?? false,
                      ),
              ),
              Expanded(
                child: Text(
                  selectedCount == 0
                      ? 'Select products to run bulk actions.'
                      : '$selectedCount product${selectedCount == 1 ? '' : 's'} selected.',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blackColor,
                  ),
                ),
              ),
              if (selectedCount > 0)
                TextButton(
                  onPressed: isBulkUpdating ? null : _clearSelectedProducts,
                  child: const Text('Clear'),
                ),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: selectedCount == 0 || isBulkUpdating
                    ? null
                    : () => _bulkUpdateSelectedProducts(
                        status: 'active',
                        successMessage: 'Selected products are now active.',
                      ),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Activate'),
              ),
              OutlinedButton.icon(
                onPressed: selectedCount == 0 || isBulkUpdating
                    ? null
                    : () => _bulkUpdateSelectedProducts(
                        status: 'hidden',
                        successMessage: 'Selected products are now hidden.',
                      ),
                icon: const Icon(Icons.visibility_off_outlined, size: 18),
                label: const Text('Hide'),
              ),
              OutlinedButton.icon(
                onPressed: selectedCount == 0 || isBulkUpdating
                    ? null
                    : () => _bulkUpdateSelectedProducts(
                        featured: true,
                        successMessage: 'Selected products are now featured.',
                      ),
                icon: const Icon(Icons.star_outline_rounded, size: 18),
                label: const Text('Feature'),
              ),
              OutlinedButton.icon(
                onPressed: selectedCount == 0 || isBulkUpdating
                    ? null
                    : () => _bulkUpdateSelectedProducts(
                        featured: false,
                        successMessage:
                            'Selected products were removed from featured.',
                      ),
                icon: const Icon(Icons.star_border_rounded, size: 18),
                label: const Text('Unfeature'),
              ),
              OutlinedButton.icon(
                onPressed: selectedCount == 0 || isBulkUpdating
                    ? null
                    : _deleteSelectedProducts,
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                icon: isBulkUpdating
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

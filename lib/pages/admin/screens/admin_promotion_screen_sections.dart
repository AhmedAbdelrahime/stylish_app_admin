// ignore_for_file: invalid_use_of_protected_member

part of 'admin_promotion_screen.dart';

extension _AdminPromotionScreenSections on _AdminPromotionScreenState {
  Widget _buildSearchHeader() {
    return AdminSectionIntro(
      title: 'Promotions Library',
      subtitle:
          'Manage coupon campaigns and storefront banners from one clean admin view.',
      trailing: SizedBox(
        width: 260,
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: _inputDecoration(
            'Search promotions',
          ).copyWith(prefixIcon: const Icon(Icons.search_rounded)),
        ),
      ),
    );
  }

  Widget _buildCouponComposer() {
    return AdminSurfaceCard(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _couponFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminSectionIntro(
              title: _editingCoupon == null ? 'Create Coupon' : 'Edit Coupon',
              subtitle:
                  'Set discount rules, activation state, and order thresholds the same way most admin apps handle promo codes.',
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _couponCodeController,
              validator: _requiredValidator,
              decoration: _inputDecoration('Coupon code', hintText: 'SAVE20'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _couponDescriptionController,
              decoration: _inputDecoration('Description'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _couponType,
                    decoration: _inputDecoration('Discount type'),
                    items: const [
                      DropdownMenuItem(
                        value: 'percent',
                        child: Text('Percent'),
                      ),
                      DropdownMenuItem(value: 'fixed', child: Text('Fixed')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _couponType = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _couponDiscountValueController,
                    validator: _requiredValidator,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _inputDecoration('Discount value'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _couponMinOrderController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _inputDecoration('Minimum order'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _couponMaxDiscountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _inputDecoration('Max discount'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _couponUsageLimitController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Usage limit'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _couponActive,
              onChanged: (value) => setState(() => _couponActive = value),
              title: const Text('Coupon is active'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: (_isSavingCoupon || _isDeleting)
                        ? null
                        : _saveCoupon,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.redColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSavingCoupon
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _editingCoupon == null
                                ? 'Create Coupon'
                                : 'Save Coupon',
                          ),
                  ),
                ),
                if (_editingCoupon != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resetCouponForm,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
    );
  }

  Widget _buildBannerComposer() {
    return AdminSurfaceCard(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _bannerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminSectionIntro(
              title: _editingBanner == null ? 'Create Banner' : 'Edit Banner',
              subtitle:
                  'Control hero banners, link targets, active state, and storefront order from one professional admin form.',
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _bannerTitleController,
              validator: _requiredValidator,
              decoration: _inputDecoration('Banner title'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bannerSubtitleController,
              decoration: _inputDecoration('Subtitle'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bannerImageUrlController,
              decoration: _inputDecoration(
                'Image URL',
                hintText: 'Optional fallback URL',
              ),
            ),
            const SizedBox(height: 12),
            _PromotionImageUploadCard(
              title: 'Upload banner image',
              description:
                  'Upload the hero artwork here, or keep a direct image URL above when your media is already hosted.',
              bytes: _selectedBannerImageBytes,
              fileName: _selectedBannerImage?.name ?? _editingBanner?.imageUrl,
              isPickingImage: _isPickingBannerImage,
              onPickImage: _pickBannerImage,
              onRemoveImage: () {
                setState(() {
                  _selectedBannerImage = null;
                  _selectedBannerImageBytes = null;
                });
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _bannerTargetType,
                    decoration: _inputDecoration('Target type'),
                    items: const [
                      DropdownMenuItem(value: 'url', child: Text('URL')),
                      DropdownMenuItem(
                        value: 'product',
                        child: Text('Product'),
                      ),
                      DropdownMenuItem(
                        value: 'category',
                        child: Text('Category'),
                      ),
                      DropdownMenuItem(value: 'offer', child: Text('Offer')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _bannerTargetType = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _bannerTargetValueController,
                    decoration: _inputDecoration('Target value'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _bannerSortOrderController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Sort order'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _bannerActive,
              onChanged: (value) => setState(() => _bannerActive = value),
              title: const Text('Banner is active'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: (_isSavingBanner || _isDeleting)
                        ? null
                        : _saveBanner,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.blackColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSavingBanner
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _editingBanner == null
                                ? 'Create Banner'
                                : 'Save Banner',
                          ),
                  ),
                ),
                if (_editingBanner != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resetBannerForm,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
    );
  }

  Widget _buildOfferComposer() {
    return AdminSurfaceCard(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _offerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminSectionIntro(
              title: _editingOffer == null ? 'Create Offer' : 'Edit Offer',
              subtitle:
                  'Manage simple storefront promo cards for your home slider, with image upload first and URL as an optional fallback.',
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _offerTitleController,
              decoration: _inputDecoration('Offer title'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _offerImageUrlController,
              decoration: _inputDecoration(
                'Image URL',
                hintText: 'Optional fallback URL',
              ),
            ),
            const SizedBox(height: 12),
            _PromotionImageUploadCard(
              title: 'Upload offer image',
              description:
                  'Use upload for the main offer artwork, or keep a URL above if your media is already hosted elsewhere.',
              bytes: _selectedOfferImageBytes,
              fileName: _selectedOfferImage?.name ?? _editingOffer?.imageUrl,
              isPickingImage: _isPickingOfferImage,
              onPickImage: _pickOfferImage,
              onRemoveImage: () {
                setState(() {
                  _selectedOfferImage = null;
                  _selectedOfferImageBytes = null;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: (_isSavingOffer || _isDeleting)
                        ? null
                        : _saveOffer,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.redColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSavingOffer
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _editingOffer == null
                                ? 'Create Offer'
                                : 'Save Offer',
                          ),
                  ),
                ),
                if (_editingOffer != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resetOfferForm,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
    );
  }

  Widget _buildCouponSection() {
    return AdminSurfaceCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionIntro(
            title: 'Coupon Library',
            subtitle:
                'Monitor active codes, order thresholds, and usage so campaigns stay clean and support can scan them quickly.',
          ),
          const SizedBox(height: 16),
          if (_filteredCoupons.isEmpty)
            const AdminEmptyPanel(
              icon: Icons.sell_outlined,
              title: 'No coupons yet',
              description:
                  'Create your first coupon to start discount campaigns and checkout promotions.',
            )
          else
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: _filteredCoupons.map((coupon) {
                return SizedBox(
                  width: 320,
                  child: _CouponCard(
                    coupon: coupon,
                    onEdit: () => _startEditingCoupon(coupon),
                    onDelete: () => _deleteCoupon(coupon),
                    onToggle: () => _toggleCoupon(coupon),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildBannerSection() {
    return AdminSurfaceCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionIntro(
            title: 'Banner Library',
            subtitle:
                'Keep storefront banners ordered, active, and linked to the right destinations.',
          ),
          const SizedBox(height: 16),
          if (_filteredBanners.isEmpty)
            const AdminEmptyPanel(
              icon: Icons.photo_size_select_actual_outlined,
              title: 'No banners yet',
              description:
                  'Create your first hero banner to control the top of the storefront.',
            )
          else
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: _filteredBanners.map((banner) {
                return SizedBox(
                  width: 360,
                  child: _BannerCard(
                    banner: banner,
                    onEdit: () => _startEditingBanner(banner),
                    onDelete: () => _deleteBanner(banner),
                    onMoveUp: () => _moveBanner(banner, -1),
                    onMoveDown: () => _moveBanner(banner, 1),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildOfferSection() {
    return AdminSurfaceCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionIntro(
            title: 'Offer Library',
            subtitle:
                'Keep simple storefront offer cards updated for the home slider and other lightweight promo surfaces.',
          ),
          const SizedBox(height: 16),
          if (_filteredOffers.isEmpty)
            const AdminEmptyPanel(
              icon: Icons.local_offer_outlined,
              title: 'No offers yet',
              description:
                  'Create your first offer card to feed the storefront slider with simple visual promotions.',
            )
          else
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: _filteredOffers.map((offer) {
                return SizedBox(
                  width: 320,
                  child: _OfferCard(
                    offer: offer,
                    onEdit: () => _startEditingOffer(offer),
                    onDelete: () => _deleteOffer(offer),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

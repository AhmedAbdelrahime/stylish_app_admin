// ignore_for_file: invalid_use_of_protected_member

part of 'admin_order_screen.dart';

extension _AdminOrderExportActions on _AdminOrderViewState {
  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _fromDate = picked;
      if (_toDate != null && _toDate!.isBefore(picked)) {
        _toDate = picked;
      }
    });
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? _fromDate ?? DateTime.now(),
      firstDate: _fromDate ?? DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() => _toDate = picked);
  }

  void _clearDateRange() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
  }

  Future<void> _exportFilteredOrders(
    List<AdminOrderModel> filteredOrders,
  ) async {
    if (filteredOrders.isEmpty || _isExporting) return;
    setState(() => _isExporting = true);
    try {
      final workbook = excel.Excel.createExcel();
      final ordersSheet = workbook['Orders'];
      final itemsSheet = workbook['Order Items'];
      final defaultSheet = workbook.getDefaultSheet();
      if (defaultSheet != null &&
          defaultSheet != 'Orders' &&
          defaultSheet != 'Order Items') {
        workbook.delete(defaultSheet);
      }
      ordersSheet.appendRow([
        excel.TextCellValue('order_id'),
        excel.TextCellValue('order_code'),
        excel.TextCellValue('customer'),
        excel.TextCellValue('email'),
        excel.TextCellValue('status'),
        excel.TextCellValue('payment_status'),
        excel.TextCellValue('delivery_status'),
        excel.TextCellValue('subtotal'),
        excel.TextCellValue('shipping_fee'),
        excel.TextCellValue('discount_amount'),
        excel.TextCellValue('total_amount'),
        excel.TextCellValue('currency'),
        excel.TextCellValue('item_count'),
        excel.TextCellValue('shipping_address'),
        excel.TextCellValue('notes'),
        excel.TextCellValue('created_at'),
      ]);
      itemsSheet.appendRow([
        excel.TextCellValue('order_id'),
        excel.TextCellValue('order_code'),
        excel.TextCellValue('product_name'),
        excel.TextCellValue('product_title'),
        excel.TextCellValue('unit_price'),
        excel.TextCellValue('quantity'),
        excel.TextCellValue('selected_size'),
        excel.TextCellValue('line_total'),
      ]);
      for (final order in filteredOrders) {
        ordersSheet.appendRow([
          excel.TextCellValue(order.id),
          excel.TextCellValue(order.orderCode),
          excel.TextCellValue(order.displayCustomerName),
          excel.TextCellValue(order.user?.email ?? ''),
          excel.TextCellValue(order.status),
          excel.TextCellValue(order.paymentStatus),
          excel.TextCellValue(order.deliveryStatus),
          excel.DoubleCellValue(order.subtotal),
          excel.DoubleCellValue(order.shippingFee),
          excel.DoubleCellValue(order.discountAmount),
          excel.DoubleCellValue(order.totalAmount),
          excel.TextCellValue(order.currency),
          excel.IntCellValue(order.itemCount),
          excel.TextCellValue(order.shippingAddress ?? ''),
          excel.TextCellValue(order.notes ?? ''),
          excel.TextCellValue(order.createdAt?.toIso8601String() ?? ''),
        ]);
        for (final item in order.items) {
          itemsSheet.appendRow([
            excel.TextCellValue(order.id),
            excel.TextCellValue(order.orderCode),
            excel.TextCellValue(item.productName),
            excel.TextCellValue(item.productTitle ?? ''),
            excel.DoubleCellValue(item.unitPrice),
            excel.IntCellValue(item.quantity),
            excel.TextCellValue(item.selectedSize?.toString() ?? ''),
            excel.DoubleCellValue(item.lineTotal),
          ]);
        }
      }
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final fileName = 'orders_export_$timestamp.xlsx';
      if (kIsWeb) {
        final bytes = workbook.save(fileName: fileName);
        if (bytes == null) {
          throw 'Could not generate the Excel file.';
        }
      } else {
        final bytes = workbook.save();
        if (bytes == null || bytes.isEmpty) {
          throw 'Could not generate the Excel file.';
        }
        final savePath = await FilePicker.platform.saveFile(
          dialogTitle: 'Export orders',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: const ['xlsx'],
        );
        if (savePath == null) return;
        await File(savePath).writeAsBytes(bytes, flush: true);
      }
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        text:
            'Exported ${filteredOrders.length} order${filteredOrders.length == 1 ? '' : 's'} to Excel.',
        icon: Icons.download_done_rounded,
        backgroundColor: Colors.green,
      );
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        text: SupabaseErrorMapper.map(error),
        icon: Icons.error_outline_rounded,
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }
}

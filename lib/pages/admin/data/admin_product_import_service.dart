import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:hungry/pages/home/models/category_model.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

class AdminProductImportRow {
  const AdminProductImportRow({
    required this.name,
    required this.title,
    required this.description,
    required this.price,
    required this.salePrice,
    required this.rating,
    required this.sizes,
    required this.stockQuantity,
    required this.lowStockThreshold,
    required this.status,
    required this.featured,
    required this.categoryId,
    required this.requestedCategoryId,
    required this.requestedCategoryName,
    required this.mainImageUrl,
    required this.imageUrls,
    required this.sku,
  });

  final String name;
  final String title;
  final String description;
  final double? price;
  final double? salePrice;
  final double rating;
  final List<int> sizes;
  final int stockQuantity;
  final int lowStockThreshold;
  final String status;
  final bool featured;
  final String? categoryId;
  final String? requestedCategoryId;
  final String? requestedCategoryName;
  final String? mainImageUrl;
  final List<String> imageUrls;
  final String? sku;

  bool get isValid =>
      name.isNotEmpty &&
      title.isNotEmpty &&
      description.isNotEmpty &&
      price != null &&
      (salePrice == null || salePrice! < price!);

  bool get hasCategoryReference =>
      (requestedCategoryId?.isNotEmpty ?? false) ||
      (requestedCategoryName?.isNotEmpty ?? false);

  bool get hasMissingCategory => hasCategoryReference && categoryId == null;

  String get missingCategoryLabel {
    if (requestedCategoryName != null && requestedCategoryName!.isNotEmpty) {
      return requestedCategoryName!;
    }
    if (requestedCategoryId != null && requestedCategoryId!.isNotEmpty) {
      return requestedCategoryId!;
    }
    return 'Unknown category';
  }
}

class AdminProductImportService {
  const AdminProductImportService();

  static const Map<String, String> _headerAliases = {
    'product_name': 'name',
    'product_title': 'title',
    'short_title': 'title',
    'details': 'description',
    'product_description': 'description',
    'category': 'category_name',
    'categoryid': 'category_id',
    'categoryname': 'category_name',
    'image_url': 'main_image_url',
    'main_image': 'main_image_url',
    'mainimageurl': 'main_image_url',
    'gallery': 'gallery_urls',
    'gallery_url': 'gallery_urls',
    'gallery_images': 'gallery_urls',
    'saleprice': 'sale_price',
    'stock': 'stock_quantity',
    'low_stock': 'low_stock_threshold',
    'featured_product': 'featured',
  };

  List<AdminProductImportRow> parseRows({
    required List<int> bytes,
    required String extension,
    required List<CategoryModel> categories,
  }) {
    return _parseSheetRows(bytes: bytes, extension: extension).map((row) {
      final price = tryParseDouble(row['price']);
      return AdminProductImportRow(
        name: row['name']?.trim() ?? '',
        title: row['title']?.trim() ?? '',
        description: row['description']?.trim() ?? '',
        price: price,
        salePrice: tryParseDouble(row['sale_price']),
        rating: tryParseDouble(row['rating']) ?? 0,
        sizes: parseImportedSizes(row['sizes']),
        stockQuantity: tryParseInt(row['stock_quantity']) ?? 0,
        lowStockThreshold: tryParseInt(row['low_stock_threshold']) ?? 5,
        status: normalizeImportedStatus(row['status']),
        featured: parseImportedBool(row['featured']),
        categoryId: resolveCategoryIdFromImportRow(
          row: row,
          categories: categories,
        ),
        requestedCategoryId: _normalizedValue(row['category_id']),
        requestedCategoryName: _normalizedValue(row['category_name']),
        mainImageUrl: _normalizedValue(row['main_image_url']),
        imageUrls: parseImportedUrls(row['gallery_urls']),
        sku: _normalizedValue(row['sku']),
      );
    }).toList();
  }

  List<Map<String, String>> _parseSheetRows({
    required List<int> bytes,
    required String extension,
  }) {
    return switch (extension) {
      'xlsx' => _parseExcelRows(bytes),
      'csv' => _parseCsvRows(bytes),
      _ => throw UnsupportedError('Only CSV and XLSX files are supported.'),
    };
  }

  List<Map<String, String>> _parseCsvRows(List<int> bytes) {
    final content = utf8.decode(bytes, allowMalformed: true);
    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(content);

    if (rows.isEmpty) return const [];

    final headers = rows.first
        .map((cell) => cell.toString().trim().toLowerCase())
        .toList();

    return rows.skip(1).where((row) => row.isNotEmpty).map((row) {
      return {
        for (var index = 0; index < headers.length; index++)
          headers[index]: index < row.length
              ? row[index].toString().trim()
              : '',
      };
    }).toList();
  }

  List<Map<String, String>> _parseExcelRows(List<int> bytes) {
    try {
      final excel = Excel.decodeBytes(bytes);
      final table = excel.tables.values.firstOrNull;
      if (table == null || table.rows.isEmpty) {
        return _parseExcelRowsWithFallbackDecoder(bytes);
      }

      final parsedRows = _rowsFromGrid(
        rows: table.rows,
        stringify: (cell) => cell?.value?.toString() ?? '',
      );
      if (parsedRows.isEmpty || !_containsRecognizedHeaders(parsedRows.first)) {
        return _parseExcelRowsWithFallbackDecoder(bytes);
      }
      return parsedRows;
    } catch (_) {
      return _parseExcelRowsWithFallbackDecoder(bytes);
    }
  }

  List<Map<String, String>> _parseExcelRowsWithFallbackDecoder(
    List<int> bytes,
  ) {
    final decoder = SpreadsheetDecoder.decodeBytes(bytes, update: false);
    if (decoder.tables.isEmpty) return const [];

    final table = decoder.tables.values.first;
    if (table.rows.isEmpty) return const [];

    return _rowsFromGrid(
      rows: table.rows,
      stringify: (cell) => cell?.toString() ?? '',
    );
  }

  List<Map<String, String>> _rowsFromGrid<T>({
    required List<List<T?>> rows,
    required String Function(T? cell) stringify,
  }) {
    if (rows.isEmpty) return const [];

    final headers = rows.first
        .map((cell) => _normalizeHeader(stringify(cell)))
        .toList();
    if (headers.every((header) => header.isEmpty)) {
      return const [];
    }

    return rows
        .skip(1)
        .where((row) => row.any((cell) => stringify(cell).trim().isNotEmpty))
        .map((row) {
          return {
            for (var index = 0; index < headers.length; index++)
              headers[index]: headers[index].isEmpty
                  ? ''
                  : index < row.length
                  ? stringify(row[index]).trim()
                  : '',
          }..remove('');
        })
        .toList();
  }

  bool _containsRecognizedHeaders(Map<String, String> row) {
    const expectedHeaders = {
      'name',
      'title',
      'description',
      'price',
      'category_name',
      'category_id',
      'main_image_url',
      'gallery_urls',
    };
    return row.keys.any(expectedHeaders.contains);
  }

  String? resolveCategoryIdFromImportRow({
    required Map<String, String> row,
    required List<CategoryModel> categories,
  }) {
    final categoryId = row['category_id']?.trim();
    if (categoryId != null && categoryId.isNotEmpty) {
      return categoryId;
    }

    final categoryName = row['category_name']?.trim().toLowerCase();
    if (categoryName == null || categoryName.isEmpty) {
      return null;
    }

    for (final category in categories) {
      if (category.name.trim().toLowerCase() == categoryName) {
        return category.id;
      }
    }

    return null;
  }

  List<int> parseImportedSizes(String? rawSizes) {
    if (rawSizes == null || rawSizes.trim().isEmpty) return const [];

    return rawSizes
        .split(RegExp(r'[|, ]+'))
        .map((value) => int.tryParse(value.trim()))
        .whereType<int>()
        .toList();
  }

  List<String> parseImportedUrls(String? rawUrls) {
    if (rawUrls == null || rawUrls.trim().isEmpty) return const [];

    return rawUrls
        .split(RegExp(r'[\n|,]+'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  String normalizeImportedStatus(String? status) {
    final normalized = status?.trim().toLowerCase() ?? '';
    return switch (normalized) {
      'draft' => 'draft',
      'hidden' => 'hidden',
      _ => 'active',
    };
  }

  bool parseImportedBool(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';
    return normalized == 'true' ||
        normalized == 'yes' ||
        normalized == '1' ||
        normalized == 'featured';
  }

  double? tryParseDouble(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return double.tryParse(value.trim());
  }

  int? tryParseInt(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return int.tryParse(value.trim());
  }

  String? _normalizedValue(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }

  String _normalizeHeader(String rawHeader) {
    final trimmed = rawHeader
        .replaceAll('\uFEFF', '')
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s\-\/]+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]+'), '');
    return _headerAliases[trimmed] ?? trimmed;
  }
}

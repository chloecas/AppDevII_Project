import 'dart:convert';

import 'package:http/http.dart' as http;

const String _apiKey = String.fromEnvironment('CARDDEX_API_KEY');

class CardDexException implements Exception {
  CardDexException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => 'CardDexException($statusCode): $message';
}

/// A card. The API docs don't list response fields yet, so the parsing below
/// is tolerant. Print one real response and tighten it (see README note).
class CardItem {
  const CardItem({
    required this.id,
    required this.name,
    this.imageUrl,
    this.largeImageUrl,
    this.value,
    this.setId,
  });

  final String id;
  final String name;
  final String? imageUrl;
  final String? largeImageUrl;
  final double? value;
  final String? setId;

  factory CardItem.fromJson(Map<String, dynamic> json) => CardItem(
    id: '${json['id']}',
    name: (json['name'] ?? 'Unknown card') as String,
    imageUrl: _imageFor(json),
    largeImageUrl: _imageFor(json, large: true),

    value: _findValue(json['prices'] ?? json['price']),
    setId: json['set'] is Map
        ? '${(json['set'] as Map)['id']}'
        : json['setId']?.toString(),
  );
}

class CardSet {
  const CardSet({required this.id, required this.name, this.releaseDate});

  final String id;
  final String name;
  final String? releaseDate;

  factory CardSet.fromJson(Map<String, dynamic> json) => CardSet(
    id: '${json['id']}',
    name: (json['name'] ?? 'Unknown set') as String,
    releaseDate: (json['releaseDate'] ?? json['release_date'])?.toString(),
  );
}

class CardDexApi {
  CardDexApi({http.Client? client}) : _client = client ?? http.Client();

  static const _baseUrl = 'https://api.carddex.dev';
  final http.Client _client;

  Future<dynamic> _get(String path, [Map<String, String>? query]) async {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);
    final response = await _client.get(uri, headers: {
      'Accept': 'application/json',
      if (_apiKey.isNotEmpty) 'X-API-Key': _apiKey,
    });
    if (response.statusCode != 200) {
      var message = 'Request failed';
      try {
        message = jsonDecode(response.body)['error']['message'] as String;
      } catch (_) {}
      throw CardDexException(response.statusCode, message);
    }
    return jsonDecode(response.body);
  }

  // List responses are assumed to look like {"data": [...]}. If yours returns
  // a bare list, this handles that too.
  List<Map<String, dynamic>> _items(dynamic body) {
    final list = body is Map ? body['data'] : body;
    return (list as List).cast<Map<String, dynamic>>();
  }

  /// GET /v1/cards
  Future<List<CardItem>> getCards({
    String? name,
    String? setId,
    int page = 1,
    int pageSize = 24,
  }) async {
    final body = await _get('/v1/cards', {
      if (name != null) 'name': name,
      if (setId != null) 'set': setId,
      'include': 'images,prices',
      'page': '$page',
      'pageSize': '$pageSize',
    });
    return _items(body).map(CardItem.fromJson).toList();
  }

  /// GET /v1/cards/{id}
  Future<Object> getCard(String id) async {
    final body = await _get('/v1/cards/$id', {'include': 'images,prices'});
    final json = body is Map && body['data'] is Map ? body['data'] : body;
    return CardItem.fromJson(json as Map<String, dynamic>);
  }

  /// GET /v1/sets (ordered by release date)
  Future<List<CardSet>> getSets() async {
    final body = await _get('/v1/sets');
    return _items(body).map(CardSet.fromJson).toList();
  }

  /// GET /v1/sets/{id}/cards
  Future<List<CardItem>> getSetCards(
      String setId, {
        int page = 1,
        int pageSize = 50,
      }) async {
    final body = await _get('/v1/sets/$setId/cards', {
      'include': 'images,prices',
      'page': '$page',
      'pageSize': '$pageSize',
    });
    return _items(body).map(CardItem.fromJson).toList();
  }
}

String? _imageFor(Map<String, dynamic> json, {bool large = false}) {
  final ptcg = json['ptcgio_id'];
  if (ptcg is String && ptcg.contains('-')) {
    final i = ptcg.indexOf('-');
    final set = ptcg.substring(0, i);
    final num = ptcg.substring(i + 1);
    return 'https://images.pokemontcg.io/$set/${num}${large ? '_hires' : ''}.png';
  }

  final direct = json['image_url'];
  if (direct is String && direct.startsWith('http')) return direct;

  return null;
}

/// Finds a market-style price number in whatever shape the API returns.
double? _findValue(dynamic node) {
  if (node is num) return node.toDouble();
  if (node is Map) {
    for (final key in ['market', 'average', 'avg', 'mid', 'low']) {
      if (node[key] is num) return (node[key] as num).toDouble();
    }
    for (final value in node.values) {
      final found = _findValue(value);
      if (found != null) return found;
    }
  }
  if (node is List) {
    for (final value in node) {
      final found = _findValue(value);
      if (found != null) return found;
    }
  }
  return null;
}
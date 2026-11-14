import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

//https://carddex.dev/sets
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
class Ability {
  const Ability({required this.name, this.text, this.type});

  final String name;
  final String? text;
  final String? type;

  factory Ability.fromJson(Map<String, dynamic> json) => Ability(
    name: (json['name'] ?? 'Unknown') as String,
    text: json['text'] as String?,
    type: json['type'] as String?,
  );
}

class Attack {
  const Attack({
    required this.name,
    this.cost = const [],
    this.damage,
    this.text,
  });

  final String name;
  final List<String> cost;
  final String? damage; // "20×", "30+", etc.
  final String? text;

  factory Attack.fromJson(Map<String, dynamic> json) => Attack(
    name: (json['name'] ?? 'Unknown') as String,
    cost: _stringList(json['cost']),
    damage: json['damage']?.toString(),
    text: json['text'] as String?,
  );
}

class TypeModifier {
  const TypeModifier({required this.type, required this.value});

  final String type;
  final String value;

  factory TypeModifier.fromJson(Map<String, dynamic> json) => TypeModifier(
    type: '${json['type'] ?? ''}',
    value: '${json['value'] ?? ''}',
  );
}

class CardItem {
  const CardItem({
    required this.id,
    required this.name,
    this.imageUrl,
    this.largeImageUrl,
    this.value,
    this.setId,
    this.setName,
    this.number,
    this.hp,
    this.rarity,
    this.supertype,
    this.subtypes = const [],
    this.types = const [],
    this.evolvesFrom,
    this.retreatCost,
    this.abilities = const [],
    this.attacks = const [],
    this.weaknesses = const [],
    this.resistances = const [],
    this.flavorText,
    this.artist,
    this.baseFinish,
  });

  final String id;
  final String name;
  final String? imageUrl;
  final String? largeImageUrl;
  final double? value;
  final String? setId;
  final String? setName;
  final String? number;
  final int? hp;
  final String? rarity;
  final String? supertype;
  final List<String> subtypes;
  final List<String> types;
  final String? evolvesFrom;
  final int? retreatCost;
  final List<Ability> abilities;
  final List<Attack> attacks;
  final List<TypeModifier> weaknesses;
  final List<TypeModifier> resistances;
  final String? flavorText;
  final String? artist;
  final String? baseFinish;

  factory CardItem.fromJson(Map<String, dynamic> json) => CardItem(
    id: '${json['id']}',
    name: (json['name'] ?? 'Unknown card') as String,
    imageUrl: _imageFor(json),
    largeImageUrl: _imageFor(json, large: true),
    value: _findValue(json['prices'] ?? json['price']),
    setId:
        json['set_id']?.toString() ??
        (json['set'] is Map ? '${(json['set'] as Map)['id']}' : null),
    setName: json['set_name'] as String?,
    number: json['number']?.toString(),
    hp: int.tryParse('${json['hp'] ?? ''}'),
    rarity: json['rarity'] as String?,
    supertype: json['supertype'] as String?,
    subtypes: _stringList(json['subtypes']),
    types: _stringList(json['types']),
    evolvesFrom: json['evolves_from'] as String?,
    retreatCost: int.tryParse('${json['retreat_cost'] ?? ''}'),
    abilities: _list(json['abilities'], Ability.fromJson),
    attacks: _list(json['attacks'], Attack.fromJson),
    weaknesses: _list(json['weaknesses'], TypeModifier.fromJson),
    resistances: _list(json['resistances'], TypeModifier.fromJson),
    flavorText: json['flavor_text'] as String?,
    artist: json['artist'] as String?,
    baseFinish: json['base_finish'] as String?,
  );
}

List<String> _stringList(dynamic v) =>
    v is List ? v.map((e) => '$e').toList() : const [];

List<T> _list<T>(dynamic v, T Function(Map<String, dynamic>) parse) => v is List
    ? v
          .whereType<Map>()
          .map((e) => parse(Map<String, dynamic>.from(e)))
          .toList()
    : const [];

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
    final response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        if (_apiKey.isNotEmpty) 'X-API-Key': _apiKey,
      },
    );
    if (response.statusCode != 200) {
      var message = 'Request failed';
      try {
        message = jsonDecode(response.body)['error']['message'] as String;
      } catch (_) {}
      throw CardDexException(response.statusCode, message);
    }
    return jsonDecode(response.body);
  }

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
      'include': 'images,prices,attacks,abilities,weaknesses,resistances',
      'page': '$page',
      'pageSize': '$pageSize',
    });
    return _items(body).map(CardItem.fromJson).toList();
  }

  /// GET /v1/cards/{id}
  Future<CardItem> getCard(String id) async {
    final body = await _get('/v1/cards/$id', {
      'include': 'images,prices,attacks,abilities,weaknesses,resistances',
    });
    final json = body is Map && body['data'] is Map ? body['data'] : body;
    return CardItem.fromJson(Map<String, dynamic>.from(json as Map));
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

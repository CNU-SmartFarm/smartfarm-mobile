import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'dart:developer';

Future<List<String>> fetchPlants(String query, String apiKey) async {
  final encodedQuery = Uri.encodeComponent(query);
  final numOfRows = 500;

  final url = Uri.parse(
    'http://api.nongsaro.go.kr/service/garden/gardenList?apiKey=$apiKey&searchWord=$encodedQuery&numOfRows=$numOfRows',
  );

  final response = await http.get(url);

  log('API 요청 URL: $url');
  log('API 응답 상태 코드: ${response.statusCode}');
  log('API 응답 본문: ${response.body}');

  if (response.statusCode == 200) {
    final document = xml.XmlDocument.parse(response.body);
    final items = document.findAllElements('item');

    List<String> allPlantNames = items
        .map((item) => item.findElements('cntntsSj').isNotEmpty
        ? item.findElements('cntntsSj').first.text
        : '이름 없음')
        .toList();

    if (query.isNotEmpty) {
      return allPlantNames
          .where((name) => name.contains(query))
          .toList();
    } else {
      return allPlantNames;
    }
  } else {
    throw Exception('식물 정보를 불러오는 데 실패했습니다. 상태 코드 : ${response.statusCode}');
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:hacker_news/article.dart';
import 'package:http/http.dart' as http;

void main() {
  test('Parse ids', () {
    final jsonString = """[25238639,25229672,25238778,25217436,25237188,25225775,25236609,25234187,25228733,25234300,25232783,25233622,25233398,25197418,25222120,25221831,25229552,25233353,25200702,25207732,25231578,25221474,25230408,25218865,25225755,25214264,25215801,25198465,25217835,25203876,25223054,25214738,25225294,25211940,25219694,25211563,25210815,25194393,25218781,25200712,25216709,25216041,25201906,25193275,25212865,25210648,25188256,25209495]""";
    expect(parseIds(jsonString).first, 25238639);
  });

  test('Parse article', () {
    final jsonString = """{"by":"dhouston","descendants":71,"id":8863,"kids":[9224,8917,8952,8958,8884,8887,8869,8940,8908,9005,8873,9671,9067,9055,8865,8881,8872,8955,10403,8903,8928,9125,8998,8901,8902,8907,8894,8870,8878,8980,8934,8943,8876],"score":104,"time":1175714200,"title":"My YC app: Dropbox - Throw away your USB drive","type":"story","url":"http://www.getdropbox.com/u/2/screencast.html"}""";
    expect(parseArticle(jsonString).by, "dhouston");
  });

  test('Parse article over network', () async {
    final url = 'https://hacker-news.firebaseio.com/v0/item/8863.json';
    final res = await http.get(url);
    
    if (res.statusCode == 200) {
      final article = parseArticle(res.body);
      expect(article.by, "dhouston");
    }
  });
}
import 'package:html/parser.dart';
import 'package:http/http.dart';
import 'package:xml/xml.dart' as xml;

import '../utils/types.dart';

Future<List<Episode>> krekScrape() async {
  print('Scraping latest from krek.hu');

  var httpClient = Client();
  var resp = await httpClient.get(
    Uri.parse(//post(
        'https://www.krek.hu/sources/webshop/product_list.php'), //body: {'prod_page': '12'}
  );
  var document = parse(resp.body);
  var rows = document.querySelectorAll('div.data');

  List<Episode> list = [];

  for (var row in rows) {
    List<String> downloadLinks = [];
    row.querySelector('div.dwnld')!.querySelectorAll('a').forEach((element) {
      downloadLinks.add(element.attributes.values.first);
    });

    if (downloadLinks.isEmpty) {
      continue;
    }

    list.add(Episode(
        PodcastID.krek, //! id
        dateFormat.parse(row.querySelector('div.datum')!.text), //! date
        row.querySelector('div.cim')!.text, //! title
        row.querySelector('div.hirdeto')!.text, //! author
        row.querySelector('div.igeresz')!.text, //! field1 (bible)
        (downloadLinks.length > 1) ? downloadLinks.first : null, //! field2 (youtube)
        downloadLinks.last, //! download
        null,
        null,
        null));
  }

  return list;
}

Episode krekFromJson(Map entry) => Episode(
    PodcastID.krek,
    dateFormat.parse(entry["date"]),
    entry["title"],
    entry["pastor"],
    entry["bible"],
    entry["youtube"],
    entry["download"],
    entry["uuid"],
    entry["length"],
    entry["size"]);

Map krekToJson(Episode episode) => {
      "title": episode.title,
      "bible": episode.field1,
      "date": dateFormat.format(episode.date),
      "pastor": episode.author,
      "youtube": episode.field2,
      "download": episode.download,
      "uuid": episode.uuid,
      "length": episode.length,
      "size": episode.fileSize,
    };

String krekTitle(Episode element) =>
    '${element.title} | ${element.author} | ${dateFormat.format(element.date)}';

String krekDescription(Podcast podcast, Episode element) {
  xml.XmlBuilder builder = xml.XmlBuilder();

  if (element.field2 != null) {
    builder.element('p', nest: () {
      builder.element('a', attributes: {"href": element.field2!}, nest: () {
        builder.text(
            'Az alkalomról videófelvétel is elérhető: ${element.field2}');
      });
    });
  }

  builder.element('br', isSelfClosing: true);

  builder.element('p', nest: () {
    builder.text('Igerész: ${element.field1}');
  });
  builder.element('p', nest: () {
    builder.text('Lelkész: ${element.author}');
  });

  builder.element('br', isSelfClosing: true);
  builder.element('hr', isSelfClosing: true);

  builder.element('p', nest: () {
    builder.text('Lejátszás közvetlen fájlból (hiba esetén): ');
    builder.element('a',
        attributes: {"href": podcast.properties.baseUrl + element.download},
        nest: () {
      builder.text(podcast.properties.baseUrl + element.download);
    });
  });

  builder.element('br', isSelfClosing: true);

  builder.element('p', nest: () {
    builder.text('Becsült hossz: ${element.length} mp');
  });
  builder.element('p', nest: () {
    builder.text('Generálta: ');
    builder.element('a',
        attributes: {"href": "https://reformatus.github.io/scrapecast"},
        nest: () {
      builder.text('ScrapeCast');
    });
    builder.text(' by Fodor Benedek');
  });
  builder.element('p', nest: () {
    builder.text('UUID: ${element.uuid}');
  });

  return builder
      .buildDocument()
      .toXmlString(pretty: true, preserveWhitespace: (_) => true);
}

String krekArtworkBuilder(Podcast podcast, Episode episode) {
  assert(podcast.properties.episodeArtworks!.length == 5);
  switch (episode.date.hour) {
    case 9:
      return podcast.properties.episodeArtworks![1];
    case 10:
      return podcast.properties.episodeArtworks![2];
    case 11:
      return podcast.properties.episodeArtworks![3];
    case 18:
      return podcast.properties.episodeArtworks![4];
    default:
      return podcast.properties.episodeArtworks![0];
  }
}

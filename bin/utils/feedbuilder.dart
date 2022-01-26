import 'package:xml/xml.dart';

import 'types.dart';

String getFeed(List<Episode> list, PodcastProperties properties) {
  String description = properties.description +
      ' \nLegutóbb frissítve: ${getRfcDate(DateTime.now())}';

  final builder = XmlBuilder();
  builder.processing('xml', 'version="1.0" encoding="UTF-8"');
  builder.element('rss', attributes: {
    'xmlns:itunes': 'http://www.itunes.com/dtds/podcast-1.0.dtd',
    'xmlns:content': 'http://purl.org/rss/1.0/modules/content/',
    'xmlns:atom': 'http://www.w3.org/2005/Atom',
    'version': '2.0'
  }, nest: () {
    builder.element('channel', nest: () {
      builder.element('title', nest: () {
        builder.cdata(properties.title); //! Title
      });
      builder.element('description', nest: () {
        builder.cdata(description); //! Descriion
      });
      builder.element('link', nest: () {
        builder.text(properties.link); //! Link
      });
      builder.element('image', nest: () {
        builder.element('url', nest: () {
          builder.text(properties.artworkLink); //! Image
        });
        builder.element('title', nest: () {
          builder.cdata(properties.title);
        });
        builder.element('link', nest: () {
          builder.text(properties.link);
        });
      });
      builder.element('generator', nest: () {
        builder.text('ScrapeCast');
      });
      builder.element('lastBuildDate', nest: () {
        builder.text(getRfcDate(DateTime.now()));
      }); /*
      builder.element('email', nest: () {
        builder.text(properties.ownerEmail);
      });*/
      builder.element('author', nest: () {
        builder.cdata(properties.author); //! Author
      });
      builder.element('copyright', nest: () {
        builder.cdata(properties.copyright); //! Copyght
      });
      builder.element('language', nest: () {
        builder.cdata(properties.language); //! Lanage
      });
      builder.element('itunes:author', nest: () {
        builder.text(properties.author); //! Author
      });
      builder.element('itunes:summary', nest: () {
        builder.cdata(description); //! Descriion
      });
      builder.element('itunes:type', nest: () {
        builder.text(properties.podcastType); //! Type
      });
      builder.element('itunes:owner', nest: () {
        builder.element('itunes:name', nest: () {
          builder.text(properties.ownerName);
        });
        builder.element('itunes:email', nest: () {
          builder.text(properties.ownerEmail);
        });
      });
      builder.element('itunes:explicit', nest: () {
        builder.text(properties.explicit ? "yes" : "no"); //! Is explicit
      });
      builder.element('itunes:category',
          attributes: {"text": properties.iCategory}, nest: () {
        builder.element('itunes:category',
            attributes: {"text": properties.iCategorySecondary}); //! Category
      });
      builder.element('itunes:image',
          attributes: {"href": properties.artworkLink}); //! Image
      builder.element('atom:link', attributes: {
        "rel": "hub",
        "href": "https://pubsubhubbub.appspot.com/"
      });

      for (Episode element in list) {
        builder.element('item', nest: () {
          builder.element('title', nest: () {
            builder.cdata(
                '${element.title} | ${element.pastor} | ${dateFormat.format(element.date)}');
          });
          builder.element('description', nest: () {
            builder.cdata(getDescription(properties.baseUrl, element));
          });
          builder.element('guid', attributes: {"isPermaLink": "false"},
              nest: () {
            builder.text(element.uuid);
          });
          builder.element('pubDate', nest: () {
            builder.text(getRfcDate(element.date));
          });
          builder.element('enclosure', attributes: {
            "url": (properties.baseUrl + element.download),
            "length": '${element.fileSize}',
            "type": 'audio/mpeg'
          });
          builder.element('itunes:summary', nest: () {
            builder.cdata(getDescription(properties.baseUrl, element));
          });
          builder.element('itunes:explicit', nest: () {
            builder.text(properties.explicit ? "yes" : "no");
          });
          builder.element('itunes:duration', nest: () {
            builder.text('${element.length}');
          });

          if (properties.episodeArtworks != null) {
            //! Krek exclusive behaviour
            if (properties.id == 1) {
              assert(properties.episodeArtworks!.length == 5);
              switch (element.date.hour) {
                case 9:
                  builder.element('itunes:image',
                      attributes: {"href": properties.episodeArtworks![1]});
                  break;
                case 10:
                  builder.element('itunes:image',
                      attributes: {"href": properties.episodeArtworks![2]});
                  break;
                case 11:
                  builder.element('itunes:image',
                      attributes: {"href": properties.episodeArtworks![3]});
                  break;
                case 18:
                  builder.element('itunes:image',
                      attributes: {"href": properties.episodeArtworks![4]});
                  break;
                default:
                  builder.element('itunes:image',
                      attributes: {"href": properties.episodeArtworks![0]});
              }
            } else {
              builder.element('itunes:image',
                  attributes: {"href": properties.artworkLink});
            }
          } else {
            builder.element('itunes:image',
                attributes: {"href": properties.artworkLink});
          }
          builder.element('itunes:episodeType', nest: () {
            builder.text('full');
          });
        });
      }
    });
  });

  return builder.buildDocument().toXmlString(pretty: true);
}

String getDescription(String baseUrl, Episode element) {
  XmlBuilder builder = XmlBuilder();

  if (element.youTube != null) {
    builder.element('p', nest: () {
      builder.element('a', attributes: {"href": element.youTube!}, nest: () {
        builder.text(
            'Az alkalomról videófelvétel is elérhető: ${element.youTube}');
      });
    });
  }

  builder.element('br', isSelfClosing: true);

  builder.element('p', nest: () {
    builder.text('Igerész: ${element.bible}');
  });
  builder.element('p', nest: () {
    builder.text('Lelkész: ${element.pastor}');
  });

  builder.element('br', isSelfClosing: true);
  builder.element('hr', isSelfClosing: true);

  builder.element('p', nest: () {
    builder.text('Lejátszás közvetlen fájlból (hiba esetén): ');
    builder.element('a', attributes: {"href": baseUrl + element.download},
        nest: () {
      builder.text(baseUrl + element.download);
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

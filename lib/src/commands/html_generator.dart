import 'package:analyzer/dart/element/type.dart';

String generateHtmlFile(Map<String, Iterable<DartType>> serviceInfo) {
  final Map<String, Iterable<String>> infoMap = serviceInfo.map((String key, Iterable<DartType> argList) {
    final Iterable<String> paramSet = argList.map((DartType e) {
      return e.getDisplayString(withNullability: false);
    });

    return MapEntry<String, Iterable<String>>(key, paramSet);
  });

  final StringBuffer sb = StringBuffer();

  final StringBuffer stylesSb = StringBuffer();
  final StringBuffer gridsSb = StringBuffer();

  final Map<String, Set<String>> diMap = <String, Set<String>>{};

  infoMap.forEach((String serviceName, Iterable<String> args) {
    for (final String param in args) {
      final Set<String>? curSet = diMap[param];
      if (curSet == null) {
        diMap[param] = <String>{serviceName};
      } else {
        diMap[param] = <String>{...curSet, serviceName};
      }
    }
  });

  // relations
  for (final String paramName in infoMap.keys) {
    bool isAbandoned = false;
    Set<String>? relationSet = diMap[paramName];
    final Iterable<String> originArgs = infoMap[paramName] ?? <String>[];

    // abandoned
    if (relationSet == null && originArgs.isEmpty) {
      relationSet = <String>{'-'};
      isAbandoned = true;
    }

    //
    if (relationSet == null) {
      continue;
    }

    final String gridDivs = relationSet.map((String name) {
      final String css = isAbandoned ? 'abandoned' : '';
      return '<div class="$css">$name</div>';
    }).join();

    // style
    if (!isAbandoned) {
      stylesSb.writeln('''
      .$paramName {
        grid-row-start: 1;
        grid-row-end: ${relationSet.length + 2};
      }
    ''');
    }

    // grid
    final String css = isAbandoned ? 'abandoned' : paramName;
    gridsSb.writeln('''
      <div class="grid-container">
        <div class="$css">$paramName</div>
        $gridDivs
      </div>
    ''');
  }

  sb.writeln('''
    <!DOCTYPE html>
    <html>
        <head>
            <style>
              .abandoned {
                background-color: rgba(141, 139, 139, 0.8) !important;
              }

              .grid-container {
                  display: grid;
                  grid-template-columns: auto auto;
                  background-color: #1a84db;
                  padding: 1px;
                  margin-bottom: 16px;
                }

                .grid-container>div {
                  background-color: rgba(255, 255, 255, 0.8);
                  text-align: center;
                  padding: 4px 0px;
                  font-size: 23px;
                  margin: 1px;
                }

                $stylesSb
            </style>
        </head>
        <body>
            <h1>DI visualizer</h1>

            $gridsSb
        </body>
    </html>
  ''');

  return sb.toString();
}

import 'package:analyzer/dart/element/type.dart';

String generateHtmlFile(Map<String, Iterable<DartType>> serviceInfo) {
  final StringBuffer sb = StringBuffer();

  final StringBuffer stylesSb = StringBuffer();
  final StringBuffer gridsSb = StringBuffer();

  final Map<String, Set<String>> diMap = <String, Set<String>>{};

  serviceInfo.forEach((String serviceName, Iterable<DartType> fieldList) {
    final Iterable<String> paramSet = fieldList.map((DartType e) {
      return e.getDisplayString(withNullability: false);
    });

    for (final String param in paramSet) {
      final Set<String>? curSet = diMap[param];
      if (curSet == null) {
        diMap[param] = <String>{serviceName};
      } else {
        diMap[param] = <String>{...curSet, serviceName};
      }
    }
  });

  // relations
  diMap.forEach((String paramName, Set<String> relationSet) {
    final String gridDivs = relationSet.map((String name) {
      return '<div>$name</div>';
    }).join();

    // style
    stylesSb.writeln('''
      .$paramName {
        grid-row-start: 1;
        grid-row-end: ${relationSet.length + 2};
      }
    ''');

    // grid
    gridsSb.writeln('''
      <div class="grid-container">
        <div class="$paramName">$paramName</div>
        $gridDivs
      </div>
    ''');
  });

  sb.writeln('''
    <!DOCTYPE html>
    <html>
        <head>
            <style>
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

import 'package:di_visualizer_annotation/di_visualizer_annotation.dart';

@diService
class Service1 {
  Service1(this.util, this.repository1);

  @diInject
  final Util util;

  @diInject
  final Repository1 repository1;
}

@diService
class Service2 {
  Service2(this.util, this.repository2);

  @diInject
  final Util util;

  @diInject
  final Repository2 repository2;
}

@diService
class Util {}

@diService
class RepoUtil {}

@diService
class Repository1 {
  Repository1(this.repoUtil);

  @diInject
  final RepoUtil repoUtil;
}

@diService
class Repository2 {
  Repository2(this.repoUtil);

  @diInject
  final RepoUtil repoUtil;
}

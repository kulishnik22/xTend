import 'package:equatable/equatable.dart';
import 'package:xtend/data/user_32/model/input/point.dart';

class MousePosition extends Equatable {
  const MousePosition({required this.x, required this.y});

  factory MousePosition.fromStruct(POINT point) =>
      MousePosition(x: point.x, y: point.y);

  factory MousePosition.fromJson(Map<String, dynamic> json) =>
      MousePosition(x: json['x'], y: json['y']);

  final int x;
  final int y;

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  @override
  List<Object?> get props => [x, y];
}

extension ListExt on List<DataCellState> {
  double width(CellId T) {
    CellId id = CellId.values.firstWhere((element) => element == T);
    return this[id.id].width;
  }
}

class DataCellState {
  final double minWidth;
  final double maxWidth;
  final double width;
  final int id;
  final String label;

  const DataCellState({
    this.width = 75,
    this.minWidth = 50,
    this.maxWidth = 100,
    required this.id,
    required this.label,
  });

  DataCellState copyWith({
    double? minWidth,
    double? maxWidth,
    double? width,
    int? id,
    String? label,
  }) {
    return DataCellState(
      minWidth: minWidth ?? this.minWidth,
      maxWidth: maxWidth ?? this.maxWidth,
      width: width ?? this.width,
      id: id ?? this.id,
      label: label ?? this.label,
    );
  }
}

enum CellId {
  State(0, '', minWidth: 26, maxWidth: 26),
  Id(1, 'Id', minWidth: 30, maxWidth: 40),
  Url(2, 'Url', maxWidth: 400),
  Client(3, 'Client'),
  Method(4, 'Method'),
  Status(5, 'Status'),
  Code(6, 'Code'),
  Time(7, 'Time'),
  Duration(8, 'Duration'),
  Secure(9, 'Secure');

  final int id;
  final String label;
  final double minWidth;
  final double maxWidth;
  const CellId(this.id, this.label, {this.minWidth = 50, this.maxWidth = 100});
}

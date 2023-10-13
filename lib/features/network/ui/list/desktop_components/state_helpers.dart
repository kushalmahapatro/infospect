extension ListExt on List<DataCellState> {
  double width(CellType cell) {
    final CellType cellId =
        CellType.values.firstWhere((element) => element == cell);
    return this[cellId.id].width;
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

enum CellType {
  columnState(0, '', minWidth: 26, maxWidth: 26),
  columnId(1, 'Id', minWidth: 30, maxWidth: 40),
  columnUrl(2, 'Url', maxWidth: 400, minWidth: 300),
  columnClient(3, 'Client'),
  columnMethod(4, 'Method'),
  columnStatus(5, 'Status'),
  columnCode(6, 'Code'),
  columnTime(7, 'Time', minWidth: 80, maxWidth: 200),
  columnDuration(8, 'Duration'),
  columnSecure(9, 'Secure');

  final int id;
  final String label;
  final double minWidth;
  final double maxWidth;
  const CellType(this.id, this.label,
      {this.minWidth = 50, this.maxWidth = 100});
}

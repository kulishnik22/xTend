import 'package:equatable/equatable.dart';
import 'package:xtend/keyboard/keyboard_controller.dart';

enum KeyboardLayoutType { alphabeticNumeric, specialCharacters, functional }

class KeyboardLayout extends Equatable {
  factory KeyboardLayout.fromType(KeyboardLayoutType type) => switch (type) {
    KeyboardLayoutType.alphabeticNumeric => KeyboardLayout.alphabeticNumeric(),
    KeyboardLayoutType.specialCharacters => KeyboardLayout.specialCharacters(),
    KeyboardLayoutType.functional => KeyboardLayout.alphabeticNumeric(),
  };

  factory KeyboardLayout.alphabeticNumeric() => KeyboardLayout(
    rowsCount: 5,
    columnsCount: 10,
    type: KeyboardLayoutType.alphabeticNumeric,
    initialCursor: const KeyboardCursor(4, 2),
    rows: [
      KeyRow.numeric(),
      const KeyRow([
        TextKey(value: 'q', capsLockVariant: 'Q'),
        TextKey(value: 'w', capsLockVariant: 'W'),
        TextKey(value: 'e', capsLockVariant: 'E'),
        TextKey(value: 'r', capsLockVariant: 'R'),
        TextKey(value: 't', capsLockVariant: 'T'),
        TextKey(value: 'y', capsLockVariant: 'Y'),
        TextKey(value: 'u', capsLockVariant: 'U'),
        TextKey(value: 'i', capsLockVariant: 'I'),
        TextKey(value: 'o', capsLockVariant: 'O'),
        TextKey(value: 'p', capsLockVariant: 'P'),
      ]),
      const KeyRow([
        VoidKey(0.5),
        TextKey(value: 'a', capsLockVariant: 'A'),
        TextKey(value: 's', capsLockVariant: 'S'),
        TextKey(value: 'd', capsLockVariant: 'D'),
        TextKey(value: 'f', capsLockVariant: 'F'),
        TextKey(value: 'g', capsLockVariant: 'G'),
        TextKey(value: 'h', capsLockVariant: 'H'),
        TextKey(value: 'j', capsLockVariant: 'J'),
        TextKey(value: 'k', capsLockVariant: 'K'),
        TextKey(value: 'l', capsLockVariant: 'L'),
        VoidKey(0.5),
      ]),
      const KeyRow([
        FunctionalKey(FunctionalKeyType.capsLock),
        TextKey(value: 'z', capsLockVariant: 'Z'),
        TextKey(value: 'x', capsLockVariant: 'X'),
        TextKey(value: 'c', capsLockVariant: 'C'),
        TextKey(value: 'v', capsLockVariant: 'V'),
        TextKey(value: 'b', capsLockVariant: 'B'),
        TextKey(value: 'n', capsLockVariant: 'N'),
        TextKey(value: 'm', capsLockVariant: 'M'),
        FunctionalKey(FunctionalKeyType.backspace),
      ]),
      const KeyRow([
        RedirectKey(KeyboardLayoutType.specialCharacters),
        VoidKey(),
        TextKey(value: ' ', width: 5),
        VoidKey(),
        FunctionalKey(FunctionalKeyType.enter),
      ]),
    ],
  );

  factory KeyboardLayout.specialCharacters() => KeyboardLayout(
    rowsCount: 5,
    columnsCount: 10,
    type: KeyboardLayoutType.specialCharacters,
    initialCursor: const KeyboardCursor(7, 3),
    rows: [
      KeyRow.numeric(),
      const KeyRow([
        TextKey(value: '#'),
        TextKey(value: '\$'),
        TextKey(value: '%'),
        TextKey(value: '&'),
        TextKey(value: '@'),
        TextKey(value: '-'),
        TextKey(value: '+'),
        TextKey(value: '*'),
        TextKey(value: '/'),
        TextKey(value: '='),
      ]),
      const KeyRow([
        TextKey(value: '('),
        TextKey(value: ')'),
        TextKey(value: '{'),
        TextKey(value: '}'),
        TextKey(value: '['),
        TextKey(value: ']'),
        TextKey(value: '<'),
        TextKey(value: '>'),
        TextKey(value: '|'),
        TextKey(value: '\\'),
      ]),
      const KeyRow([
        TextKey(value: '_'),
        TextKey(value: '^'),
        TextKey(value: '"'),
        TextKey(value: '\''),
        TextKey(value: ';'),
        TextKey(value: ':'),
        TextKey(value: ','),
        TextKey(value: '.'),
        TextKey(value: '?'),
        TextKey(value: '!'),
      ]),
      const KeyRow([
        RedirectKey(KeyboardLayoutType.functional),
        VoidKey(),
        TextKey(value: ' ', width: 5),
        VoidKey(),
        FunctionalKey(FunctionalKeyType.backspace),
      ]),
    ],
  );
  const KeyboardLayout({
    required this.type,
    required this.rows,
    required this.rowsCount,
    required this.columnsCount,
    required this.initialCursor,
  });
  final List<KeyRow> rows;
  final KeyboardLayoutType type;
  final int rowsCount;
  final int columnsCount;
  final KeyboardCursor initialCursor;

  KeyboardCursor? findFirst(bool Function(KeyboardKey) test) {
    for (int y = 0; y < rows.length; y++) {
      KeyRow row = rows[y];
      int x = row.findFirst(test);
      if (x == -1) {
        continue;
      }
      return KeyboardCursor(x, y);
    }
    return null;
  }

  @override
  List<Object?> get props => [
    rows,
    type,
    rowsCount,
    columnsCount,
    initialCursor,
  ];
}

class KeyRow extends Equatable {
  const KeyRow(this.keys);
  KeyRow.numeric()
    : keys = [
        const TextKey(value: '0'),
        const TextKey(value: '1'),
        const TextKey(value: '2'),
        const TextKey(value: '3'),
        const TextKey(value: '4'),
        const TextKey(value: '5'),
        const TextKey(value: '6'),
        const TextKey(value: '7'),
        const TextKey(value: '8'),
        const TextKey(value: '9'),
      ];
  final List<KeyboardKey> keys;

  int findFirst(bool Function(KeyboardKey) test) {
    return keys.where((key) => key is! VoidKey).toList().indexWhere(test);
  }

  @override
  List<Object?> get props => [keys];
}

sealed class KeyboardKey<T> extends Equatable {
  const KeyboardKey();
  double get width;
  T get value;
  @override
  List<Object?> get props => [width, value];
}

class VoidKey extends KeyboardKey<void> {
  const VoidKey([this.width = 1]);

  @override
  final double width;
  @override
  final void value = null;
}

class TextKey extends KeyboardKey<String> {
  const TextKey({required this.value, String? capsLockVariant, this.width = 1})
    : capsLockVariant = capsLockVariant ?? value;
  @override
  final String value;
  final String capsLockVariant;

  @override
  final double width;

  @override
  List<Object?> get props => [width, value, capsLockVariant];
}

class RedirectKey extends KeyboardKey<KeyboardLayoutType> {
  const RedirectKey(this.value, [this.width = 1.5]);
  @override
  final KeyboardLayoutType value;

  @override
  final double width;
}

enum FunctionalKeyType { backspace, enter, capsLock }

class FunctionalKey extends KeyboardKey<FunctionalKeyType> {
  const FunctionalKey(this.value, [this.width = 1.5]);
  @override
  final FunctionalKeyType value;

  @override
  final double width;
}

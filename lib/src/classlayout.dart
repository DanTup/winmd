import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'base.dart';
import 'com/constants.dart';
import 'scope.dart';

/// A tuple of a field and its byte offset within a parent struct.
class FieldOffset extends TokenObject {
  /// The byte offset of a specific field relative to its parent struct.
  ///
  /// Normally fields are located consecutively within a struct, but in a union
  /// the fields are aligned with the 0th index of the struct.
  final int offset;

  const FieldOffset(Scope scope, int fieldToken, this.offset)
      : super(scope, fieldToken);
}

/// Layout information for the class referenced by a specified token.
class ClassLayout extends TokenObject {
  /// The array of field offsets, for manually-aligned structs.
  List<FieldOffset>? fieldOffsets;

  /// The size in bytes of the class represented.
  int? minimumSize;

  /// The pack size of the class.
  ///
  /// If specified, this contains one of the values 1, 2, 4, 8, or 16,
  /// representing the packing alignment of the class. If null, no packing
  /// alignment is specified.
  int? packingAlignment;

  ClassLayout(Scope scope, int classToken) : super(scope, classToken) {
    // Check for synthetic type like GUID
    if (classToken == 0) {
      return;
    }

    using((Arena arena) {
      final pdwPackSize = arena<DWORD>();
      final rgFieldOffset = arena<COR_FIELD_OFFSET>(256);
      final pcFieldOffset = arena<ULONG>();
      final pulClassSize = arena<ULONG>();

      final hr = reader.GetClassLayout(classToken, pdwPackSize, rgFieldOffset,
          256, pcFieldOffset, pulClassSize);
      if (SUCCEEDED(hr)) {
        packingAlignment = pdwPackSize.value;
        minimumSize = pulClassSize.value;
        fieldOffsets = <FieldOffset>[];

        final offsetCount = pcFieldOffset.value;
        for (var i = 0; i < offsetCount; i++) {
          final offset = rgFieldOffset.elementAt(i).ref;
          fieldOffsets
              ?.add(FieldOffset(scope, offset.ridOfField, offset.ulOffset));
        }
      } else if (hr == CLDB_E_RECORD_NOTFOUND) {
        // No class layout record, so leave the fields null
        return;
      } else {
        // Some other failure
        throw WindowsException(hr);
      }
    });
  }
}

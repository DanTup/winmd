// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'base.dart';
import 'mixins/customattributes_mixin.dart';
import 'scope.dart';

/// A module reference.
class ModuleRef extends TokenObject with CustomAttributesMixin {
  final String name;

  ModuleRef(Scope scope, int token, this.name) : super(scope, token);

  /// Creates a module object from a provided token.
  factory ModuleRef.fromToken(Scope scope, int token) => using((Arena arena) {
        final szName = arena<WCHAR>(MAX_STRING_SIZE).cast<Utf16>();
        final pchName = arena<ULONG>();

        final reader = scope.reader;
        final hr =
            reader.GetModuleRefProps(token, szName, MAX_STRING_SIZE, pchName);

        if (SUCCEEDED(hr)) {
          return ModuleRef(scope, token, szName.toDartString());
        } else {
          throw WindowsException(hr);
        }
      });

  @override
  String toString() => name;
}

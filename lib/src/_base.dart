// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'com/IMetaDataImport2.dart';
import 'customattribute.dart';

// The base object for metadata objects.
abstract class TokenObject {
  final IMetaDataImport2 reader;
  final int token;

  const TokenObject(this.reader, this.token);

  /// Token is valid within the current metadata scope
  bool get isValidToken => reader.IsValidToken(token) == TRUE;

  /// Token is marked as global
  bool get isGlobal {
    if (isValidToken) {
      final pIsGlobal = calloc<Int32>();

      try {
        final hr = reader.IsGlobal(token, pIsGlobal);
        if (SUCCEEDED(hr)) {
          return pIsGlobal.value == 1;
        } else {
          throw WindowsException(hr);
        }
      } finally {
        calloc.free(pIsGlobal);
      }
    } else {
      return false;
    }
  }

  @override
  int get hashCode => token;

  @override
  bool operator ==(Object other) =>
      other is TokenObject && other.token == token;
}

/// Represents an object that has custom (named) attributes associated with it.
mixin CustomAttributes on TokenObject {
  /// Retrieve the string associated with a specific attribute name.
  String attributeAsString(String attrName) {
    final szName = attrName.toNativeUtf16();
    final ppData = calloc<IntPtr>();
    final pcbData = calloc<Uint32>();
    try {
      final hr =
          reader.GetCustomAttributeByName(token, szName, ppData, pcbData);
      if (SUCCEEDED(hr)) {
        if (pcbData.value <= 3) return '';
        final sigList = Pointer<Uint8>.fromAddress(ppData.value)
            .elementAt(3)
            .cast<Utf8>()
            .toDartString();
        return sigList;
      } else {
        throw WindowsException(hr);
      }
    } finally {
      calloc.free(szName);
      calloc.free(ppData);
      calloc.free(pcbData);
    }
  }

  /// Retrieve the blob associated with a specific attribute name.
  Uint8List attributeSignature(String attrName) {
    final szName = attrName.toNativeUtf16();
    final ppData = calloc<IntPtr>();
    final pcbData = calloc<Uint32>();
    try {
      final hr =
          reader.GetCustomAttributeByName(token, szName, ppData, pcbData);
      if (SUCCEEDED(hr)) {
        final sigList =
            Pointer<Uint8>.fromAddress(ppData.value).asTypedList(pcbData.value);
        return sigList;
      } else {
        throw WindowsException(hr);
      }
    } finally {
      calloc.free(szName);
      calloc.free(ppData);
      calloc.free(pcbData);
    }
  }

  /// Enumerate all attributes that this object has.
  List<CustomAttribute> get customAttributes {
    final attributes = <CustomAttribute>[];

    final phEnum = calloc<IntPtr>();
    final rAttrs = calloc<Uint32>();
    final pcAttrs = calloc<Uint32>();

    try {
      // Certain TokenObjects may not have a valid token (e.g. a return
      // type has a token of 0). In this case, we return an empty set, since
      // calling EnumCustomAttributes with a scope of 0 will return all
      // attributes on all objects in the scope.
      if (!isValidToken) return attributes;

      var hr =
          reader.EnumCustomAttributes(phEnum, token, 0, rAttrs, 1, pcAttrs);
      while (hr == S_OK) {
        final attrToken = rAttrs.value;

        attributes.add(CustomAttribute.fromToken(reader, attrToken));
        hr = reader.EnumCustomAttributes(phEnum, token, 0, rAttrs, 1, pcAttrs);
      }
      return attributes;
    } finally {
      reader.CloseEnum(phEnum.value);
      calloc.free(phEnum);
      calloc.free(rAttrs);
      calloc.free(pcAttrs);
    }
  }
}

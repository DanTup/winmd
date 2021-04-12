import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'base.dart';
import 'com/IMetaDataImport2.dart';
import 'constants.dart';
import 'mixins/customattributes_mixin.dart';
import 'typedef.dart';
import 'win32.dart';

class Event extends TokenObject with CustomAttributesMixin {
  final String eventName;
  final int _parentToken;
  final int _attributes;
  final int eventType;
  final int addOnToken;
  final int removeOnToken;
  final int fireToken;
  final List<int> otherMethodTokens;

  TypeDef get parent => TypeDef.fromToken(reader, _parentToken);

  bool get isSpecialName =>
      _attributes & CorEventAttr.evSpecialName == CorEventAttr.evSpecialName;

  bool get isRTSpecialName =>
      _attributes & CorEventAttr.evRTSpecialName ==
      CorEventAttr.evRTSpecialName;

  Event(
      IMetaDataImport2 reader,
      int token,
      this._parentToken,
      this.eventName,
      this._attributes,
      this.eventType,
      this.addOnToken,
      this.removeOnToken,
      this.fireToken,
      this.otherMethodTokens)
      : super(reader, token);

  /// Creates an event object from its given token.
  factory Event.fromToken(IMetaDataImport2 reader, int token) {
    final ptkClass = calloc<mdTypeDef>();
    final szEvent = stralloc(MAX_STRING_SIZE);
    final pchEvent = calloc<ULONG>();
    final pdwEventFlags = calloc<DWORD>();
    final ptkEventType = calloc<mdToken>();
    final ptkAddOn = calloc<mdMethodDef>();
    final ptkRemoveOn = calloc<mdMethodDef>();
    final tkkFire = calloc<mdMethodDef>();
    final rgOtherMethod = calloc<mdMethodDef>(16);
    final pcOtherMethod = calloc<ULONG>();

    try {
      final hr = reader.GetEventProps(
          token,
          ptkClass,
          szEvent,
          MAX_STRING_SIZE,
          pchEvent,
          pdwEventFlags,
          ptkEventType,
          ptkAddOn,
          ptkRemoveOn,
          tkkFire,
          rgOtherMethod,
          16,
          pcOtherMethod);

      if (SUCCEEDED(hr)) {
        return Event(
            reader,
            token,
            ptkClass.value,
            szEvent.toDartString(),
            pdwEventFlags.value,
            ptkEventType.value,
            ptkAddOn.value,
            ptkRemoveOn.value,
            tkkFire.value,
            rgOtherMethod.asTypedList(pcOtherMethod.value));
      } else {
        throw WindowsException(hr);
      }
    } finally {
      free(ptkClass);
      free(szEvent);
      free(pchEvent);
      free(pdwEventFlags);
      free(ptkEventType);
      free(ptkAddOn);
      free(ptkRemoveOn);
      free(tkkFire);
      free(rgOtherMethod);
      free(pcOtherMethod);
    }
  }
}
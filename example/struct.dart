import 'package:win32/win32.dart';
import 'package:winmd/winmd.dart';

void main() {
  final scope = MetadataStore.getWin32Scope();

  // Find a namesapce
  final struct = scope
      .findTypeDef('Windows.Win32.NetworkManagement.WiFi.WLAN_RAW_DATA_LIST')!;
  final unionField = struct.fields.last; // union
  final unionFieldType = unionField.typeIdentifier.typeArg?.type;
  print('unionField: $unionFieldType | isNested: ${unionFieldType?.isNested}');
  print('Field: ${unionField.token.toHexString(32)}');

  print('Nested: ${struct.nestedTypeDefs}');
  final nestedStruct = struct.nestedTypeDefs
      .firstWhere((t) => t.name == unionField.typeIdentifier.typeArg!.name);
  print('nestedStruct: $nestedStruct | isNested: ${nestedStruct.isNested}');

  print('match: ${unionFieldType == nestedStruct}');
}
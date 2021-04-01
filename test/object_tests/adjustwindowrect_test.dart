@TestOn('windows')

import 'package:test/test.dart';
import 'package:winmd/winmd.dart';

void main() {
  // .method public hidebysig static pinvokeimpl("USER32" nomangle lasterr winapi)
  // 	valuetype Windows.Win32.SystemServices.BOOL AdjustWindowRect (
  // 		[in] [out] valuetype [Windows.Win32.winmd]Windows.Win32.DisplayDevices.RECT* lpRect,
  // 		[in] uint32 dwStyle,
  // 		[in] valuetype Windows.Win32.SystemServices.BOOL bMenu
  // 	) cil managed preservesig
  // {
  // 	.custom instance void [Windows.Win32.Interop]Windows.Win32.Interop.SupportedOSPlatformAttribute::.ctor(string) = (
  // 		01 00 0a 77 69 6e 64 6f 77 73 35 2e 30 00 00
  // 	)
  // } // end of method Apis::AdjustWindowRect
  test('Windows.Win32.WindowsAndMessaging.Apis.AdjustWindowRect', () {
    final scope = MetadataStore.getWin32Scope();
    final typedef = scope['Windows.Win32.WindowsAndMessaging.Apis']!;
    final awr = typedef.findMethod('AdjustWindowRect')!;

    expect(awr.isPublic, isTrue);
    expect(awr.hasAttribute(CorMethodAttr.mdHideBySig), isTrue);
    expect(awr.isStatic, isTrue);
    expect(awr.hasAttribute(CorMethodAttr.mdPinvokeImpl), isTrue);

    expect(
        awr.attributeSignature(
            'Windows.Win32.Interop.SupportedOSPlatformAttribute'),
        equals([
          0x01, 0x00, 0x0a, 0x77, 0x69, 0x6e, 0x64, 0x6f, //
          0x77, 0x73, 0x35, 0x2e, 0x30, 0x00, 0x00
        ]));
  });
}

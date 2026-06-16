import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';

void callPhoneNumber(String phoneNumber) async {
  try {
    await FlutterPhoneDirectCaller.callNumber(phoneNumber);
  } catch (e) {
    print('Error calling phone number: $e');
  }
}
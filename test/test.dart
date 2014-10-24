import 'package:secret_sharing/secret_sharing.dart';
import 'package:unittest/unittest.dart';
import 'random_test_util.dart';

main() {
  globalRandomCount = 100;
  
  rTest("Raw share codec", () {
    var codec = new RawShareCodec(3, 2);
    var shares = codec.encode(900000000000000);
    var decodable = (shares..shuffle).sublist(1);
    var decoded = codec.decode(decodable);
    expect(decoded, equals(900000000000000));
  });
  
  
  rTest("String share codec with dynamic charset", () {
    var secret = r"Some strange signs :-'$#äöü";
    var codec = new StringShareCodec.bySecret(3, 2, secret);
    var shares = codec.encode(secret);
    var decoded = codec.decode((shares..shuffle).sublist(1, 3));
    expect(decoded, equals(secret));
  });
}
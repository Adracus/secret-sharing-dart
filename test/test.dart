import 'package:secret_sharing/secret_sharing.dart';
import 'package:unittest/unittest.dart';

const int RANDOM_COUNT = 30000;

rTest(String name, f(), {randomCount: RANDOM_COUNT}) {
  test(name, () {
    for (int i = 0; i < RANDOM_COUNT; i++) {
      f();
    }
  });
}

main() {
  /*
  test("Share parsing", () {
    var share = new StringShare("abc-0-1");
    expect(share.point, equals(new Point(0, 1)));
    expect(share.charsetString, equals("abc"));
    share = new StringShare("ab----10-5");
    expect(share.point, equals(new Point(10, 5)));
    expect(share.charsetString, equals("ab-"));
    share = new StringShare("bab---001-6");
    expect(share.point, equals(new Point(1, 6)));
    expect(share.charsetString, equals("ba-"));
    share = new RawShare("10-5");
    expect(share.point, equals(new Point(10, 5)));
    share = new RawShare("01-5");
    expect(share.point, equals(new Point(1, 5)));
  });*/
  
  rTest("Raw share codec", () {
    var codec = new RawShareCodec(3, 2);
    var shares = codec.encode(200000000000);
    var decoded = codec.decode(shares.sublist(1, 3));
    expect(decoded, equals(200000000000));
  });
  
  
  rTest("String share codec", () {
    var codec = new StringShareCodec(3, 2);
    var shares = codec.encode("Test");
    var decoded = codec.decode(shares.sublist(1, 3));
    expect(decoded, equals("Test"));
  });
}
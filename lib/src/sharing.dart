part of secret_sharing;

/// A basic representation of a share produced by [ShareEncoder]s
/// 
/// A share is produced if a [ShareEncoder] encodes a secret into
/// parts. A specific number of shares is neeeded to recover the
/// original secret.
abstract class Share {
}


/// A share from an int secret value
/// 
/// This kind of share is generated, if you encode an int with
/// a [RawShareEncoder]. You need a specific number to recover
/// the original secret.
class RawShare implements Share {
  
  /// The point this share represents
  /// 
  /// A [RawShare] consists of the point generated by a [SecretPolynomial].
  final Point<int> point;
  
  /// Creates a [RawShare] with the specified point.
  RawShare.fromPoint(this.point);
  
  /// Creates a [RawShare] from a share string.
  /// 
  /// This basically parses the given share string. The
  /// String has to be in the format x-y where x and y
  /// are hexadecimal values.
  factory RawShare(String rawShare) {
    var parts = rawShare.split("-");
    var x = int.parse(parts[0], radix: 16);
    var y = int.parse(parts[1], radix: 16);
    return new RawShare.fromPoint(new Point(x, y));
  }
  
  /// Produces a string of the form "x-y" where x and y are hexadecimal values
  String toString() => point.x.toRadixString(16) + "-" +
      point.y.toRadixString(16);
}


/// A share representing a part of an encoded String secret
/// 
/// A [StringShare] consists of a [Charset] which represents
/// the chars of the secret string. It also has a [RawShare]
/// which is the part of the string secret encoded to int.
class StringShare implements RawShare {
  
  /// The [Charset] which the secret String belongs to.
  final Charset charset;
  
  /// The [RawShare] holding the information of the String secret encoded as int.
  final RawShare rawShare;
  
  /// Creates a new StringShare with the specified [Charset] and [RawShare].
  StringShare._(this.charset, this.rawShare);
  
  /// Parses a [StringShare]
  /// 
  /// This parses a [StringShare]. A [StringShare] can have various formats:
  /// 
  /// * charset-x-y: This is a [StringShare] with a [DynamicCharset]
  /// * $$name-x-y: This is a [StringShare] which explicitly uses the charset with
  ///   the specified name
  /// * x-y: This is a [StringShare] with the default [ASCIICharset]
  factory StringShare.parse(String share) {
    int ct = 0;
    int i = share.length - 1;
    var charsetString = "";
    var rawShareString = "";
    for (int i = share.length -1; i >= 0; i--) {
      if (share[i] == "-") {
        ct ++;
        if (ct == 2) continue;
      }
      if (ct <= 1) {
        rawShareString = share[i] + rawShareString;
        continue;
      }
      charsetString = share[i] + charsetString;
    }
    var rawShare = new RawShare(rawShareString);
    var charset = new Charset.fromString(charsetString);
    return new StringShare._(charset, rawShare);
  }
  
  /// Converts this [StringShare] to its String representation
  String toString() => charsetString == "" ? rawShare.toString() :
    charsetString + "-" + rawShare.toString();
  
  /// Returns a representation of the [Charset] in form of a String
  String get charsetString => charset.representation;
  
  /// Returns the point of the [RawShare] of this
  Point get point => rawShare.point;
}


/// A class which specifies a share encoder.
/// 
/// A share encoder needs to know about the number of needed shares
/// (number of shares needed to reproduce the original secret) and the number
/// of total shares (the number of shares it should produce).
/// An encoder should be able to encode from [E] to a [List] of [int]s.
abstract class ShareEncoder<E, S extends Share> extends Converter<E, List<S>> {
  /// The number of total shares this encoder should produce if [convert] is used.
  final int noOfShares;
  
  /// The number of shares needed to recover the original secret.
  final int neededShares;
  
  /// Creates a new Instance of [ShareEncoder]
  /// 
  /// The default number of total and needed shares is 2 and can
  /// be omitted.
  ShareEncoder([this.noOfShares = 2, this.neededShares = 2]) {
    if (noOfShares < neededShares)
      throw new ArgumentError("No of shares cannot be < than needed Shares");
  }
}


/// A class which specifies a Share decoder
/// 
/// A Share Decoder should be able to decode from a list of [int]s to [E]
abstract class ShareDecoder<E, S extends Share> extends Converter<List<S>, E> {
}

/// A class which encodes an [int] secret to a [List] of [RawShare]s.
class RawShareEncoder extends ShareEncoder<int, RawShare> {
  /// The random generator used for coefficient generation
  final Random random;
  
  /// Instantiates a new [RawShareEncoder].
  /// 
  /// This creates a new [RawShareEncoder] with the specified number of total
  /// and needed shares. The number of needed shares specifies how many
  /// shares are needed to recover the secret [int] and the number of total
  /// shares specifies the number of [RawShare]s produced if you call [convert]
  /// with a secret int. If you don't specify a [random], [BRandom] is used.
  /// ATTENTION: [BRandom] is not cryptographically secure as well as Darts
  /// underlying [Random].
  RawShareEncoder(int noOfShares, int neededShares, Random random)
      : random = random == null ? _random : random,
        super(noOfShares, neededShares);
  
  
  /// Converts a secret [int] to a [List] of [RawShare]s.
  /// 
  /// Converts the given secret [int] to a [List] of [RawShare]s.
  /// If you want to recover the given secret, [neededShares] are
  /// needed.
  List<RawShare> convert(int secret) {
    var p = new SecretPolynomial(secret, neededShares, random);
    log.info("Converting with prime ${p.prime}");
    log.info("Polynomial is $p");
    return p.getShares(noOfShares).map((p) =>
        new RawShare.fromPoint(p)).toList();
  }
}


/// An encoder which can be used to convert secret [String]s to [StringShare]s
/// 
/// This class can be used to create encoders, which encode a given secret
/// [String] to a [List] of [StringShare]s.
class StringShareEncoder extends ShareEncoder<String, StringShare> {
  
  /// The [RawShareEncoder] which is used to encode the int representation of the secret [String]
  final RawShareEncoder _encoder;
  
  /// The [Charset] this encoder should use to encode given [String]s.
  final Charset charset;
  
  /// The [CharsetToIntConverter] used to get the [int] representation of given [String]s
  final CharsetToIntConverter converter;
  
  
  /// Instantiates a new encoder which uses a dynamic charset based on the given secret
  /// 
  /// This creates a new encoder, which produces [noOfShares] shares if you call
  /// the [convert] method. [neededShares] are needed to recover the given
  /// [secret]. The [Charset] used by this encoder is a [DynamicCharset].
  factory StringShareEncoder.bySecret(int noOfShares, int neededShares, String secret,
      {Random random}) {
    var charset = new Charset.create(secret);
    return new StringShareEncoder(noOfShares, neededShares, charset, random: random);
  }
  
  /// Instantiates a new encoder with the specified [noOfShares], [neededShares]
  /// and [charset].
  /// 
  /// This creates a new encoder, which produces [noOfShares] shares if you call
  /// the [convert] method. [neededShares] are needed to recover the given
  /// [secret]. The [Charset] is specified by [charset]. If no [random] is 
  /// specified, [BRandom] is used.
  /// ATTENTION: Both [Random] and [BRandom] are NOT cryptographically secure.
  StringShareEncoder(int noOfShares, int neededShares, Charset charset, {Random random})
      : charset = charset,
        _encoder = new RawShareEncoder(noOfShares, neededShares,
            random == null? random : _random),
        converter = new CharsetToIntConverter(charset),
        super(noOfShares, neededShares);
  
  /// Converts the given [secret] to a [List] of [StringShare]s.
  List<StringShare> convert(String secret) {
    var representation = converter.convert(secret);
    var rawShares = _encoder.convert(representation);
    return rawShares.map((share) =>
        new StringShare._(charset, share)).toList();
  }
}


/// A decoder which can be used to recover a secret [String] from a [List] of
/// [StringShare]s.
class StringShareDecoder extends ShareDecoder<String, StringShare> {
  
  /// The decoder used to decode the [int] representation of the secret [String]
  final _decoder = new RawShareDecoder();
  
  /// Recovers the secret [String] from the given [shares].
  String convert(List<StringShare> shares) {
    var rawShares = shares.map((share) => share.rawShare).toList();
    var secretInt = _decoder.convert(rawShares);
    var converter = new IntToCharsetConverter(shares.first.charset);
    return converter.convert(secretInt);
  }
}


/// A decoder which can be used to recover a secret [int] of a [List] of [RawShare]s
class RawShareDecoder extends ShareDecoder<int, RawShare> {
  
  /// Recovers the secret [int] from the given [shares]
  int convert(List<RawShare> shares) {
    var points = shares.map((s) => s.point);
    return modularLagrange(shares.map((s) => s.point).toList());
  }
}


/// A codec which is capable of en- and decoding secret [E]s.
abstract class ShareCodec<E, S extends Share> extends Codec<E, List<S>> {
  
  /// The number of shares this codec shall produce during [encode].
  final int noOfShares;
  
  /// The number of shares needed to recover secrets encoded by this.
  final int neededShares;
  
  /// Creates a new [ShareCodec] producing [noOfShares] shares and needing
  /// [neededShares] to recover the secret [E].
  ShareCodec(this.noOfShares, this.neededShares);
}


/// A codec which is capable of en- and decoding secret [int]s.
/// 
/// During encoding, this produces a [List] of [RawShare]s. Encoded
/// [int]s need [neededShares] shares to be recovered.
class RawShareCodec extends ShareCodec<int, RawShare> {
  
  /// The decoder used to decode [RawShare]s to [int]
  final RawShareDecoder decoder = new RawShareDecoder();
  
  /// The encoder which produces [RawShare]s from secret [int]s
  final RawShareEncoder encoder;
  
  /// Creates a new codec which is capable of en- and decoding secret [int]s
  RawShareCodec(int noOfShares, int neededShares, {Random random})
      : encoder = new RawShareEncoder(noOfShares, neededShares, random),
        super(noOfShares, neededShares);
}


/// A [ShareCodec] for en- and decoding secret [String]s.
class StringShareCodec extends ShareCodec<String, StringShare> {
  
  /// The decoder used to recover secret [String]s from [StringShare]s.
  final StringShareDecoder decoder = new StringShareDecoder();
  
  /// The encoder used to encode secret [String]s to [StringShare]s.
  final StringShareEncoder encoder;
  
  /// The charset the [encoder] should use while [encode].
  final Charset charset;
  
  /// Creates a new codec
  /// 
  /// [noOfShares] shares will be produced during [encode]. If an encoded secret
  /// should be [decode]d, then [neededShares] shares are needed. The [charset]
  /// used by this codec is a [DynamicCharset] specified by [secret].
  factory StringShareCodec.bySecret(int noOfShares, int neededShares, String secret,
      {Random random}) {
    var charset = new Charset.create(secret);
    return new StringShareCodec(noOfShares, neededShares, charset, random: random);
  }
  
  /// Creates a new codec
  /// 
  /// [noOfShares] shares will be produced during [encode]. If an encoded secret
  /// should be [decode]d, then [neededShares] shares are needed. The [charset]
  /// used by this codec is specified by [charset].
  StringShareCodec(int noOfShares, int neededShares, Charset charset, {Random random})
      : charset = charset,
        encoder = new StringShareEncoder(noOfShares, neededShares, charset,
            random: random),
        super(noOfShares, neededShares);
}
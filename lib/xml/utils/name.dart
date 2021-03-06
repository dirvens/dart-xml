part of xml;

const _SEPARATOR = ':';

const _XML = 'xml';
const _XML_URI = 'http://www.w3.org/XML/1998/namespace';
const _XMLNS = 'xmlns';


/**
 * XML entity name.
 */
abstract class XmlName extends Object with XmlWritable, XmlParent {

  /**
   * Return the namespace prefix, or `null`.
   */
  String get prefix;

  /**
   * Return the local name, excluding the namespace prefix.
   */
  String get local;

  /**
   * Return the fully qualified name, including the namespace prefix.
   */
  String get qualified;

  /**
   * Return the namespace URI, or `null`.
   */
  String get namespaceUri;

  /**
   * Creates a qualified [XmlName] from a `local` name and an optional `prefix`.
   */
  factory XmlName(String local, [String prefix]) {
    return prefix == null || prefix.isEmpty
        ? new _XmlSimpleName(local)
        : new _XmlPrefixName('$prefix$_SEPARATOR$local', local, prefix);
  }

  /**
   * Create a [XmlName] by parsing the provided `qualified` name.
   */
  factory XmlName.fromString(String qualified) {
    var index = qualified.indexOf(_SEPARATOR);
    if (index > 0) {
      var prefix = qualified.substring(0, index);
      var local = qualified.substring(index + 1, qualified.length);
      return new _XmlPrefixName(qualified, prefix, local);
    } else {
      return new _XmlSimpleName(qualified);
    }
  }

  XmlName._();

  @override
  void writeTo(StringBuffer buffer) => buffer.write(qualified);

  @override
  bool operator == (Object other) => other is XmlName
      && other.local == local
      && other.namespaceUri == namespaceUri;

  @override
  int get hashCode => local.hashCode;

}

/**
 * An XML entity name without a prefix.
 */
class _XmlSimpleName extends XmlName {

  @override
  String get qualified => local;

  @override
  String get prefix => null;

  @override
  final String local;

  _XmlSimpleName(this.local) : super._();

  @override
  String get namespaceUri {
    for (var node = parent; node != null; node = node.parent) {
      for (var attribute in node.attributes) {
        if (attribute.name.prefix == null && attribute.name.local == _XMLNS) {
          return attribute.value;
        }
      }
    }
    return null;
  }

}

/**
 * An XML entity name with a prefix.
 */
class _XmlPrefixName extends XmlName {

  @override
  final String qualified;

  @override
  final String prefix;

  @override
  final String local;

  _XmlPrefixName(this.qualified, this.prefix, this.local) : super._();

  @override
  String get namespaceUri {
    for (var node = parent; node != null; node = node.parent) {
      for (var attribute in node.attributes) {
        if (attribute.name.prefix == _XMLNS && attribute.name.local == prefix) {
          return attribute.value;
        }
      }
    }
    return null;
  }

}
part of xml;

/**
 * XML CDATA node.
 */
class XmlCDATA extends XmlData {

  /**
   * Create a CDATA section with `text`.
   */
  XmlCDATA(String text): super(text);

  @override
  XmlNodeType get nodeType => XmlNodeType.CDATA;

  @override
  void writeTo(StringBuffer buffer) {
    buffer.write('<![CDATA[');
    buffer.write(text);
    buffer.write(']]>');
  }

  @override
  void prettyWriteTo(StringBuffer buffer, {String indent, int indentLevel}) {
    _doPrettyIndent(buffer, indent, indentLevel);
    writeTo(buffer);
  }

}

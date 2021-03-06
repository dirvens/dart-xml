library xml_test;

import 'package:xml/xml.dart';
import 'package:unittest/unittest.dart';

import 'xml_examples.dart';

void validate(String input) {
  var tree = parse(input);
  assertTreeInvariants(tree);
  var copy = parse(tree.toString());
  expect(tree.toString(), copy.toString());
}

void assertTreeInvariants(XmlNode xml) {
  assertDocumentInvariant(xml);
  assertParentInvariant(xml);
  assertForwardInvariant(xml);
  assertBackwardInvariant(xml);
  assertNameInvariant(xml);
  assertAttributeInvariant(xml);
  assertTextInvariant(xml);
  assertIteratorInvariants(xml);
}

void assertDocumentInvariant(XmlNode xml) {
  var root = xml.root;
  for (var child in xml.descendants) {
    expect(root, same(child.root));
    expect(root, same(child.document));
  }
  var document = xml.document;
  expect(document.children, contains(document.rootElement));
  if (document.doctypeElement != null) {
    expect(document.children, contains(document.doctypeElement));
  }
}

void assertParentInvariant(XmlNode xml) {
  for (var node in xml.descendants) {
    expect(node.parent, node is XmlDocument ? isNull : isNotNull);
    for (var child in node.children) {
      expect(child.parent, same(node));
    }
    for (var attribute in node.attributes) {
      expect(attribute.parent, same(node));
    }
  }
}

void assertForwardInvariant(XmlNode xml) {
  for (var node in xml.descendants) {
    var current = node.firstChild;
    for (var i = 0; i < node.children.length; i++) {
      expect(node.children[i], same(current));
      current = current.nextSibling;
    }
    expect(current, isNull);
  }
}

void assertBackwardInvariant(XmlNode xml) {
  for (var node in xml.descendants) {
    var current = node.lastChild;
    for (var i = node.children.length - 1; i >= 0; i--) {
      expect(node.children[i], same(current));
      current = current.previousSibling;
    }
    expect(current, isNull);
  }
}

void assertNameInvariant(XmlNode xml) {
  for (var node in xml.descendants) {
    if (node is XmlElement) {
      var element = node;
      assertQualifiedInvariant(element.name);
    }
    if (node is XmlAttribute) {
      var attribute = node;
      assertQualifiedInvariant(attribute.name);
    }
  }
}

void assertQualifiedInvariant(XmlName name) {
  expect(name.local, isNot(isEmpty));
  expect(name.qualified, endsWith(name.local));
  if (name.prefix != null) {
    expect(name.qualified, startsWith(name.prefix));
  }
  expect(name.qualified, name.toString());
}

void assertAttributeInvariant(XmlNode xml) {
  for (var node in xml.descendants) {
    if (node is XmlElement) {
      var element = node;
      for (var attribute in element.attributes) {
        expect(attribute, same(element.getAttributeNode(attribute.name.qualified)));
        expect(attribute.value, same(element.getAttribute(attribute.name.qualified)));
      }
      if (element.attributes.isEmpty) {
        expect(element.getAttribute('foo'), isNull);
        expect(element.getAttributeNode('foo'), isNull);
      }
    }
  }
}

void assertTextInvariant(XmlNode xml) {
  for (var node in xml.descendants) {
    if (node is XmlDocument) {
      expect(node.text, isNull);
    } else {
      expect(node.text, (text) => text is String);
    }
  }
}

void assertIteratorInvariants(XmlNode xml) {
  var ancestors = new List();
  void check(XmlNode node) {
    var all_axis = [node.preceding, [node], node.descendants, node.following]
        .expand((each) => each);
    var all_root = [[node.root], node.root.descendants]
        .expand((each) => each);
    expect(all_axis, all_root, reason: 'All preceding nodes, the node, all decendant '
        'nodes, and all following nodes should be equal to all nodes in the tree.');
    expect(node.ancestors, ancestors.reversed);
    ancestors.add(node);
    node.attributes.forEach((each) => check(each));
    node.children.forEach((each) => check(each));
    ancestors.removeLast();
  }
  check(xml);
}

void main() {
  group('parsing', () {
    test('comment', () {
      validate('<?xml version="1.0" encoding="UTF-8"?>' '<schema><!-- comment --></schema>');
    });
    test('comment with xml', () {
      validate('<?xml version="1.0" encoding="UTF-8"?>' '<schema><!-- <foo></foo> --></schema>');
    });
    test('complicated', () {
      validate('<?xml foo?>\n' '<!DOCTYPE [ something ]>\n'
          '<ns:foo attr="not namespaced" n1:ans="namespaced 1" n2:ans="namespace 2" >\n' '  <element/>\n'
          '  <ns:element/>\n' '  <!-- comment -->\n' '  <![CDATA[cdata]]>\n' '  <?processing instruction?>\n'
          '</ns:foo>');
    });
    test('doctype', () {
      validate('<!DOCTYPE with <schema> [ <!-- schema --> ]>\n<schema />');
    });
    test('empty element', () {
      validate('<schema/>');
    });
    test('namespace', () {
      validate('<xs:schema xs:attr="1"></xs:schema>');
    });
    test('simple', () {
      validate('<schema></schema>');
    });
    test('simple double quote attribute', () {
      validate('<schema foo="bar"></schema>');
    });
    test('simple single quote attribute', () {
      validate('<schema foo=\'bar\'></schema>');
    });
    test('short cdata section', () {
      validate('<data><![CDATA[]]></data>');
    });
    test('short cdata section', () {
      validate('<data><![CDATA[<data></data>]]></data>');
    });
    test('short processing instruction', () {
      validate('<?xml?><data />');
    });
    test('long processing instruction', () {
      validate('<?xml version="1.0"?><data />');
    });
    test('whitespace after prolog', () {
      validate('<?xml version="1.0" encoding="UTF-8"?>\n\t<schema></schema>\t\n');
    });
  });
  group('nodes', () {
    test('element', () {
      XmlDocument document = parse('<ns:data>Am I or are the other crazy?</ns:data>');
      XmlElement node = document.rootElement;
      expect(node.name, new XmlName.fromString('ns:data'));
      expect(node.parent, same(document));
      expect(node.root, same(document));
      expect(node.document, same(document));
      expect(node.attributes, isEmpty);
      expect(node.children, hasLength(1));
      expect(node.descendants, hasLength(1));
      expect(node.text, 'Am I or are the other crazy?');
      expect(node.nodeType, XmlNodeType.ELEMENT);
      expect(node.toString(), '<ns:data>Am I or are the other crazy?</ns:data>');
    });
    test('attribute', () {
      XmlDocument document = parse('<data ns:attr="Am I or are the other crazy?" />');
      XmlAttribute node = document.rootElement.attributes.single;
      expect(node.name, new XmlName.fromString('ns:attr'));
      expect(node.value, 'Am I or are the other crazy?');
      expect(node.parent, same(document.rootElement));
      expect(node.root, same(document));
      expect(node.document, same(document));
      expect(node.attributes, isEmpty);
      expect(node.children, isEmpty);
      expect(node.descendants, isEmpty);
      expect(node.text, isEmpty);
      expect(node.nodeType, XmlNodeType.ATTRIBUTE);
      expect(node.toString(), 'ns:attr="Am I or are the other crazy?"');
    });
    test('attribute (character references)', () {
      XmlDocument document = parse('<data ns:attr="&lt;&gt;&amp;&apos;&quot;" />');
      XmlAttribute node = document.rootElement.attributes.single;
      expect(node.value, '<>&\'"');
      expect(node.toString(), 'ns:attr="<>&\'&quot;"');
    });
    test('text', () {
      XmlDocument document = parse('<data>Am I or are the other crazy?</data>');
      XmlText node = document.rootElement.children.single;
      expect(node.text, 'Am I or are the other crazy?');
      expect(node.parent, same(document.rootElement));
      expect(node.root, same(document));
      expect(node.document, same(document));
      expect(node.attributes, isEmpty);
      expect(node.children, isEmpty);
      expect(node.descendants, isEmpty);
      expect(node.nodeType, XmlNodeType.TEXT);
      expect(node.toString(), 'Am I or are the other crazy?');
    });
    test('text (character references)', () {
      XmlDocument document = parse('<data>&lt;&gt;&amp;&apos;&quot;</data>');
      XmlText node = document.rootElement.children.single;
      expect(node.text, '<>&\'"');
      expect(node.toString(), '&lt;>&amp;\'"');
    });
    test('text (nested)', () {
      XmlDocument root = parse('<p>Am <i>I</i> or are the <b>other</b><!-- very --> crazy?</p>');
      expect(root.rootElement.text, 'Am I or are the other crazy?');
    });
    test('cdata', () {
      XmlDocument document = parse('<data><![CDATA[Methinks <word> it <word> is like '
          'a weasel!]]></data>');
      XmlCDATA node = document.rootElement.children.single;
      expect(node.text, 'Methinks <word> it <word> is like a weasel!');
      expect(node.parent, same(document.rootElement));
      expect(node.root, same(document));
      expect(node.document, same(document));
      expect(node.attributes, isEmpty);
      expect(node.children, isEmpty);
      expect(node.nodeType, XmlNodeType.CDATA);
      expect(node.toString(), '<![CDATA[Methinks <word> it <word> is like a weasel!]]>');
      expect(node.descendants, isEmpty);
    });
    test('processing', () {
      XmlDocument document = parse('<?xml version="1.0"?><data/>');
      XmlProcessing node = document.firstChild;
      expect(node.target, 'xml');
      expect(node.text, 'version="1.0"');
      expect(node.parent, same(document));
      expect(node.root, same(document));
      expect(node.document, same(document));
      expect(node.attributes, isEmpty);
      expect(node.children, isEmpty);
      expect(node.nodeType, XmlNodeType.PROCESSING);
      expect(node.toString(), '<?xml version="1.0"?>');
      expect(node.descendants, isEmpty);
    });
    test('comment', () {
      XmlDocument document = parse('<data><!--Am I or are the other crazy?--></data>');
      XmlComment node = document.rootElement.children.single;
      expect(node.parent, same(document.rootElement));
      expect(node.root, same(document));
      expect(node.document, same(document));
      expect(node.attributes, isEmpty);
      expect(node.children, isEmpty);
      expect(node.descendants, isEmpty);
      expect(node.text, 'Am I or are the other crazy?');
      expect(node.nodeType, XmlNodeType.COMMENT);
      expect(node.toString(), '<!--Am I or are the other crazy?-->');
    });
    test('document', () {
      XmlDocument document = parse('<data />');
      XmlDocument node = document.document;
      expect(node.parent, isNull);
      expect(node.root, same(document));
      expect(node.document, same(document));
      expect(node.attributes, isEmpty);
      expect(node.children, hasLength(1));
      expect(node.descendants, hasLength(1));
      expect(node.text, isNull);
      expect(node.nodeType, XmlNodeType.DOCUMENT);
      expect(node.toString(), '<data />');
    });
    test('document type', () {
      XmlDocument document = parse('<!DOCTYPE html [<!-- internal subset -->]><data />');
      XmlDoctype node = document.doctypeElement;
      expect(node.parent, same(document));
      expect(node.document, same(document));
      expect(node.attributes, isEmpty);
      expect(node.children, isEmpty);
      expect(node.descendants, isEmpty);
      expect(node.text, 'html [<!-- internal subset -->]');
      expect(node.nodeType, XmlNodeType.DOCUMENT_TYPE);
      expect(node.toString(), '<!DOCTYPE html [<!-- internal subset -->]>');
    });
  });
  group('namespaces', () {
    test('default namespace', () {
      XmlDocument document = parse(
          '<html xmlns="http://www.w3.org/1999/xhtml">'
          '  <body lang="en"/>'
          '</html>');
      List<XmlNode> nodes = new List.from(document.descendants)..add(document);
      nodes.forEach((node) {
        if (node is XmlAttribute || node is XmlElement) {
          expect(node.name.namespaceUri, 'http://www.w3.org/1999/xhtml');
        }
      });
    });
    test('prefix namespace', () {
      XmlDocument document = parse(
          '<xhtml:html xmlns:xhtml="http://www.w3.org/1999/xhtml">'
          '  <xhtml:body xhtml:lang="en"/>'
          '</xhtml:html>');
      List<XmlNode> nodes = new List.from(document.descendants)..add(document);
      nodes.forEach((node) {
        if ((node is XmlAttribute && node.name.prefix != 'xmlns') || (node is XmlElement)) {
          expect(node.name.namespaceUri, 'http://www.w3.org/1999/xhtml');
        }
      });
    });
  });
  group('entities', () {
    String decode(String input) => parse('<data>$input</data>').rootElement.text;
    String encodeText(String input) => new XmlText(input).toString();
    String encodeAttributeValue(String input) {
      var attribute = new XmlAttribute(new XmlName('a'), input).toString();
      return attribute.substring(3, attribute.length - 1);
    }
    test('decode &#xHHHH;', () {
      expect(decode('&#X41;'), 'A');
      expect(decode('&#x61;'), 'a');
      expect(decode('&#x7A;'), 'z');
    });
    test('decode &#dddd;', () {
      expect(decode('&#65;'), 'A');
      expect(decode('&#97;'), 'a');
      expect(decode('&#122;'), 'z');
    });
    test('decode &named;', () {
      expect(decode('&lt;'), '<');
      expect(decode('&gt;'), '>');
      expect(decode('&amp;'), '&');
      expect(decode('&apos;'), '\'');
      expect(decode('&quot;'), '"');
    });
    test('encode text', () {
      expect(encodeText('<'), '&lt;');
      expect(encodeText('&'), '&amp;');
      expect(encodeText('hello'), 'hello');
      expect(encodeText('<foo &amp;>'), '&lt;foo &amp;amp;>');
    });
    test('encode attribute', () {
      expect(encodeAttributeValue('"'), '&quot;');
      expect(encodeAttributeValue('hello'), 'hello');
      expect(encodeAttributeValue('"hello"'), '&quot;hello&quot;');
    });
  });
  group('axis', () {
    var bookXml = '<book><title lang="en" price="12.00">XML</title><description/></book>';
    var book = parse(bookXml);
    test('ancestors', () {
      expect(book.ancestors, []);
      expect(book.children[0].ancestors, [
          book]);
      expect(book.children[0].children[0].ancestors, [
          book.children[0],
          book]);
      expect(book.children[0].children[0].attributes[0].ancestors, [
          book.children[0].children[0],
          book.children[0],
          book]);
      expect(book.children[0].children[0].attributes[1].ancestors, [
          book.children[0].children[0],
          book.children[0],
          book]);
      expect(book.children[0].children[0].children[0].ancestors, [
          book.children[0].children[0],
          book.children[0],
          book]);
      expect(book.children[0].children[1].ancestors, [
          book.children[0],
          book]);
    });
    test('preceding', () {
      expect(book.preceding, []);
      expect(book.children[0].preceding, [
          book]);
      expect(book.children[0].children[0].preceding, [
          book,
          book.children[0]]);
      expect(book.children[0].children[0].attributes[0].preceding, [
          book,
          book.children[0],
          book.children[0].children[0]]);
      expect(book.children[0].children[0].attributes[1].preceding, [
          book,
          book.children[0],
          book.children[0].children[0],
          book.children[0].children[0].attributes[0]]);
      expect(book.children[0].children[0].children[0].preceding, [
          book,
          book.children[0],
          book.children[0].children[0],
          book.children[0].children[0].attributes[0],
          book.children[0].children[0].attributes[1]]);
      expect(book.children[0].children[1].preceding, [
          book,
          book.children[0],
          book.children[0].children[0],
          book.children[0].children[0].attributes[0],
          book.children[0].children[0].attributes[1],
          book.children[0].children[0].children[0]]);
    });
    test('descendants', () {
      expect(book.descendants, [
          book.children[0],
          book.children[0].children[0],
          book.children[0].children[0].attributes[0],
          book.children[0].children[0].attributes[1],
          book.children[0].children[0].children[0],
          book.children[0].children[1]]);
      expect(book.children[0].descendants, [
          book.children[0].children[0],
          book.children[0].children[0].attributes[0],
          book.children[0].children[0].attributes[1],
          book.children[0].children[0].children[0],
          book.children[0].children[1]]);
      expect(book.children[0].children[0].descendants, [
          book.children[0].children[0].attributes[0],
          book.children[0].children[0].attributes[1],
          book.children[0].children[0].children[0]]);
      expect(book.children[0].children[0].attributes[0].descendants, []);
      expect(book.children[0].children[0].attributes[1].descendants, []);
      expect(book.children[0].children[0].children[0].descendants, []);
      expect(book.children[0].children[1].descendants, []);
    });
    test('following', () {
      expect(book.following, []);
      expect(book.children[0].following, []);
      expect(book.children[0].children[0].following, [
          book.children[0].children[1]]);
      expect(book.children[0].children[0].attributes[0].following, [
          book.children[0].children[0].attributes[1],
          book.children[0].children[0].children[0],
          book.children[0].children[1]]);
      expect(book.children[0].children[0].attributes[1].following, [
          book.children[0].children[0].children[0],
          book.children[0].children[1]]);
      expect(book.children[0].children[0].children[0].following, [
          book.children[0].children[1]]);
      expect(book.children[0].children[1].following, []);
    });
  });
  group('querying all elements', () {
    var bookstore = parse(bookstoreXml);
    var shiporder = parse(shiporderXsd);
    var xsd = 'http://www.w3.org/2001/XMLSchema';
    test('name defined, namespace undefined', () {
      var books = bookstore.findAllElements('book');
      expect(books.length, 2);
      var orders = shiporder.findAllElements('element');
      expect(orders.length, 0);
    });
    test('name defined, namespace wildcard', () {
      var books = bookstore.findAllElements('book', namespace: '*');
      expect(books.length, 2);
      var orders = shiporder.findAllElements('element', namespace: '*');
      expect(orders.length, 17);
    });
    test('name defined, namespace defined', () {
      var books = bookstore.findAllElements('book', namespace: xsd);
      expect(books.length, 0);
      var orders = shiporder.findAllElements('element', namespace: xsd);
      expect(orders.length, 17);
    });
    test('name wildcard, namespace undefined', () {
      var books = bookstore.findAllElements('*');
      expect(books.length, 7);
      var orders = shiporder.findAllElements('*');
      expect(orders.length, 37);
    });
    test('name wildcard, namespace wildcard', () {
      var books = bookstore.findAllElements('*', namespace: '*');
      expect(books.length, 7);
      var orders = shiporder.findAllElements('*', namespace: '*');
      expect(orders.length, 37);
    });
    test('name wildcard, namespace defined', () {
      var books = bookstore.findAllElements('*', namespace: xsd);
      expect(books.length, 0);
      var orders = shiporder.findAllElements('*', namespace: xsd);
      expect(orders.length, 37);
    });
  });
  group('builder', () {
    test('basic', () {
      var builder = new XmlBuilder();
      builder.processing('xml', 'encoding="UTF-8"');
      builder.element('bookstore', nest: () {
        builder.comment('Only one book?');
        builder.element('book', nest: () {
          builder.element('title', nest: () {
            builder.attribute('lang', 'en');
            builder.text('Harry ');
            builder.cdata('Potter');
          });
          builder.element('price', nest: 29.99);
          builder.element('special');
        });
      });
      var actual = builder.build().toString();
      var expected =
          '<?xml encoding="UTF-8"?>'
          '<bookstore>'
            '<!--Only one book?-->'
            '<book>'
              '<title lang="en">Harry <![CDATA[Potter]]></title>'
              '<price>29.99</price>'
              '<special />'
            '</book>'
          '</bookstore>';
      expect(actual, expected);
    });
    test('namespace binding', () {
      var uri = 'http://www.w3.org/2001/XMLSchema';
      var builder = new XmlBuilder();
      builder.element('schema', nest: () {
        builder.namespace(uri, 'xsd');
        builder.attribute('lang', 'en', namespace: uri);
        builder.element('element', namespace: uri);
      }, namespace: uri);
      var actual = builder.build().toString();
      var expected =
          '<xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema" xsd:lang="en">'
            '<xsd:element />'
          '</xsd:schema>';
      expect(actual, expected);
    });
    test('default namespace binding', () {
      var uri = 'http://www.w3.org/2001/XMLSchema';
      var builder = new XmlBuilder();
      builder.element('schema', nest: () {
        builder.namespace(uri);
        builder.attribute('lang', 'en', namespace: uri);
        builder.element('element', namespace: uri);
      }, namespace: uri);
      var actual = builder.build().toString();
      var expected =
          '<schema xmlns="http://www.w3.org/2001/XMLSchema" lang="en">'
            '<element />'
          '</schema>';
      expect(actual, expected);
    });
  });
  group('examples', () {
    test('books', () {
      validate(booksXml);
    });
    test('bookstore', () {
      validate(bookstoreXml);
    });
    test('atom', () {
      validate(atomXml);
    });
    test('shiporder', () {
      validate(shiporderXsd);
    });
  });
}

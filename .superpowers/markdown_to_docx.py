import re
import zipfile
from pathlib import Path
from datetime import datetime, UTC
from xml.sax.saxutils import escape

src = Path(r'docs/superpowers/specs/2026-05-04-bondy-parallel-feature-backlog-design.md')
out = src.with_suffix('.docx')

text = src.read_text(encoding='utf-8')
lines = text.splitlines()

content_types = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>'''

rels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>'''

doc_rels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"/>'''

styles = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:sz w:val="22"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Title"><w:name w:val="Title"/><w:basedOn w:val="Normal"/><w:pPr><w:spacing w:after="240"/></w:pPr><w:rPr><w:b/><w:sz w:val="36"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/><w:basedOn w:val="Normal"/><w:pPr><w:spacing w:before="360" w:after="160"/><w:outlineLvl w:val="0"/></w:pPr><w:rPr><w:b/><w:sz w:val="32"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Heading2"><w:name w:val="heading 2"/><w:basedOn w:val="Normal"/><w:pPr><w:spacing w:before="280" w:after="120"/><w:outlineLvl w:val="1"/></w:pPr><w:rPr><w:b/><w:sz w:val="28"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Heading3"><w:name w:val="heading 3"/><w:basedOn w:val="Normal"/><w:pPr><w:spacing w:before="220" w:after="100"/><w:outlineLvl w:val="2"/></w:pPr><w:rPr><w:b/><w:sz w:val="24"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Code"><w:name w:val="Code"/><w:basedOn w:val="Normal"/><w:pPr><w:shd w:fill="F3F4F6"/><w:spacing w:before="80" w:after="80"/></w:pPr><w:rPr><w:rFonts w:ascii="Consolas" w:hAnsi="Consolas"/><w:sz w:val="19"/></w:rPr></w:style>
</w:styles>'''

now = datetime.now(UTC).replace(microsecond=0).isoformat().replace('+00:00', 'Z')
core = f'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:title>BONDY – DESIGN DOC BACKLOG PHÂN CHIA SONG SONG CHO 5 DEV</dc:title>
  <dc:creator>Antigravity</dc:creator>
  <cp:lastModifiedBy>Antigravity</cp:lastModifiedBy>
  <dcterms:created xsi:type="dcterms:W3CDTF">{now}</dcterms:created>
  <dcterms:modified xsi:type="dcterms:W3CDTF">{now}</dcterms:modified>
</cp:coreProperties>'''

app = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes"><Application>Antigravity</Application></Properties>'''


def runs_from_inline(s, code=False):
    s = re.sub(r'\*\*(.*?)\*\*', r'\1', s)
    s = s.replace('`', '')
    font = '<w:rFonts w:ascii="Consolas" w:hAnsi="Consolas"/>' if code else ''
    return f'<w:r><w:rPr>{font}</w:rPr><w:t xml:space="preserve">{escape(s)}</w:t></w:r>'


def para(s='', style=None, code=False, bullet=False):
    ppr = ''
    if style:
        ppr += f'<w:pStyle w:val="{style}"/>'
    if bullet:
        ppr += '<w:ind w:left="720" w:hanging="360"/>'
    if code and not style:
        ppr += '<w:pStyle w:val="Code"/>'
    prefix = '• ' if bullet else ''
    return f'<w:p><w:pPr>{ppr}</w:pPr>{runs_from_inline(prefix + s, code=code)}</w:p>'


def table(rows):
    xml = ['<w:tbl><w:tblPr><w:tblW w:w="0" w:type="auto"/><w:tblBorders><w:top w:val="single" w:sz="4"/><w:left w:val="single" w:sz="4"/><w:bottom w:val="single" w:sz="4"/><w:right w:val="single" w:sz="4"/><w:insideH w:val="single" w:sz="4"/><w:insideV w:val="single" w:sz="4"/></w:tblBorders></w:tblPr>']
    for row in rows:
        xml.append('<w:tr>')
        for cell in row:
            xml.append(f'<w:tc><w:tcPr><w:tcW w:w="2400" w:type="dxa"/></w:tcPr>{para(cell)}</w:tc>')
        xml.append('</w:tr>')
    xml.append('</w:tbl>')
    return ''.join(xml)

body = []
in_code = False
code_buffer = []
table_buffer = []


def flush_table():
    global table_buffer
    if len(table_buffer) >= 2:
        rows = []
        for tr in table_buffer:
            cells = [c.strip() for c in tr.strip().strip('|').split('|')]
            if all(re.fullmatch(r':?-{3,}:?', c or '') for c in cells):
                continue
            rows.append(cells)
        if rows:
            body.append(table(rows))
    table_buffer = []


def flush_code():
    global code_buffer
    for c in code_buffer:
        body.append(para(c, code=True))
    code_buffer = []

for line in lines:
    if line.startswith('```'):
        flush_table()
        if in_code:
            flush_code()
            in_code = False
        else:
            in_code = True
        continue

    if in_code:
        code_buffer.append(line)
        continue

    if line.strip().startswith('|') and line.strip().endswith('|'):
        table_buffer.append(line)
        continue
    else:
        flush_table()

    stripped = line.strip()
    if stripped == '---':
        body.append('<w:p><w:r><w:br w:type="page"/></w:r></w:p>')
    elif stripped.startswith('# '):
        body.append(para(stripped[2:].strip(), 'Title'))
    elif stripped.startswith('## '):
        body.append(para(stripped[3:].strip(), 'Heading1'))
    elif stripped.startswith('### '):
        body.append(para(stripped[4:].strip(), 'Heading2'))
    elif stripped.startswith('#### '):
        body.append(para(stripped[5:].strip(), 'Heading3'))
    elif stripped.startswith('- '):
        body.append(para(stripped[2:].strip(), bullet=True))
    elif stripped == '':
        body.append(para(''))
    else:
        body.append(para(stripped))

flush_table()
if in_code:
    flush_code()

section = '<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440"/></w:sectPr>'
document = f'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>{''.join(body)}{section}</w:body></w:document>'''

with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as z:
    z.writestr('[Content_Types].xml', content_types)
    z.writestr('_rels/.rels', rels)
    z.writestr('word/document.xml', document)
    z.writestr('word/_rels/document.xml.rels', doc_rels)
    z.writestr('word/styles.xml', styles)
    z.writestr('docProps/core.xml', core)
    z.writestr('docProps/app.xml', app)

print(out)

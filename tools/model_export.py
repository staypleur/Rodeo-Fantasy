"""Export a standalone Roblox model with all of its serialized dependencies."""
import copy
import xml.etree.ElementTree as E

def validate_model(document):
    items=list(document.iter('Item'))
    ids={item.get('referent') for item in items}
    assert len(ids)==len(items), 'Duplicate instance references'
    for item in items:
        assert item.get('class') not in ('Script','LocalScript','ModuleScript'), 'Model contains code'
        for ref in item.findall('Properties/Ref'):
            assert ref.text in ids or ref.text=='null', 'Missing instance dependency'
    entries=document.findall('SharedStrings/SharedString')
    shared={entry.get('md5') for entry in entries}
    assert len(shared)==len(entries), 'Duplicate shared-string entries'
    for item in items:
        for ref in item.findall('Properties/SharedString'):
            assert ref.text in shared, 'Missing serialized shared-string dependency: '+str(ref.get('name'))

def export_model(source,model,name):
    detail=copy.deepcopy(model)
    detail.find("Properties/string[@name='Name']").text=name
    document=E.Element('roblox',{'version':'4'})
    E.SubElement(document,'External').text='null'
    E.SubElement(document,'External').text='nil'
    document.append(detail)
    needed={ref.text for item in detail.iter('Item') for ref in item.findall('Properties/SharedString')}
    saved={entry.get('md5'):entry for entry in source.findall('SharedStrings/SharedString')}
    if needed:
        table=E.SubElement(document,'SharedStrings')
        for key in sorted(needed):
            assert key in saved, 'Missing dependency in source model'
            table.append(copy.deepcopy(saved[key]))
    validate_model(document)
    return document

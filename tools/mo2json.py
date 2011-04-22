#!/usr/bin/python
from gettext import GNUTranslations
import json
import re

def mo_to_no(mofile):
    translations = GNUTranslations(mofile)

    info = translations._info
    catalog = translations._catalog

    numplurals_m = re.match(r"\s*nplurals\s*=\s*(\d+)", info['plural-forms'])
    if not numplurals_m or not numplurals_m:
        fn = "<unknown file>"
        if hasattr(mofile, 'name'):
            fn = "file " + mofile.name
        raise Error("No plural-forms or nplurals in message catalog info in %s" % fn)

    numplurals = int(numplurals_m.group(1))
    info['nplurals'] = numplurals

    newcatalog = { }
    for msgid, trans in catalog.iteritems():
        if isinstance(msgid, tuple):
            forms = newcatalog.setdefault(msgid[0], [ None ] * numplurals)
            try:
                forms[msgid[1]] = trans
            except:
                print "Broken translation: ", msgid
        else:
            newcatalog[msgid] = trans

    return '{ "info": %s, "catalog": %s }\n' % (json.dumps(info, ensure_ascii=False, indent=0), json.dumps(newcatalog, ensure_ascii=False, indent=0))

if __name__ == "__main__":
    import sys
    if len(sys.argv) != 3:
        print >> sys.stderr, "Usage: mo_to_no mofile nofile"
        sys.exit(1)

    compiled = mo_to_no(file(sys.argv[1], "rb"))
    jsonout = open(sys.argv[2], "w")
    jsonout.write(compiled.encode('UTF-8'))
    jsonout.close()

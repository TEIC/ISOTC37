![validate_examples](https://github.com/TEIC/ISOTC37/workflows/validate_MAF_examples/badge.svg?event=push)
# MAF Core (ISO 24611-1)

The documents in this repository present the ongoing work on the TEI serialization of MAF (Morphosyntactic Annotation Framework, [ISO 24611](https://www.iso.org/standard/51934.html)). So far, only MAF Core (part 1 of the MAF family) is represented here.


* MAFinTEI.odd is the TEI ODD file, from which both the documentation and the schemas are derived.
* MAFinTEI.html is the documentation of the ODD
* MAFinTEI.rng is the RELAX NG schema, used by the example document
* MAFinTEI-examples.xml is a test application of the ODD as well as a demo.

The etc/ directory contains the current snapshot of the TEI Guidelines that the MAFinTEI.odd 
is compiled against. This is because it depends on some bleeding edge features that are
not yet officially released.


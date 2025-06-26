# MAF Core (ISO 24611-1)

![validate_examples](https://github.com/TEIC/ISOTC37/workflows/validate_MAF_examples/badge.svg?event=push)

The documents in this repository present the ongoing work on the TEI serialization of MAF (Morphosyntactic 
Annotation Framework, [ISO 24611](https://www.iso.org/standard/51934.html)). So far, only MAF Core (part 1 of 
the MAF family) is represented here.

Please use issues to submit ideas, bug reports, etc. Contribution to the tools section and examples of 
implementations are very welcome.

MAF-1 is meant to be an add-on to a stable customisation. Not a fully neutral add-on, because it modifies 
some of the native TEI elements, but does it in a way that is transparent, so appropriate decisions 
regarding the original resource can be made. (Modifying MAF element/attribute definitions to adjust 
them to the resource that is about to be enriched is also a possibility, given the levels of 
conformance that the standard defines -- one may simply aim for algorithmic conformance, rather than using pure MAF). 

## Contents of this directory

### Files:

* MAF-1.odd is the TEI ODD file from which both the documentation and the schemas are derived.
* MAF-1.html is the documentation of the ODD
* MAF-1.rng is the RELAX NG schema, used by the example document
* MAF-1_examples.xml is a test application of the ODD to TEI Bare, as well as a demo.

### Subdirectories

* base/ holds files necessary to derive the MAF documentation and the MAF schema on the basis of 
* TEI Bare, by means of ODD chaining
* doc/ holds documentation of various sorts
* etc/ holds additional files (example tool output, etc.)
* tools/ stores tools, e.g. converting UD representations to MAF

## MAF-1 Conformance levels

Conformance of an annotation scheme with MAF is primarily conditioned on sharing the same
data model.

An annotation scheme qualifies as **fully conformant** with ISO MAF Core iff:

- it follows the data model defined by ISO 24611-1; and
- its serialization is valid with respect to the RELAX NG schema (RNG, RNC) or
the XML Schema (XSD) defined by the MAF-1.odd ODD document.

An annotation scheme qualifies as **algorithmically conformant** with ISO MAF iff all the following items
are true:

- the annotation scheme in question follows the data model defined by this document; and
- its serialization format can be translated into a format that is valid with respect to the Relax NG
schema (RNG, RNC) or the XML Schema (XSD) defined by the MAF-1.odd; and
- a translation tool to the ISO MAF serialization is provided and potential differences in information
content of the two serialization formats are documented.


Algorithmic conformance can involve information loss. This is why documentation is a crucial condition
for claiming algorithmic conformance with ISO MAF.

The term “**shallow conformance with ISO MAF**” is used for cases where the underlying data model of an
annotation scheme differs from the data model defined by this document and yet its serialization is
directly or indirectly valid with respect to the Relax NG schema (RNG, RNC) or the XML Schema (XSD)
defined by the MAF-1.odd ODD document. 

Additional conformance constrants that follow from the normative part of the standard:

The word-form component of the MAF metamodel should be implemented by means of a `<span>`
element, subject to the following constraints:
- `<span>` elements can be grouped together within one or more `<spanGrp>` elements;
- the `<span>` element shall have a corresponding @type attribute with value “wordform”; this @type
attribute can be moved to the nesting `<spanGrp>` element when applicable;
- the `@target` attribute should contain the list of URIs which reference the tokens that the word-form
is associated with;
- the `@lemmaRef` attribute can be used to point to a lexical entry (or a subpart of an entry);
- the `@ana` attribute can be used to point to a feature structure (or a feature-value library entry, see
below) that provides the morphosyntactic content of the word-form.


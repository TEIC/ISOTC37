# Base files for ODD chaining

This directory contains base files for creating the environment for 'attaching' MAF 
on top of an existing TEI customisation, on the example of TEI Bare. 

This is done by a process called "chaining", whereby the MAF ODD is processed 
against the set of definitions that belong to the base customisation, effectively 
creating a second cycle of ODD processing.

The files present in this directory are the following:

- p5subset.xml -- the entire set of TEI P5 definitions
- p5subset_DDMMYYYY.xml -- date-stamped copy of p5subset.xml
- tei_bare.odd -- the ODD file defining the TEI Bare customisation
- tei_bare-subset.xml -- the subset of p5subset.xml that is the product of processing tei_bare.odd against p5subset.xml
- tei_bare-subset_DDMMYYYY.xml -- date-stamped copy of tei_bare-subset.xml


The file p5subset.xml can be obtained at https://jenkins.tei-c.org/job/TEIP5-dev/lastSuccessfulBuild/artifact/P5/release/xml/tei/odd/p5subset.xml 
(it makes sense to check the current status of the dev build at https://jenkins.tei-c.org/job/TEIP5-dev/ -- for whether a new build is being processed, 
after which the p5subset.xml at the link above may get modified). 

The date-stamped versions are an attempt to keep versioning reasonably explicit and to keep the metadata as close to the data as possible (rather than 
expecting a regular modification of this very README document).

The tei_bare.odd is a copy of https://jenkins.tei-c.org/job/TEIP5-dev/lastSuccessfulBuild/artifact/P5/release/xml/tei/Exemplars/tei_bare.odd (no changes intended -- this is just an example)

## Deriving the subset for chaining

The tei_bare-subset.xml is derived by applying the following command, in this (MAF/base) directory:

   `teitoodd --localsource=p5subset.xml tei_bare.odd tei_bare-subset.xml`
   
Then, a date-stamped copy of the derived subset should be created, just in case it later turns out that, for some reason, 
we might want to go back to it. There is no special preservation strategy in the case of date-stamped versions (they are under
version control, after all).

The command assumes that the current version of [Stylesheets](https://github.com/TEIC/Stylesheets) is compiled and installed. Note that 
this is a slight reproducibility trap, because we do not explicitly track the precise version of the Stylesheets used for 
compiling tei_bare-subset.xml . That is, apparently, not indicated at the top of tei_bare-subset.xml, although one would imagine that
this kind of information should be present in the header of the derived document. (Perhaps it is -- if you know, where, please let us know.)

### Chaining

The "normal" way to derive a schema (and also documentation) is to apply the ODD document to the p5subset (in a way not visible to 
the end user; the p5subset is, practically, the embodiment of what is meant by "the TEI Guidelines", in processing terms). In chaining
scenarios, instead of the p5subset, we use a different (usually smaller) set of definitions. In the proof-of-concept application presented 
here, we use the subset created in the previous step, i.e., the TEI Bare set of definitions.

Thus, the "normal" way to manually create the TEI Bare RNG schema would be to do

   `teitorng --localsource=p5subset.xml tei_bare.odd tei_bare.rng`
   
-- except that is done under the hood, by Roma or equivalents.

In order to create the MAF schema as an add-on to 



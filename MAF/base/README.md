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

The tei_bare-subset.xml is derived by applying the following command:

   `teitoodd --localsource=p5subset.xml tei_bare.odd tei_bare-subset.xml`


The command assumes that the current version of [Stylesheets](https://github.com/TEIC/Stylesheets) is compiled and installed. Note that 
this is a slight reproducibility trap, because we do not explicitly track the precise version of the Stylesheets used for 
compiling tei_bare-subset.xml . That should be indicated automatically at the top of tei_bare-subset.xml -- in case an investigation is needed.

Note: in June 2025, there is an issue that requires manual intervention. It is summarised and can be traced at https://github.com/TEIC/Stylesheets/issues/759 .
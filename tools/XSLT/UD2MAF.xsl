<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:f="func"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs xd f map tei"
    version="3.0"
    expand-text="yes">
    
    <xsl:output encoding="UTF-8" method="xml" indent="yes"/>
    
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> May 23rd, 2020</xd:p>
            <xd:p><xd:b>Author:</xd:b>Piotr Banski</xd:p>
            <xd:p>Parse UD files into ISO MAF XML structures</xd:p>
            <xd:p>The current form of this script is a proof-of-concept prepared for the June 2020
                ISO Conference, to demonstrate how the ISO MAF standard can be used to describe data
                encoded in the Universal Dependencies format.</xd:p>
            <xd:p>Many routines below are redundant and sometimes even seem kludgy, but this is not
                the production form of this script yet.</xd:p>
        </xd:desc>
    </xd:doc>

<!--for sequential encoding where two values (XPOS and UPOS) need to be squeezed into a single attribute value
the corresponding typing is: @type="wordForm" @n="UPOS:XPOS"-->
    <xsl:param name="pos_separator" select="':'" as="xs:string"/>

    <xsl:variable name="TAB" select="'&#9;'" as="xs:string"/>

    <xsl:variable name="CONLLU" select="('ID','FORM','LEMMA','UPOS','XPOS','FEATS','HEAD','DEPREL','DEPS','MISC')" as="xs:string+"/>
    
    <xsl:variable name="unknown_id_pref" select="'unk_'" as="xs:string"/>

    <!--the following two utility variables, together with the constants above, are just a nod towards the potential later extension of this tool-->
    <xsl:variable name="columns" select="$CONLLU" as="xs:string+"/>
<!--    <xsl:variable name="columns" select="($CONLLU, 'excluded_by')" as="xs:string+"/>-->
    <xsl:variable name="value_separator" select="$TAB" as="xs:string"/>
    
    <xd:doc>
        <xd:desc>
            <xd:p>This variable holds the entire corpus in a map indexed by sentence position, the
                value being a sequence of lines (comments + annotations). This is simply an entry
                point for further processing.</xd:p>
            <xd:p>Note that this variable is indexed with the position in the original grouping,
                where the separator between sentences is also counted; but in both the dependent
                variables ($metadata_map and $annotation_map), values are indexed by the position()
                in this variable (so, effectively, 3 here becomes 2 there, because 2 here is the
                separator, which we don't need for further processing).</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:variable name="corpus_map" as="map(xs:integer, xs:string+)">
        <xsl:map>
            <xsl:for-each-group select="unparsed-text-lines('../../etc/UD2MAF_sample_input-2020-06-24.conllu')" group-adjacent="not(. eq '')">
                <xsl:choose>
                    <xsl:when test="current-grouping-key()">
                        <xsl:map-entry key="position()" select="current-group()"></xsl:map-entry>
                        <!--  -->
                    </xsl:when>
                </xsl:choose>
            </xsl:for-each-group>
        </xsl:map>
    </xsl:variable>
    
    <xd:doc>
        <xd:desc><xd:p>This variable holds only attribute-value pairs, indexed by the position in the
            $corpus_map. If a comment does not contain a '=' sign, it will not make it into here,
            unless it is "newpar" or "newdoc", which are promoted to key status, with the value of
            "'1'".</xd:p>
        <xd:p>In other words, <xd:i>#newpar</xd:i> alone in the line yields 
                <xd:i>'newpar':'1'</xd:i>.</xd:p>
            <xd:p>On the other hand,  <xd:i>#newpar = my_id-34</xd:i> yields two pairs: <xd:i>'newpar': 'id'</xd:i> and <xd:i>'newpar_id': 'my_id-34'</xd:i></xd:p>
            
            <xd:p>Sample structure:
                <xd:pre>map{
1:map{"newpar":"1","newdoc_id":"dump-compars-deu.txt","sent_id":"deu-ab1seg1","text":"Der Dinosaurier ist ausgestorben.","newdoc":"id"},
2:map{"sent_id":"deu-ab15seg2","text":"Genau das hat sie gesagt."},
3:map{"newpar":"id","sent_id":"deu-ab64seg1","text":"Ein kleiner Junge versichert: ich habe ebenso viele Brüder wie Schwestern.","newpar_id":"test_par_id-2"},
4:map{"sent_id":"deu-ab64seg2","text":"Seine Schwester antwortet: ich habe zweimal mehr Brüder als Schwestern."},
5:map{"newpar":"1","text":"Ich habe mich im Winter in dich verliebt."}}</xd:pre></xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:variable name="metadata_map" as="map(xs:integer,map(xs:string, xs:string))">
        <xsl:map>
            <xsl:for-each select="map:keys($corpus_map)">
                <xsl:map-entry key="position()">
                    <xsl:map>
                        <xsl:for-each select="$corpus_map(.)">
                            <xsl:choose>
                                <xsl:when test="matches(., '^#\s*newpar(\s|$)','i')">
                                    <xsl:choose>
                                        <xsl:when test="matches(., 'newpar\s+id\s*=','i')">
                                            <xsl:map-entry key="'newpar'" select="'id'"/>
                                            <xsl:map-entry key="'newpar_id'" select="tokenize(.,' ')[last()]"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:map-entry key="'newpar'" select="'1'"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:when>
                                <xsl:when test="matches(., '^#\s*newdoc(\s|$)','i')">
                                    <xsl:choose>
                                        <xsl:when test="matches(., 'newdoc\s+id\s*=','i')">
                                            <xsl:map-entry key="'newdoc'" select="'id'"/>
                                            <xsl:map-entry key="'newdoc_id'" select="tokenize(.,' ')[last()]"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:map-entry key="'newdoc'" select="'1'"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:when>
                                <xsl:when test="matches(.,'^#.*?=.*')">
                                    <xsl:variable name="avm_seq" select="tokenize(.,' ')"/>
<!-- assuming that the '=' sign is always surrounded by whitespace; if not, consider replace() followed by normalize-space() before tokenization  -->
                                    <xsl:variable name="eq_pos" select="index-of($avm_seq,'=')"/>
                                    <xsl:map-entry key="$avm_seq[$eq_pos - 1]"
                                        select="string-join(subsequence($avm_seq, $eq_pos + 1),' ')"/>
                                </xsl:when>
                            </xsl:choose>
                        </xsl:for-each>
                    </xsl:map>
                </xsl:map-entry>
            </xsl:for-each>
        </xsl:map>
    </xsl:variable>
<xd:doc>
    <xd:p>Sample structure:
        <xd:pre>map{
...
5:map{
    1:map{"HEAD":"_","FEATS":"Case=Nom|Number=Sing|Person=1|PronType=Prs","FORM":"Ich","DEPS":"_","LEMMA":"ich","DEPREL":"_","MISC":"_","ID":"1","XPOS":"PPER","UPOS":"PRON"},
    2:map{"HEAD":"_","FEATS":"Mood=Ind|Number=Sing|Person=1|Tense=Pres|VerbForm=Fin","FORM":"habe","DEPS":"_","LEMMA":"haben","DEPREL":"_","MISC":"_","ID":"2","XPOS":"VAFIN","UPOS":"AUX"},
    3:map{"HEAD":"_","FEATS":"Case=Acc|Number=Sing|Person=1|PronType=Prs|Reflex=Yes","FORM":"mich","DEPS":"_","LEMMA":"ich","DEPREL":"_","MISC":"_","ID":"3","XPOS":"PRF","UPOS":"PRON"},
    4:map{"HEAD":"_","FEATS":"_","FORM":"im","DEPS":"_","LEMMA":"_","DEPREL":"_","MISC":"_","ID":"4-5","XPOS":"_","UPOS":"_"},
    5:map{"HEAD":"_","FEATS":"_","FORM":"in","DEPS":"_","LEMMA":"in","DEPREL":"_","MISC":"_","excluded_by":"4-5","ID":"4","XPOS":"APPR","UPOS":"ADP"},
    6:map{"HEAD":"_","FEATS":"Case=Dat|Definite=Def|Gender=Masc|Number=Sing|PronType=Art","FORM":"dem","DEPS":"_","LEMMA":"der","DEPREL":"_","MISC":"_","excluded_by":"4-5","ID":"5","XPOS":"ART","UPOS":"DET"},
    7:map{"HEAD":"_","FEATS":"Case=Dat|Gender=Masc|Number=Sing","FORM":"Winter","DEPS":"_","LEMMA":"Winter","DEPREL":"_","MISC":"_","ID":"6","XPOS":"NN","UPOS":"NOUN"},
    8:map{"HEAD":"_","FEATS":"_","FORM":"in","DEPS":"_","LEMMA":"in","DEPREL":"_","MISC":"_","ID":"7","XPOS":"APPR","UPOS":"ADP"},
    9:map{"HEAD":"_","FEATS":"Case=Acc|Number=Sing|Person=2|PronType=Prs|Reflex=Yes","FORM":"dich","DEPS":"_","LEMMA":"du","DEPREL":"_","MISC":"_","ID":"8","XPOS":"PRF","UPOS":"PRON"},
    10:map{"HEAD":"_","FEATS":"Mood=Ind|Number=Sing|Person=3|Tense=Pres|VerbForm=Fin","FORM":"verliebt","DEPS":"_","LEMMA":"verlieben","DEPREL":"_","MISC":"SpaceAfter=No","ID":"9","XPOS":"VVFIN","UPOS":"VERB"},
    11:map{"HEAD":"_","FEATS":"_","FORM":".","DEPS":"_","LEMMA":".","DEPREL":"_","MISC":"SpacesAfter=\n\n","ID":"10","XPOS":"$.","UPOS":"PUNCT"}
    }
}</xd:pre></xd:p></xd:doc>
    <xsl:variable name="annotation_map"
        as="map(xs:integer, map(xs:integer, map(xs:string, xs:string)))">
        <xsl:map>
            <xsl:for-each select="map:keys($corpus_map)">
                <xsl:map-entry key="position()">
                    <xsl:map>
                        <xsl:variable name="exclusions" as="map(xs:string,xs:string)">
                            <xsl:map>
                                <xsl:for-each select="$corpus_map(.)[matches(., '^\d+-\d')]">
                                    <xsl:variable name="my_id" select="substring-before(.,$value_separator)" as="xs:string"/>
                                    <xsl:variable name="enumerated"
                                        select="xs:integer(substring-before($my_id, '-')) to xs:integer(substring-after($my_id, '-'))"
                                        as="xs:integer+"/>

                                    <xsl:for-each select="$enumerated">
                                        <xsl:map-entry key="xs:string(.)" select="$my_id"/>
                                    </xsl:for-each>
                                </xsl:for-each>
                            </xsl:map>
                        </xsl:variable>
                        <xsl:for-each select="$corpus_map(.)[matches(., '^\d')]">
                            <!-- both tokens and analyses thereof ('im'=4-5 as well as 'in'=4 + 'dem'=5) -->
                            <xsl:variable name="col_seq" select="tokenize(., $value_separator)"
                                as="xs:string+"/>
                            <xsl:map-entry key="position()">
                                <xsl:map>
                                    <xsl:for-each select="$col_seq">
                                        <xsl:variable name="pos" select="position()" as="xs:integer"/>
                                        <xsl:map-entry key="$columns[$pos]" select="."/>
                                    </xsl:for-each>
<!--                                    handle excluded_by (and join?) here, but compute the values outside this loop 
                                        (later: build a map to derive various values for @join) -->
                                    <xsl:if test="$exclusions($col_seq[1])">
                                        <xsl:map-entry key="'excluded_by'" select="$exclusions($col_seq[1])"/>
                                    </xsl:if>
                                </xsl:map>
                            </xsl:map-entry>
                        </xsl:for-each>
                    </xsl:map>
                </xsl:map-entry>
            </xsl:for-each>
        </xsl:map>
    </xsl:variable>

    
    
    <xsl:variable name="plain_sentences" as="element()+">
        <xsl:for-each select="map:keys($metadata_map)">
            <xsl:sort select="." order="ascending"/>
            <xsl:variable name="sent_id" select="if ($metadata_map(.)('sent_id')) then $metadata_map(.)('sent_id') else $unknown_id_pref || position()" as="xs:string"/>
            <s xml:id="{$sent_id}"><xsl:value-of select="$metadata_map(.)('text')"/></s>
        </xsl:for-each>
    </xsl:variable>
    
    <xsl:variable name="sequential_annotation" as="element()+">
        <xsl:for-each select="map:keys($metadata_map)">
            <xsl:sort select="." order="ascending"/>
<!--            <xsl:variable name="sent_id" select="$metadata_map(.)('sent_id')" as="xs:string*"/>-->
            <xsl:variable name="sent_id" select="if ($metadata_map(.)('sent_id')) then $metadata_map(.)('sent_id') else $unknown_id_pref || position()" as="xs:string"/>
            <xsl:variable name="sent_number" select="."/>
            <s xml:id="{'seq_' || $sent_id}" corresp="{'#' || $sent_id}">
                <xsl:for-each select="map:keys($annotation_map($sent_number))">
                    <!--we use xsl:if here to see where the discontinuity happens, for debugging mostly-->
                    <xsl:if test="not($annotation_map($sent_number)(.)('excluded_by'))">
                        <seg xml:id="{'seq_' || $sent_id || '-' || $annotation_map($sent_number)(.)('ID')}">
                            <xsl:if test="matches($annotation_map($sent_number)(.)('MISC'),'SpaceAfter=No')">
                                <xsl:attribute name="join" select="'right'"/>
                            </xsl:if>
                            <xsl:value-of select="$annotation_map($sent_number)(.)('FORM')"/>
                        </seg>
                    </xsl:if>
                </xsl:for-each>
                <xsl:for-each select="map:keys($annotation_map($sent_number))[not(matches($annotation_map($sent_number)(.)('ID'),'\d+-\d'))]">
                    <!-- excluding the portmanteaus by force, this feels like a kludge -->
                    <span type="wordForm" n="UPOS:XPOS" xml:id="{'seq-wf_' || $sent_id || '-' || $annotation_map($sent_number)(.)('ID')}"
                        lemma="{$annotation_map($sent_number)(.)('LEMMA')}"
                        pos="{$annotation_map($sent_number)(.)('UPOS') || $pos_separator || $annotation_map($sent_number)(.)('XPOS')}"
                        msd="{$annotation_map($sent_number)(.)('FEATS')}"
                        corresp="{concat('#seq_',$sent_id, '-', if (not($annotation_map($sent_number)(.)('excluded_by'))) then $annotation_map($sent_number)(.)('ID') else $annotation_map($sent_number)(.)('excluded_by') )}"
                        >
                    </span>
                </xsl:for-each>
            </s>
        </xsl:for-each>
    </xsl:variable>
    
    <xd:doc>
        <xd:desc>There is nearly no excuse for this function to look as it does. But I needed something quick to recursively compute token offsets</xd:desc>
        <xd:param name="sentence">The sentence for which the map is produced</xd:param>
        <xd:param name="current_key">Pointer at the current token</xd:param>
        <xd:param name="base_offset">Should point at the inter-character-point just before the current token</xd:param>
    </xd:doc>
    <xsl:function name="f:map_offsets" as="map(xs:integer, map(xs:string,xs:integer))">
        <xsl:param name="sentence" as="map(xs:integer, map(xs:string, xs:string))"/>
        <xsl:param name="current_key" as="xs:integer"/>
        <xsl:param name="base_offset" as="xs:integer"/>

        <xsl:variable name="adjusted_base" as="xs:integer" select="$base_offset"/>
        <!--this variable is a tunnel for adjustments with @join="left" effects, to be done-->

        <xsl:variable name="end_offset" as="xs:integer" select="$adjusted_base + string-length($sentence($current_key)('FORM'))"/>
        <xsl:variable name="adjusted_end" as="xs:integer" select="if (matches($sentence($current_key)('MISC'),'SpaceAfter=No')) then $end_offset else $end_offset + 1"/>
        
        <xsl:choose>
            <xsl:when test="$sentence($current_key)('excluded_by')">
                <xsl:sequence
                    select="f:map_offsets($sentence,$current_key +1,$base_offset)"
                />
            </xsl:when>
            <xsl:when test="$current_key lt map:size($sentence)">
                <xsl:sequence
                    select="map:merge((map{$current_key : map{'start' : $adjusted_base, 'end' : $end_offset}}, f:map_offsets($sentence,$current_key +1,$adjusted_end)))"
                />
            </xsl:when>
            <xsl:otherwise>
                
                <xsl:map>
                    <xsl:map-entry key="$current_key"
                        select="map{'start' : $adjusted_base, 'end' : $end_offset}"/>
                </xsl:map>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xd:doc>
        <xd:desc>This is the 'main() function' -- the entry point.</xd:desc>
    </xd:doc>
    <xsl:template name="xsl:initial-template">
        
        <TEI xmlns="http://www.tei-c.org/ns/1.0">
            <teiHeader>
                <fileDesc>
                    <titleStmt>
                        <title>Output of the UD2MAF.xml script</title>
                    </titleStmt>
                    <publicationStmt>
                        <p>This is free output of the tool UD2MAF, accompanying the ISO MAF (proposed, revised) standard.</p>
                    </publicationStmt>
                    <sourceDesc>
                        <p>Created in the electronic form.</p>
                    </sourceDesc>
                </fileDesc>
            </teiHeader>
            <text>
                <body>
                    <div type="'plain'">
                        <p>
                            <xsl:sequence select="$plain_sentences"/>
                        </p>
                    </div>
                    <div type="'sequential'">
                        <p>
                            <xsl:sequence select="$sequential_annotation"/>
                        </p>
                    </div>
                </body>
            </text>
            <standOff>
                <xsl:for-each select="map:keys($metadata_map)">
                    <xsl:sort select="." order="ascending"/>
                    <xsl:variable name="sent_id" select="if ($metadata_map(.)('sent_id')) then $metadata_map(.)('sent_id') else $unknown_id_pref || position()" as="xs:string"/>
                    <xsl:variable name="sent_number" select="."/>
                    <xsl:variable name="index_m" as="map(xs:integer, map(xs:string, xs:integer))" select="f:map_offsets($annotation_map($sent_number),1,0)"/>
                    
                    <listAnnotation corresp="{'#' || $sent_id}" xml:id="{'ann_' || $sent_id}">
                        <annotationBlock type="token" offsetBase="{'#' || $sent_id}">
                            <xsl:for-each select="map:keys($annotation_map($sent_number))">
                                <xsl:sort select="." order="ascending"/>
                                <xsl:if test="not($annotation_map($sent_number)(.)('excluded_by'))">
                                    <seg
                                        xml:id="{'so-seg_' || $sent_id || '-' || $annotation_map($sent_number)(.)('ID')}"
                                        startPos="{$index_m(position())('start')}"
                                        endPos="{$index_m(position())('end')}"/>
                                </xsl:if>
                            </xsl:for-each>
                        </annotationBlock>
                        
                        <annotationBlock type="wordForm" n="LEMMA">
                            <xsl:for-each select="map:keys($annotation_map($sent_number))[not(matches($annotation_map($sent_number)(.)('ID'),'\d+-\d'))]">
                                <!-- excluding the portmanteaus by force, this feels like a kludge -->
                                <xsl:sort select="." order="ascending"/>
                                <span type="wordForm" xml:id="{'so-wf-lem_' || $sent_id || '-' || $annotation_map($sent_number)(.)('ID')}"
                                    lemma="{$annotation_map($sent_number)(.)('LEMMA')}"
                                    corresp="{concat('#so-seg_',$sent_id, '-', if (not($annotation_map($sent_number)(.)('excluded_by'))) then $annotation_map($sent_number)(.)('ID') else $annotation_map($sent_number)(.)('excluded_by') )}"
                                    >
                                </span>
                            </xsl:for-each>
                        </annotationBlock>
                        
                        <annotationBlock type="wordForm" n="XPOS">
                            <xsl:for-each select="map:keys($annotation_map($sent_number))[not(matches($annotation_map($sent_number)(.)('ID'),'\d+-\d'))]">
                                <!-- excluding the portmanteaus by force, this feels like a kludge -->
                                <xsl:sort select="." order="ascending"/>
                                <span type="wordForm" xml:id="{'so-wf-x_' || $sent_id || '-' || $annotation_map($sent_number)(.)('ID')}"
                                    lemma="{$annotation_map($sent_number)(.)('LEMMA')}"
                                    pos="{$annotation_map($sent_number)(.)('XPOS')}"
                                    corresp="{concat('#so-seg_',$sent_id, '-', if (not($annotation_map($sent_number)(.)('excluded_by'))) then $annotation_map($sent_number)(.)('ID') else $annotation_map($sent_number)(.)('excluded_by') )}"
                                    >
                                </span>
                            </xsl:for-each>
                        </annotationBlock>
                        
                        <annotationBlock type="wordForm" n="UPOS">
                            <xsl:for-each select="map:keys($annotation_map($sent_number))[not(matches($annotation_map($sent_number)(.)('ID'),'\d+-\d'))]">
                                <!-- excluding the portmanteaus by force, this feels like a kludge -->
                                <xsl:sort select="." order="ascending"/>
                                <span type="wordForm" xml:id="{'so-wf-u_' || $sent_id || '-' || $annotation_map($sent_number)(.)('ID')}"
                                    lemma="{$annotation_map($sent_number)(.)('LEMMA')}"
                                    pos="{$annotation_map($sent_number)(.)('UPOS')}"
                                    msd="{$annotation_map($sent_number)(.)('FEATS')}"
                                    corresp="{concat('#so-seg_',$sent_id, '-', if (not($annotation_map($sent_number)(.)('excluded_by'))) then $annotation_map($sent_number)(.)('ID') else $annotation_map($sent_number)(.)('excluded_by') )}"
                                    >
                                </span>
                            </xsl:for-each>
                        </annotationBlock>
                        
                        <xsl:comment>the following annotation block is overall spurious, but still interesting in how it mimics the merged UPOS:XPOS description in the &lt;text> element above</xsl:comment>
                        <annotationBlock type="wordForm" n="UPOS:XPOS">
                            <xsl:for-each select="map:keys($annotation_map($sent_number))[not(matches($annotation_map($sent_number)(.)('ID'),'\d+-\d'))]">
                                <!-- excluding the portmanteaus by force, this feels like a kludge -->
                                <xsl:sort select="." order="ascending"/>
                                <span type="wordForm" xml:id="{'so-wf-ux_' || $sent_id || '-' || $annotation_map($sent_number)(.)('ID')}"
                                    lemma="{$annotation_map($sent_number)(.)('LEMMA')}"
                                    pos="{$annotation_map($sent_number)(.)('UPOS') || $pos_separator || $annotation_map($sent_number)(.)('XPOS')}"
                                    msd="{$annotation_map($sent_number)(.)('FEATS')}"
                                    corresp="{concat('#so-seg_',$sent_id, '-', if (not($annotation_map($sent_number)(.)('excluded_by'))) then $annotation_map($sent_number)(.)('ID') else $annotation_map($sent_number)(.)('excluded_by') )}"
                                    >
                                </span>
                            </xsl:for-each>
                        </annotationBlock>
                    </listAnnotation>
                </xsl:for-each>
            </standOff>
        </TEI>
        
    </xsl:template>
    
</xsl:stylesheet>
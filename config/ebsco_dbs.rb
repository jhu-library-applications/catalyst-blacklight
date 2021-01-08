$ebsco_dbs = []
    $ebsco_dbs.push( 'asn' )  # Academic Search Ultimate **
    $ebsco_dbs.push( 'awn' )  # Africa-Wide Information **
    $ebsco_dbs.push( 'ahl' )  # America: History & Life **
    $ebsco_dbs.push( 'rfh' )  # ATLA Religion Database with ATLASerials **
    $ebsco_dbs.push( 'rzh' )  # CINAHL Plus with Full Text **
    $ebsco_dbs.push( 'cmedm') # Medline
    $ebsco_dbs.push( 'ufh' )  # Communication & Mass Media Complete **
    $ebsco_dbs.push( 'eoh' )  # EconLit with Full Text **
    $ebsco_dbs.push( '20h' )  # Educational Administration Abstracts **
    $ebsco_dbs.push( 'eric')  # ERIC
    $ebsco_dbs.push( 'flh' )  # Family & Society Studies Worldwide **
    $ebsco_dbs.push( 'f3h' )  # Film & Television Literature Index with Full Text **
    $ebsco_dbs.push( 'fmh' )  # Gender Studies Database **
    $ebsco_dbs.push( 'geh' )  # GeoRef **
    $ebsco_dbs.push( '8gh' )  # GreenFILE **
    $ebsco_dbs.push( 'hch' )  # Health Source: Nursing/Academic Edition **
    $ebsco_dbs.push( 'hia' )  # Historical Abstracts **
    $ebsco_dbs.push( '22h' )  # Human Resources Abstracts **
    $ebsco_dbs.push( 'hgh' )  # Humanities International Index **
    $ebsco_dbs.push( 'ijh' )  # International Political Science Abstracts **
    $ebsco_dbs.push( 'lxh' )  # Library, Information Science & Technology Abstracts **
    $ebsco_dbs.push( 'f5h' )  # MasterFILE Premier **
    $ebsco_dbs.push( 'mth' )  # Military & Government Collection **
    $ebsco_dbs.push( 'mzh' )  # MLA International Bibliography **
    # $ebsco_dbs.push( 'pfi' )  # Philosopher's Index with Full Text ** Disabled see HELP-20951
    $ebsco_dbs.push( 'pdh' )  # PsycARTICLES **
    $ebsco_dbs.push( 'psyh' )  # PsycINFO **
    $ebsco_dbs.push( 'rih' )  # RILM  Abstracts of Music Literature **
    $ebsco_dbs.push( 'rph' )  # RIPM - Retrospective Index to Music Periodicals **
    $ebsco_dbs.push( 's3h' )  # SPORTDiscus with Full Text **
    $ebsco_dbs.push( 'trh' )  # Teacher Reference Center **
    $ebsco_dbs.push( 'mah' )  # Music Index **
    $ebsco_dbs.push( 'bsu' )  # Business Source Ultimate **
    $ebsco_dbs.push( 'i3h' )  # Criminal Justice Abstracts with full text **
    ##$ebsco_dbs.push( 'lft' )  # Index to Legal Periodicals & Books Full Text (H.W. Wilson) **
    ##$ebsco_dbs.push( 'asf' )  # Applied Science & Technology Full Text (H.W. Wilson) **
    $ebsco_dbs.push( 'hsr' )  # Humanities & Social Sciences Index Retrospective: 1907-1984 (H.W. Wilson) **
    $ebsco_dbs.push( 'rgr' )  # Readers' Guide Retrospective: 1890-1982 (H.W. Wilson) **

    # Include OmniFile, that is a superset of these smaller indexes
    # that we currently do not have access to.
    #$ebsco_dbs.push( 'ofm' )  # Wilson OmniFile


    # for reasons we don't know, we lost access to Ed Full Text.
    # 4 Sep 2012 jrochkind
    #$ebsco_dbs.push( 'eft' )  # Education Full Text (H.W. Wilson) **
    $ebsco_dbs.push( 'air' )  # Art Index Retrospective (H.W. Wilson) **
    $ebsco_dbs.push( 'aft' )  # Art Full Text (H.W. Wilson) **
    ##$ebsco_dbs.push( 'ofm' )  # OmniFile Full Text Mega (H.W. Wilson) **


    # for reasons we don't know, we lost access to Reader's Guide and
    # Social Sciences Full Text
    # 4 Sep 2012
    #$ebsco_dbs.push( 'rgm' )  # Readers' Guide Full Text Mega (H.W. Wilson)
    #$ebsco_dbs.push( 'ssf' )  # Social Sciences Full Text (H.W. Wilson) **
    #$ebsco_dbs.push( 'hft' )  # Humanities Full Text (H.W. Wilson) **
    #$ebsco_dbs.push( 'gft' )  # General Science Full Text (H.W. Wilson) **
    #$ebsco_dbs.push( 'bft' )  # Business Abstracts with Full Text (H.W. Wilson) **

    # Added by APL request
    $ebsco_dbs.push( 'tsh' )   # International Security & Counter Terrorism Reference Center
    # This one didn't seem to produce useful enough results in cross-search
    #$ebsco_dbs.push( 'ieh' )   # Inspec Archive - Science Abstracts 1898-1968

function [model,condGF,targetGF,relaxGF] = verifyGapfilledReactions(model,osenseStr)
% Part of the DEMETER pipeline. Checks whether reactions that were added
% by the gapfilling steps performed in DEMETER are required for biomass
% production. Reactions that are no longer needed are removed.
%
% USAGE
%       model = verifyGapfilledReactions(model,osenseStr)
%
% INPUT
% model             COBRA model structure
% osenseStr:        Maximize ('max')/minimize ('min') linear part of the
%                   objective

%
% OUTPUT
% model             COBRA model structure
% condGF            Reactions added based on conditions (recognizing
%                   certain patterns of reactions)
% targetGF          Reactions added based on tagrted gapfilling (specific
%                   metabolites that could not be produced)
% relaxGF           Reactions added based on relaxFBA (lowest level of
%                   confidence)
%
% .. Authors:
%       Almut Heinken and Stefania Magnusdottir, 2016-2019

tol = 0.0001;

% find the sets of gapfilled reactions and delete them -> still growth?

conditionSpecificGapfills={'rxnPresent','rxnAbsent','changeConstraints','gapfillRxns'
    'EX_dpcoa(e) OR EX_coa(e)',[],1,'PTPAT AND DPCOAK AND PPCDC AND PPNCL3 AND PNTK AND EX_pnto_R(e) AND PNTOabc'
    [],'EX_pnto_R(e)',0,'PTPAT AND DPCOAK AND PPCDC AND PPNCL3 AND PNTK AND EX_pnto_R(e) AND PNTOabc'
    'EX_cmp(e)',[],1,'EX_cytd(e) AND CYTDt2'
    'EX_dtmp(e)',[],1,'EX_thymd(e) AND THMDt2r AND TMDK1 AND TMDK2'
    'EX_ump(e)',[],1,'EX_ura(e) AND URAt2'
    'EX_gmp(e)',[],1,'EX_gua(e) AND GUAt2 AND GUAPRT'
    'EX_dgtp(e)',[],1,'EX_dgsn(e) AND DGSNt2 AND r0456'
    'EX_nadp(e)','NADK',1,'NADK'
    'EX_thmmp(e)',[],1,'EX_thm(e) AND THMabc AND TMKr'
    [],'RBFK',0,'RBFK'
    'EX_malt(e)',[],1,'PGMT'
    'EX_stys(e) OR EX_raffin(e) OR EX_melib(e) OR EX_lcts(e)',[],1,'EX_gal(e) AND GALabc'
    'EX_cgly(e)',[],0,'EX_gly(e) AND GLYt2r AND EX_cys_L(e) AND CYSt2r'
    'EX_alaasp(e)',[],1,'EX_ala_L(e) AND ALAt2r AND EX_asp_L(e) AND ASPt2r'
    'EX_alaglu(e)',[],1,'EX_ala_L(e) AND ALAt2r AND EX_glu_L(e) AND GLUt2r'
    'EX_alagly(e)',[],1,'EX_ala_L(e) AND ALAt2r AND EX_gly(e) AND GLYt2r'
    'EX_alahis(e)',[],1,'EX_ala_L(e) AND ALAt2r AND EX_his_L(e) AND HISt2r'
    'EX_alaleu(e)',[],1,'EX_ala_L(e) AND ALAt2r AND EX_leu_L(e) AND LEUt2r'
    'EX_alathr(e)',[],1,'EX_ala_L(e) AND ALAt2r AND EX_thr_L(e) AND THRt2r'
    'EX_glyasn(e)',[],1,'EX_gly(e) AND GLYt2r AND EX_asn_L(e) AND ASNt2r'
    'EX_glyasp(e)',[],1,'EX_gly(e) AND GLYt2r AND EX_asp_L(e) AND ASPt2r'
    'EX_glygln(e)',[],1,'EX_gly(e) AND GLYt2r AND EX_gln_L(e) AND GLNt2r'
    'EX_glyglu(e)',[],1,'EX_gly(e) AND GLYt2r AND EX_glu_L(e) AND GLUt2r'
    'EX_glymet(e)',[],1,'EX_gly(e) AND GLYt2r AND EX_met_L(e) AND METt2r'
    'EX_glyphe(e)',[],1,'EX_gly(e) AND GLYt2r AND EX_phe_L(e) AND PHEt2r'
    'EX_glypro(e)',[],1,'EX_gly(e) AND GLYt2r AND EX_pro_L(e) AND PROt2r'
    'EX_glytyr(e)',[],1,'EX_gly(e) AND GLYt2r AND EX_tyr_L(e) AND TYRt2r'
    'EX_metala(e)',[],1,'EX_ala_L(e) AND ALAt2r AND EX_met_L(e) AND METt2r'
    'GK1',[],0,'DGK1'
    'FRD2',[],0,'FRD7'
    'OIVD1r',[],0,'OIVD2 AND OIVD3'
    'OIVD3',[],0,'OIVD1r AND OIVD3'
    'RHCCE',[],0,'DM_dhptd(c)'
    'URIK1',[],0,'URIK9'
    'r0671',[],0,'NDPK3 AND NDPK1 AND NDPK2 AND NDPK4 AND NDPK5 AND NDPK6 AND NDPK7 AND NDPK8 AND NDPK9 AND NTD1 AND NTD2 AND NTD3 AND NTD4 AND NTD8 AND NTD9 AND NTD10 AND NTD11 AND EX_cytd(e) AND CYTDt2r'
    'NADK2 OR URIK2 OR URIK4 OR URIK9 OR CYTDK2 OR SADT2 OR DTTPti',[],0,'NDPK3 AND NDPK1 AND NDPK2 AND NDPK4 AND NDPK5 AND NDPK6 AND NDPK7 AND NDPK8 AND NDPK9'
    'ACGAMK',[],0,'EX_acgam(e) AND ACGAMtr2'
    'AGDC AND ACGAMK_r',[],0,'EX_acgam(e) AND ACGAMtr2'
    'AGDC','ACGAMK_r',0,'G1PACT'
    'G6PDA',[],0,'GF6PTA'
    'AMPTASECG',[],0,'EX_cgly(e) AND CGLYt3_2_'
    'TRE6PS OR TRE6PPGT OR UDPGP OR UDPGFRUGT',[],0,'GALU AND PGMT'
    'OBTFL',[],0,'THRD_L'
    'GUAD',[],0,'EX_gua(e) AND GUAt2'
    'OCTT OR NPHS',[],0,'PREN'
    'NNATr',[],0,'NADN AND NNAM AND NAPRT'
    'L2A6ODs',[],0,'EX_lys_L(e) AND LYSt2r AND 26DAPLLAT AND DAPE'
    'DAPDC',[],0,'EX_lys_L(e) AND LYSt2r AND 26DAPLLAT AND DAPE AND DHDPRyr AND EX_26dap_M(e) AND 26DAPt2r'
    'CHORM',[],0,'EX_chor(e) AND CHORt'
    'HSST',[],0,'EX_fol(e) AND FOLabc AND GLYCL AND CYSTS AND EX_2obut(e) AND 2OBUTt2r'
    'ACOCT',[],0,'HYPSUCORNS AND SUCCITRDSs AND SUCORNTC'
    'AGMD OR ACGK',[],0,'ACGS'
    'AIRC4',[],0,'H2CO3D'
    'AMPN',[],0,'PRPPS AND EX_ncam(e) AND NCAMt2r'
    'NMNS',[],0,'EX_ncam(e) AND NCAMabc'
    'THRPD OR THRD',[],0,'EX_thr_L(e) AND THRt2r'
    'ARGN OR ARGDA',[],0,'EX_arg_L(e) AND ARGt2r'
    'PUTA3',[],0,'EX_pro_L(e) AND PROt2r AND EX_orn(e) AND ORNt2r'
    'r0060',[],0,'EX_ser_L(e) AND SERt2r'
    'r0127',[],0,'EX_asn_L(e) AND ASNt2r'
    'IAHDGK',[],0,'PAAI17P'
    'IHDGK',[],0,'PAI17P'
    'UPPDC1 AND EX_pheme(e)',[],0,'EX_sheme(e) AND SHEMEabc'
    'PPPGO3 AND EX_pheme(e)',[],0,'EX_sheme(e) AND SHEMEabc'
    'CPC2MT AND EX_pheme(e)',[],0,'EX_sheme(e) AND SHEMEabc'
    'CPC2MT','EX_pheme(e)',0,'EX_pheme(e) AND HEMEti AND EX_sheme(e) AND SHEMEabc'
    'PPPH',[],0,'EX_pheme(e) AND HEMEti'
    'RE3009C',[],0,'BPNT'
    'r0119',[],0,'GK1 AND GK2 AND DGK1'
    'URIK8 AND NDPK5',[],0,'GK1 AND GK2 AND DGK1'
    'RNDR2 AND GUAPRT',[],0,'GK1 AND GK2 AND DGK1'
    'NDPK1 AND GTPDPK',[],0,'GK1 AND GK2 AND DGK1'
    'CDAPPA120',[],0,'EX_cytd(e) AND CYTDt2r'
    'CBPS',[],0,'H2CO3D'
    'UPPDC1 AND MECDPDH2',[],0,'DMPPS'
    'DAGK180',[],0,'ACOATA AND TDCOATA AND MCOATA AND STCOATA AND PMTCOATA AND EAR40x AND EAR60x AND EAR80x AND EAR100x AND EAR120x AND EAR121x AND EAR140x AND EAR141x AND EAR160x AND EAR161x AND EAR180x AND EAR181x AND PAPA180 AND AACPS6'
    '3HAD140',[],0,'EAR40x AND EAR60x AND EAR80x AND EAR100x AND EAR120x AND EAR121x AND EAR140x AND EAR141x AND EAR160x AND EAR161x AND EAR180x AND EAR181x AND KAS16 AND AACPS6'
    'PLIPA1A181',[],0,'G3PAT120 AND G3PAT140 AND G3PAT141 AND G3PAT160 AND G3PAT161 AND G3PAT180 AND G3PAT181'
    'LPLIPAL2A180',[],0,'EX_12dgr180(e) AND 12DGR180ti'
    'AGPAT140',[],0,'G3PAT120 AND G3PAT140 AND G3PAT141 AND G3PAT160 AND G3PAT161 AND G3PAT180 AND G3PAT181'
    'AGPAT180',[],0,'ACOATA AND TDCOATA AND MCOATA AND STCOATA AND PMTCOATA'
    'LPLIPAL2E180',[],0,'3OAS60 AND 3OAS80 AND 3OAS100 AND 3OAS120 AND 3OAS121 AND 3OAS140 AND 3OAS141 AND 3OAS160 AND 3OAS161 AND 3OAS180 AND 3OAS181 AND AACPS6 AND 3HAD40 AND 3HAD60 AND 3HAD80 AND 3HAD100 AND 3HAD120 AND 3HAD121 AND 3HAD140 AND 3HAD141 AND 3HAD160 AND 3HAD161 AND 3HAD180 AND 3HAD181 AND PSD120 AND PSD140 AND PSD160 AND PSD180 AND PSD181 AND PSSA120 AND PSSA140 AND PSSA160 AND PSSA180 AND PSSA181 AND AACPS6 AND EX_glyc(e) AND GLYCt'
    '3OAS180',[],0,'KAS_HP'
    'PLIPA1G180 OR LPLIPAL1A180 OR PLIPA2G180',[],0,'PGPP180 AND PGSA180 AND EX_ocdca(e) AND OCDCAtr AND G3PAT180 AND AACPS6 AND EX_glyc(e) AND GLYCt'
    'PFK_3',[],0,'TALA'
    'NADH8 OR NADH9',[],0,'FRD2 AND FRD3 AND FRD7'
    'DMPPL',[],0,'DXPS AND MECDPS AND MEPCT'
    'DMATT',[],0,'DXPS AND DMPPS AND MECDPS AND MEPCT AND CDPMEK AND MECDPS AND MECDPDH2 AND DXPRIi'
    'DCTPAH',[],0,'ADAD AND EX_dcyt(e) AND DCYTt2r AND EX_acald(e) AND ACALDt'
    'HEXTT',[],0,'EX_mqn8(e) AND MK8t'
    'TMDS',[],0,'NDPK9 AND NTD1 AND NTD2 AND NTD3 AND NTD4 AND NTD5 AND NTD6 AND NTD7 AND NTD8 AND NTD9 AND NTD10 AND NTD11 AND EX_thymd(e) AND THMDt2r'
    'RNTR1',[],0,'NDPK9 AND NTD1 AND NTD2 AND NTD3 AND NTD4 AND NTD5 AND NTD6 AND NTD7 AND NTD8 AND NTD9 AND NTD10 AND NTD11 AND EX_thymd(e) AND THMDt2r AND EX_cytd(e) AND CYTDt2r AND EX_dad_2(e) AND DADNt2r AND PPM AND TALA AND NNAM AND EX_nac(e) AND EX_nac(e) AND EX_nac(e) AND NACt2r AND EX_ade(e) AND ADEt2r'
    [],'NADN',0,'NADN'
    [],'ADPRDP',0,'ADPRDP'
    [],'PRPPS',0,'PRPPS'
    'RNTR2',[],0,'NDPK9 AND NTD1 AND NTD2 AND NTD3 AND NTD4 AND NTD5 AND NTD6 AND NTD7 AND NTD8 AND NTD9 AND NTD10 AND NTD11 AND EX_dgsn(e) AND DGSNt2r'
    'RNTR3',[],0,'EX_csn(e) AND CSNt6'
    'RNTR4',[],0,'GLUPRT AND CSNt6 AND PPM AND TALA AND NNAM AND EX_nac(e) AND NACt2r'
    'TMDSf2',[],0,'EX_thymd(e) AND THMDt2r'
    'NADK2 OR DADNK',[],0,'EX_dad_2(e) AND DADNt2r'
    'THMDt2',[],0,'THMDt2r'
    'THMDt4',[],0,'THMDt4r'
    'CYTDt4',[],0,'CYTDt4r'
    'RBK_D',[],0,'RBK_Dr'
    'DTMPK',[],0,'NTPP7'
    'GLYPROabc',[],0,'CYSTGL AND CYSTS AND EX_2obut(e) AND 2OBUTt2r'
    'GLYMETabc',[],0,'MTHFD AND MTHFD2 AND FTHFL'
    'GLYLEUPEPT1tc',[],0,'MTHFD AND MTHFD2 AND FTHFL AND EX_for(e) AND FORt'
    'SUCBZL',[],0,'EX_4hbz(e) AND 4HBZt2'
    'AGPAT120',[],0,'AACPS7'
    'MACPD',[],0,'ACCOAC AND H2CO3D'
    'RHC',[],0,'HCYSMT'
    'NADK OR NADK2',[],0,'NADS1 AND NADS2 AND NAPRT AND NNATr AND EX_nac(e) AND NACt2r'
    'TAGO',[],0,'EX_ura(e) AND URAt2r AND UMPK AND UMPK2 AND UMPK3 AND UMPK4 AND UMPK5 AND UMPK6 AND UMPK7 AND PPM AND TALA AND NNAM AND EX_nac(e) AND NACt2r AND EX_ade(e) AND ADEt2r AND G1PACT AND UAGDP AND PGAMT AND EX_fald(e) AND r1421'
    'GMPS2',[],0,'EX_gua(e) AND GUAt2'
    'DASYN140',[],0,'CTPS1 AND CTPS2'
    'NTD11',[],0,'EX_ins(e) AND INSt'
    'GMPR',[],0,'EX_gua(e) AND GUAt2'
    'PLPS',[],0,'TALA'
    'CYSDS',[],0,'EX_cys_L(e) AND CYSt2r'
    'THMDt2',[],0,'EX_fol(e) AND FOLt'
    'NT5C',[],0,'EX_nac(e) AND NACt2r'
    'DAAD',[],0,'EX_ala_L(e) AND ALAt2r'
    'ORNDC AND r1667',[],0,'EX_arg_L(e) AND ARGt2r'
    'ORNTA AND r1667',[],0,'EX_arg_L(e) AND ARGt2r'
    'ORNDC OR ORNTA OR ORNCD','r1667',0,'EX_orn(e) AND ORNt2r'
    'ORNCD AND r1667',[],0,'EX_arg_L(e) AND ARGt2r'
    'PC',[],0,'H2CO3D'
    'THIORDXi',[],0,'TRDRr'
    'MTHPTGHM',[],0,'AHCYSNS'
    'MTHPTGHM AND AHC',[],0,'CYSTGL AND CYSTS AND EX_2obut(e) AND 2OBUTt2r AND EX_adn(e) AND ADNCNT3tc'
    'ADCYRS',[],0,'CYSTGL AND CYSTS AND AHCYSNS'
    'HCYSMT',[],0,'AHCYSNS'
    'AHCYSts',[],0,'EX_met_L(e) AND METt2r'
    'METALAabc',[],0,'EX_ala_L(e) AND ALAt2r'
    'CYSTL',[],0,'CYSTGL AND CYSTS AND EX_2obut(e) AND 2OBUTt2r'
    'NTD2',[],0,'EX_uri(e) AND URIt2r'
    'SUCR',[],0,'PGMT'
    'Cut1',[],0,'Cuabc'
    'ETHAAL',[],0,'PSD120 AND PSD140 AND PSD160 AND PSD180 AND PSD181 AND PSSA120 AND PSSA140 AND PSSA160 AND PSSA180 AND PSSA181'
    'G3PAT120',[],0,'EAR40x AND EAR60x AND EAR80x AND EAR100x AND EAR120x AND EAR121x AND EAR140x AND EAR141x AND EAR160x AND EAR161x AND EAR180x AND EAR181x'
    'EAR140x',[],0,'EX_ocdcea(e) AND OCDCEAtr'
    'G3PAT180',[],0,'EAR40x AND EAR60x AND EAR80x AND EAR100x AND EAR120x AND EAR121x AND EAR140x AND EAR141x AND EAR160x AND EAR161x AND EAR180x AND EAR181x AND AACPS6'
    'RNDR3',[],0,'EX_cytd(e) AND CYTDt2r AND EX_csn(e) AND CSNt6'
    'RNDR4',[],0,'EX_uri(e) AND URIt2r AND EX_ura(e) AND URAt2r'
    'UPPRT',[],0,'PPM AND EX_ura(e) AND URAt2r'
    'PYDXPP',[],0,'PYDXK'
    'CPPPGO OR SHCHCC2',[],0,'EX_sheme(e) AND SHEMEabc AND EX_cobalt2(e) AND Coabc AND EX_pheme(e) AND HEMEti'
    'GLYCLTDx OR GLYCLTDy',[],0,'EX_glyclt(e) AND GLYCLTt2r'
    'PYK',[],0,'GAPD AND ENO'
    [],'EX_nh4(e)',0,'EX_nh4(e) AND NH4tb'
    'EX_gtp(e)',[],1,'EX_gsn(e) AND GSNt2 AND GSNK AND GK1 AND GK2'
    'EX_cmp(e)',[],1,'CYTDK1'
    'EX_dgtp(e)',[],1,'EX_dgtp(e) AND DGSNt2 AND DGK1'
    'EX_datp(e)',[],1,'EX_dad_2(e) AND DADNt2 AND TRDR AND RNDR1'
    'EX_amp(e)',[],1,'EX_adn(e) AND ADNt2 AND EX_ade(e) AND ADEt2 AND ADPT AND TALA AND EX_pi(e) AND PIabc'
    'EX_pppi(e)',[],1,'EX_pi(e) AND PIabc'
    'EX_r5p(e)',[],1,'TALA AND TKT2'
    'EX_g1p(e)',[],1,'PGMT'
    'EX_glu_D(e)',[],1,'EX_glu_L(e) AND GLUt2r'
    'EX_agm(e)',[],1,'EX_ptrc(e) AND PTRCabc'
    'EX_glycys(e)',[],1,'EX_cys_L(e) AND CYSt2r'
    'OCTT',[],0,'OCTDPS'
    'SPMDt3',[],0,'SPMDabc'
    'THMDP',[],0,'TMDPK'
    'AGDC OR ACGAMK OR UAG2EMA OR UACGAMP',[],0,'G1PACT AND UAGDP AND PGAMT'
    'FFSD OR GLCS2 OR TRE6PS',[],0,'GALU AND PGMT AND PGI'
    'UDPG4E AND UDPGALP',[],0,'GALU AND PGMT AND PGI'
    'NTPTP1',[],0,'PPA2 AND r0456'
    'NTPTP2',[],0,'PPA2 AND EX_gsn(e) AND GSNt'
    'GPDDA4',[],0,'AGPAT180'
    'DASYN180 AND PLIPA2A180',[],[],'AGPAT180'
    'DESAT14 AND FACOAL140',[],0,'EX_ttdca(e) AND TTDCAtr'
    'ACPS',[],0,'BPNT'
    'NH4t4',[],0,'NH4tb AND Kt1r'
    'UTPH1',[],0,'NDPK3 AND NDPK1 AND NDPK2 AND NDPK4 AND NDPK5 AND NDPK6 AND NDPK7 AND NDPK8 AND NDPK9 AND URIDK1 AND URIDK2'
    'RNTR4 OR DUTPDP',[],0,'URIDK1 AND URIDK2'
    'r0671',[],0,'CYTK1 AND CYTK2'
    'DMGLYMT OR SADT',[],0,'EX_so4(e) AND SO4t2'
    'SADT2',[],0,'EX_so4(e) AND SO4t2 AND GTHRDt2 AND EX_gthrd(e) AND BPNT'
    'DHAD1',[],0,'EX_val_L(e) AND VALt2r'
    'CDPGLYCPGH',[],0,'G3PCT AND CYTK1'
    'DMQMT OR DMQMT2 OR DHORDfum','SUCCt2r',0,'EX_succ(e) AND SUCCt'
    'ARGSL AND FRD2 AND FRD3 AND GLYAMDTRc','SUCCt2r',0,'EX_succ(e) AND SUCCt'
    'DTTPti',[],0,'EX_thymd(e) AND THMDt2r AND DTMPK AND TMDK1 AND TMDK2'
    'MACCOAT',[],0,'EX_ppa(e) AND PPAt2r AND EX_3mop(e) AND 3MOPt2r'
    'ORNTA OR AGMD',[],0,'ARGt2 AND EX_arg_L(e)'
    'THRD_L',[],0,'EX_ppa(e) AND PPAt2 AND EX_thr_L(e) AND THRt2r'
    'GLYCTO4 OR G3PD7',[],0,'FRD3'
    'AMALT1',[],0,'PGMT'
    'FRUpts',[],0,'PGMT AND EX_glyc(e) AND GLYCt'
    'FADDP',[],0,'FMNAT'
    'PGSA180',[],0,'DASYN120 AND DASYN140 AND DASYN160 AND DASYN180 AND DASYN181'
    'LPLIPAL2A180',[],0,'G3PAT180 AND AGPAT180'
    'NNATr',[],0,'NAPRT'
    'UPP3MT',[],0,'RHC'
    'GPDDA2 OR AHMMPS OR FDMO',[],0,'EX_gcald(e) AND GCALDt'
    [],'EX_pi(e)',0,'EX_pi(e) AND PIabc'
    'SHCHF OR FERO',[],0,'EX_fe2(e) AND FE2abc'
    'SHCHD2',[],0,'AHCYSNS AND RHCCE AND DM_dhptd(c) AND DM_hcys_L[c]'
    'KAS8 OR MCOATA OR ACCOAC',[],0,'ACS AND RHCCE AND EX_ac(e) AND ACtr'
    'ALAALAD',[],0,'ALAALA'
    'MACPOR',[],0,'3OAR40 AND 3OAR60 AND 3OAR80 AND 3OAR100 AND 3OAR120 AND 3OAR140 AND 3OAR141 AND 3OAR160 AND 3OAR180 AND EAR40x AND EAR60x AND EAR80x AND EAR100x AND EAR120x AND EAR121x AND EAR140x AND EAR141x AND EAR160x AND EAR161x AND EAR180x AND EAR181x'
    '4HBZORx OR 4HBZORy',[],0,'EX_4hbz(e) AND 4HBZt2'
    'HMGL',[],0,'OIVD1r AND OIVD2 AND OIVD3 AND LEUTA'
    'ACOAD20',[],0,'OIVD1r AND OIVD2 AND OIVD3'
    'GCALDL',[],0,'EX_glyc(e) AND GLYCt'
    'C180SNrev',[],0,'C180SN'
    'COCHL',[],0,'EX_cobalt2(e) AND Coabc'
    'CYSTGL',[],0,'EX_met_L(e) AND METt2r'
    'UPPRT OR PPA2',[],0,'PPA'
    'NADS1 AND FACOALAI17',[],0,'PPA'
    'HYD3',[],0,'FRD3 AND EX_fum(e) AND FUMt2r'
    'PYDXNK',[],0,'EX_pydx(e) AND PYDXabc AND EX_pydxn(e) AND PYDXNabc AND EX_pydam(e) AND PYDAMabc'
    'UACMAMH',[],0,'UAG2E'
    'FTHFDH',[],0,'FTHFL AND EX_for(e) AND FORt'
    'DESAT18',[],0,'EX_h2o2(e) AND H2O2t AND ACCOAC AND ACCOAC2'
    'GLXO2',[],0,'EX_h2o2(e) AND H2O2t'
    'PLIPA2E180',[],0,'PSD120 AND PSD140 AND PSD160 AND PSD180 AND PSD181 AND PSSA120 AND PSSA140 AND PSSA160 AND PSSA180 AND PSSA181'
    'TMDSf2',[],0,'GHMT2r'
    'r0301',[],0,'GK1 AND GK2'
    'AACPS6',[],0,'ADK1'
    'DCTPAH',[],0,'CYTK1 AND CYTK2'
    'NTD2',[],0,'URIK1'
    'NTD5',[],0,'TMDK1 AND TMDK2'
    'NTD11',[],0,'HXPRT'
    'NTPP7',[],0,'DTMPK'
    'CTPS1',[],0,'UPPRT'
    'XTSNH OR GUAPRT',[],0,'EX_gua(e) AND GUAt2'
    'P5CD',[],0,'EX_pro_L(e) AND PROt2r'
    'PPND2',[],0,'EX_phe_L(e) AND PHEt2r'
    'ASPO1',[],0,'EX_asp_L(e) AND ASPt2r'
    'GCALDL',[],0,'EX_ala_L(e) AND ALAt2r'
    'GGTA',[],0,'EX_glu_L(e) AND GLUt2r'
    'NADS2',[],0,'EX_gln_L(e) AND GLNt2r'
    'CYSTGL',[],0,'EX_ser_L(e) AND SERt2r'
    'NPHS',[],0,'EX_4abz(e) AND 4ABZt2'
    'Coabc',[],0,'EX_amp(e) AND AMPt2r'
    'DAAD AND ALAR',[],0,'EX_ala_L(e) AND ALAt2r AND EX_ala_D(e) AND DALAt2r'
    'GUAt2',[],0,'GUAt2r'
    'MTAN',[],0,'DM_5MTR'
    'CLPNS180',[],0,'EX_glyc(e) AND GLYCt'
    'TDCOATA AND EDTXS2',[],0,'3HAD40 AND 3HAD60 AND 3HAD80 AND 3HAD100 AND 3HAD120 AND 3HAD121 AND 3HAD140 AND 3HAD141 AND 3HAD160 AND 3HAD161 AND 3HAD180 AND 3HAD181 AND KAS16'
    'XPPTr AND GK2 AND NDPK1',[],0,'GUAPRT'
    'DAGK180',[],0,'EX_12dgr180(e) AND 12DGR180ti'
    [],'METAT',0,'METAT'
    'FOLD3 AND DHPS AND DHFS',[],0,'EX_4abz(e) AND 4ABZt2'
    'GHMT2r AND FOLRrev','r0792',0,'METFR'
    'FOLR3 OR DHFR','r0792',0,'METFR'
    'ENO AND KDOPSr',[],0,'PGM AND PGK'
    [],'ACPpds',0,'ACPpds'
    [],'ACPS1',0,'ACPS1'
    [],'BPNT',0,'BPNT'
    'CHOLSH AND STS1',[],0,'EX_so4(e) AND SO4t2'
    'SPMS',[],0,'EX_spmd(e) AND SPMDabc'
    'UAMAGS AND PEPGLY','GLUR',0,'EX_glu_D(e) AND GLU_Dt2r'
    'GTHP AND TSULST','GTHS',0,'EX_gthrd(e) AND GTHRDt2'
    'ASPTA AND CITL AND TARTD',[],0,'EX_asp_L(e) AND ASPt2r'
    'FACOALAI17 AND FACOALI17',[],0,'KAS1 AND KAS11 AND KAS12 AND KAS3 AND KAS4 AND KAS6 AND ACCOAC'
    'ZN2t4',[],0,'Kt1r'
    'ACS OR XU5PG3PL OR ACGAMK OR ALDD2x OR CITL OR R05219 OR AGDC OR ACKr',[],0,'EX_ac(e) AND ACtr'
    'PRPPS OR RPI OR ADPRDP',[],0,'PPM'
    'CYTK1 AND NTPP4',[],0,'CYTDK1 AND CYTDK2 AND CYTDK3 AND CYTDK4'
    'ADPRDP AND PRPPS',[],0,'AMPN'
    'FTHFL AND METFR AND r0792 AND EX_fol(e)',[],0,'FOLR3'
    'CYTDK2 AND MAN1PT2',[],0,'GK1 AND GK2'
    'G1PACT AND PGAMT AND HEX10','GF6PTA',0,'EX_gam(e) AND GAMpts'
    'BTNCL OR ACCOAC',[],0,'H2CO3D'
    'ALAALA AND UGMDDS','ALAR',0,'EX_ala_D(e) AND DALAt2r'
    'NNDMBRT AND NT5C',[],0,'NAPRT'
    'PUNP5 AND NP1_r AND AMPN',[],0,'EX_rib_D(e) AND RIBabc'
    'ADK1 AND ADPRDP AND NADN AND ACPS1',[],0,'ADNK1 AND DADNK'
    'CDAPPA180 AND PSSA180',[],0,'DASYN120 AND DASYN140 AND DASYN141 AND DASYN160 AND DASYN161 AND DASYN180 AND DASYN181 AND 3OAS60 AND 3OAS80 AND 3OAS100 AND 3OAS120 AND 3OAS121 AND 3OAS140 AND 3OAS141 AND 3OAS160 AND 3OAS161 AND 3OAS180 AND 3OAS181'
    'CHORS AND ICHORS AND SHSL2 AND HSST',[],0,'EX_h2s(e) AND H2St'
    'HEX1 AND BGLA AND PGMT',[],0,'EX_glc_D(e) AND GLCabc'
    'ADK1 AND ACPpds AND PTPAT',[],0,'ADNK1 AND DADNK'
    'METALA1c OR GLYMET1c OR METSOXR1r','METS',0,'EX_met_L(e) AND METt2r'
    'PNTEH','PPNCL3',0,'PTPAT AND DPCOAK AND PPCDC AND PPNCL3 AND PNTK AND EX_pnto_R(e) AND PNTOabc'
    'PUNP1 AND TPRDPCOAS',[],0,'EX_q8(e) AND Q8abc'
    'UHGADA AND U23GAAT AND USHD',[],0,'KAS16'
    'NTPTP1 AND ADK2',[],0,'PPA'
    'GMPS2 AND GUAPRT',[],0,'GK1 AND GK2'
    'FACOAL181 AND LPLIPAL1E181',[],0,'EX_ocdcea(e) AND OCDCEAtr'
    'ACS AND TECA3S180 AND ALAPGPL',[],0,'ADK1 AND ADK2 AND ADK3 AND ADK10 AND ADK11 AND ADK5 AND ADK7 AND ADK8 AND ADK9 AND ADNK1'
    'DAGK180 AND PLIPA2A180',[],0,'DASYN120 AND DASYN140 AND DASYN141 AND DASYN160 AND DASYN161 AND DASYN180 AND DASYN181'
    'DPCOAK','PTPAT',0,'PTPAT AND PPCDC AND PPNCL3 AND PNTK AND EX_pnto_R(e) AND PNTOabc'
    'DAGK180 AND PLIPA2E180',[],0,'DASYN120 AND DASYN140 AND DASYN141 AND DASYN160 AND DASYN161 AND DASYN180 AND DASYN181'
    'EDA_R AND PUNP1 AND PUNP2',[],0,'EX_ade(e) AND ADEt2r'
    '5DOAN AND PUNP1 AND PUNP2',[],0,'EX_ade(e) AND ADEt2r'
    '5DOAN AND ADD AND ADPT AND MTAN',[],0,'EX_ade(e) AND ADEt2r'
    [],'DPCOAK',0,'PTPAT AND PPCDC AND PPNCL3 AND PNTK AND EX_pnto_R(e) AND PNTOabc AND DPCOAK'
    'FBA AND FBP AND GAPD AND TPI',[],0,'PFK'
    'FBA AND TPI AND GAPD AND PGK AND ENO AND PFK(ppi)',[],0,'PGM AND HEX1'
    'N2OO AND EX_n2o(e) AND N2Ot',[],0,'EX_mqn8(e) AND MK8t'
    'AMMQLT8 AND DHORD5 AND FRD2 AND DHORD2 AND DMQMT AND r0220',[],0,'EX_mqn8(e) AND MK8t'
    '6P3HXI AND AB6P3HXLL',[],0,'EX_fald(e) AND r1421'
    'FBP AND GAPD AND PGK AND PGM AND PGMT',[],0,'FBA AND PGI'
    'G6PBDH AND G6PDH2r AND GND',[],0,'PGL'
    'FAO181O AND SQLErev AND FRDPS AND r0145 AND NOt',[],0,'ACS'
    'ADD AND ADPRDP AND PRPPS AND TKT1 AND TKT2',[],0,'TALA'
    'NADN AND NNDMBRT AND NAPRT AND NNATr AND NMNAT',[],0,'EX_nmn(e) AND NMNP'
    'ASPTA AND LEUTA AND PHETA1 AND OIVD1r AND EHGLAT AND XU5PG3PL AND 2HMCOXT','AKGS',0,'GLUDxi AND GLUDy'
    'DPMVDc AND MEVK1c AND PMEVKc AND HMGL AND FRTT AND IPDDI AND r0488',[],0,'HMGCOAS'
    'TECA5S180','TECA1S180',0,'TECA1S140 AND TECA1S160 AND TECA1S180 AND TECA1SAI15 AND TECA1SAI17 AND TECA1SI14 AND TECA1SI15 AND TECA1SI17 AND TECA2S140 AND TECA2S160 AND TECA2S180 AND TECA2SAI15 AND TECA2SAI17 AND TECA2SI14 AND TECA2SI15 AND TECA2SI17 AND TECA3S140 AND TECA3S160 AND TECA3S180 AND TECA3SAI15 AND TECA3SAI17 AND TECA3SI14 AND TECA3SI15 AND TECA3SI17 AND TECAAE AND TECAGE AND TECAUE AND TECA4S AND SUDPDGT AND SUDPMGT AND AIHDUDPMG AND AIHDUPDG AND AIPDUDPG AND AIPDUDPMG AND IHDUDPG AND IHDUDPMG AND IPDUDPG AND IPDUDPMG AND ITDUDPG AND ITDUDPMG AND IXDUDPG AND IXDUDPMG AND G3PCT AND CDPGLYCGPT AND UACMAMAT AND PGPGT AND ALAPGPL'
    '26DAPLLAT AND DHDPRy AND ASNS1 AND VALTA',[],0,'EX_val_L(e) AND VALt2r'
    'ACCOACL AND MCOATA AND KAS16','BTNCL',0,'ACCOAC AND H2CO3D'
    'ACCOACL AND MCOATA AND KAS16','BTNCL',0,'BTNCL AND H2CO3D'
    'G1PACT AND UAGDP AND TECA4S AND UAGCVT_r',[],0,'PGAMT'
    'DCMPDA AND NTD1 AND URIDK2 AND DCMPDA',[],0,'DURIK1'
    'AHC AND GNMT AND DMQMT AND HCYSMT',[],0,'DM_hcys_L[c]'
    'MCOATA AND H2CO3D',[],0,'ACCOAC'
    'ACTNabc',[],0,'ACTNdiff'
    };

for i=2:size(conditionSpecificGapfills,1)
    GF_rxns=strsplit(conditionSpecificGapfills{i,4},' AND ');
    GF_rxns=strcat(GF_rxns,'_csGF');
    if any(contains(model.rxns, GF_rxns))
        modelTest = removeRxns(model,GF_rxns);
        FBA = optimizeCbModel(modelTest, osenseStr);
        if abs(FBA.f) > tol
            model = modelTest;
        end
    end
end

% now test the reactions added through targeted gapfilling
GF_rxns=model.rxns(find(contains(model.rxns,'_tGF')));
for i=1:length(GF_rxns)
    modelTest = removeRxns(model,GF_rxns);
    FBA = optimizeCbModel(modelTest, osenseStr);
    if abs(FBA.f) > tol
        model = modelTest;
    end
end

% now test the reactions added through untargeted gapfilling
GF_rxns=model.rxns(find(contains(model.rxns,'_untGF')));
for i=1:length(GF_rxns)
    modelTest = removeRxns(model,GF_rxns);
    FBA = optimizeCbModel(modelTest, osenseStr);
    if abs(FBA.f) > tol
        model = modelTest;
    end
end

% export the gapfill IDs
condGF = model.rxns(contains(model.rxns,'_csGF'));
targetGF = model.rxns(contains(model.rxns,'_tGF'));
relaxGF = model.rxns(contains(model.rxns,'_untGF'));

% remove the "gapfilled" IDs
for n = 1:length(model.rxns)
    if ~isempty(strfind(model.rxns{n, 1}, '_csGF'))
        removeGF = strsplit(model.rxns{n, 1}, '_csGF');
        model.rxns{n, 1} = removeGF{1, 1};
        model.grRules{n, 1} = 'demeterGapfill';
    end
    if ~isempty(strfind(model.rxns{n, 1}, '_tGF'))
        removeGF = strsplit(model.rxns{n, 1}, '_tGF');
        model.rxns{n, 1} = removeGF{1, 1};
        model.grRules{n, 1} = 'demeterGapfill';
    end
    if ~isempty(strfind(model.rxns{n, 1}, '_untGF'))
        removeGF = strsplit(model.rxns{n, 1}, '_untGF');
        model.rxns{n, 1} = removeGF{1, 1};
        model.grRules{n, 1} = 'demeterGapfill';
    end
end

end

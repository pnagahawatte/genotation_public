DROP PROCEDURE `getPathwayBySymbol`;
DROP PROCEDURE `getSynonymsBySymbol`;
DROP PROCEDURE `getCV_Event_DetailsBySymbol`;
DROP PROCEDURE `getCV_VariantBySymbol`;
DROP PROCEDURE `getKegg_DiseaseBySymbol`;
DROP PROCEDURE `getMedgenDiseaseBySymbol`;
DROP PROCEDURE `getPathwayByGneomeID`;
DROP PROCEDURE `getSynonymsByGneomeID`;
DROP PROCEDURE `getCV_Event_DetailsByGneomeID`;
DROP PROCEDURE `getCV_VariantByGneomeID`;
DROP PROCEDURE `getKegg_DiseaseByGneomeID`;
DROP PROCEDURE `getMedgenDiseaseByGneomeID`;

DELIMITER //
CREATE PROCEDURE `getPathwayBySymbol` (IN gene_symbol VARCHAR(30))
BEGIN
    SELECT * FROM annotation_pathways as AP 
	INNER JOIN GeneMain as GM 
	ON AP.gneomeID = GM.gneomeID
	where GM.symbol = gene_symbol;
END//

DELIMITER //
CREATE PROCEDURE `getSynonymsBySymbol` (IN gene_symbol VARCHAR(30))
BEGIN
    SELECT GS.symbol FROM GeneSynonym as GS 
	INNER JOIN GeneMain as GM 
	ON GS.gneomeID = GM.gneomeID
	where GM.symbol = gene_symbol;
END//

DELIMITER //
CREATE PROCEDURE `getCV_Event_DetailsBySymbol` 
	(IN gene_symbol VARCHAR(30), IN variant_class VARCHAR(20))
BEGIN
    SELECT clnsig,clnorigin,nsf,nsm,nsn,common 
	FROM CV_event_details as CE_D 
	INNER JOIN CV_event_gene as  CE_G
	ON CE_D.gneomecvid = CE_G.gneomecvid
	INNER JOIN genemain as GM
	ON CE_G.gneomeid = GM.gneomeid
	where GM.symbol = gene_symbol AND
	CE_D.vc = variant_class;
END//

DELIMITER //
CREATE PROCEDURE `getCV_VariantBySymbol` (IN gene_symbol VARCHAR(30))
BEGIN
    SELECT rsID, chrom, rspos FROM CV_variant as C_V 
	INNER JOIN CV_event_gene as  CE_G
	ON CE_G.gneomecvid = C_V.gneomecvid
	INNER JOIN genemain as GM
	ON CE_G.gneomeid = GM.gneomeid
	where GM.symbol = gene_symbol;
END//

DELIMITER //
CREATE PROCEDURE `getKegg_DiseaseBySymbol` (IN gene_symbol VARCHAR(30))
BEGIN
    SELECT name, description, category, envFactor, comment, K_D.keggDiseaseID
	FROM KeggDisease AS K_D 
	INNER JOIN KeggGene as  K_G
	ON K_G.keggDiseaseID = K_D.keggDiseaseID
	INNER JOIN genemain as GM
	ON K_G.gneomeid = GM.gneomeid
	where GM.symbol = gene_symbol;
END//

DELIMITER //
CREATE PROCEDURE `getMedgenDiseaseBySymbol` (IN gene_symbol VARCHAR(30))
BEGIN
    SELECT medgenID, diseaseName, diseaseMIM
	FROM medgen_gene_disease AS MG_G_D 
	INNER JOIN GeneExternalID as  G_E_I
	ON MG_G_D.externalID = G_E_I.externalID
	INNER JOIN genemain as GM
	ON G_E_I.gneomeid = GM.gneomeid
	where GM.symbol = gene_symbol;
END//

DELIMITER //
CREATE PROCEDURE `getPathwayByGneomeID` (IN gneome_id VARCHAR(30))
BEGIN
    SELECT * FROM annotation_pathways as AP 
	where AP.gneomeID = gneome_id;
END//

DELIMITER //
CREATE PROCEDURE `getSynonymsByGneomeID` (IN gneome_id VARCHAR(30))
BEGIN
    SELECT GS.symbol FROM GeneSynonym as GS 
	where GS.gneomeID = gneome_id;
END//

DELIMITER //
CREATE PROCEDURE `getCV_Event_DetailsByGneomeID` 
	(IN gneome_id VARCHAR(30), IN variant_class VARCHAR(20))
BEGIN
    SELECT clnsig,clnorigin,nsf,nsm,nsn,common 
	FROM CV_event_details as CE_D 
	INNER JOIN CV_event_gene as  CE_G
	ON CE_D.gneomecvid = CE_G.gneomecvid
	where CE_G.gneomeid = gneome_id AND
	CE_D.vc = variant_class;
END//

DELIMITER //
CREATE PROCEDURE `getCV_VariantByGneomeID` (IN gneome_id VARCHAR(30))
BEGIN
    SELECT rsID, chrom, rspos FROM CV_variant as C_V 
	INNER JOIN CV_event_gene as  CE_G
	ON CE_G.gneomecvid = C_V.gneomecvid
	INNER JOIN CV_event_details as CE_D
	ON CE_D.gneomeCVID = C_V.gneomeCVID
	where CE_G.gneomeid = gneome_id AND
	(CE_D.nsm = 1 OR CE_D.nsf = 1 OR CE_D.nsn = 1);
END//

DELIMITER //
CREATE PROCEDURE `getKegg_DiseaseByGneomeID` (IN gneome_id VARCHAR(30))
BEGIN
    SELECT name, description, category, envFactor, comment, K_D.keggDiseaseID
	FROM KEGGdisease AS K_D 
	INNER JOIN KEGGgene as  K_G
	ON K_G.keggDiseaseID = K_D.keggDiseaseID
	where K_G.gneomeid = gneome_id;
END//

DELIMITER //
CREATE PROCEDURE `getMedgenDiseaseByGneomeID` (IN gneome_id VARCHAR(30))
BEGIN
    SELECT medgenID, diseaseName, diseaseMIM
	FROM MEDGEN_gene_disease AS MG_G_D 
	INNER JOIN GeneExternalID as  G_E_I
	ON MG_G_D.externalID = G_E_I.externalID
	where G_E_I.gneomeid = gneome_id;
END//

DELIMITER //
CREATE PROCEDURE `getUniprotByGneomeID` (IN gneome_id VARCHAR(30))
BEGIN
    SELECT uniprot_entry, uniprot_description
	FROM uniprot where gneomeID = gneome_id;
END//

DELIMITER //
CREATE PROCEDURE `getPharmGKBRelationshipByGneomeID` (IN gneome_id VARCHAR(30))
BEGIN
    SELECT entityName, entityID
	FROM pharmgkb_relationship where gneomeID = gneome_id;
END//
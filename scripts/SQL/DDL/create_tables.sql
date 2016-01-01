CREATE TABLE IF NOT EXISTS GeneMain
(
	gneomeID INT  AUTO_INCREMENT,
	symbol VARCHAR(30) NOT NULL,
	taxID varchar(10) NOT NULL,
	CONSTRAINT uc_symbol UNIQUE(symbol, taxID),
	CONSTRAINT pk_gneomeID PRIMARY KEY(gneomeID)
);

CREATE TABLE IF NOT EXISTS DrugMain
(
	accessionID VARCHAR(15) NOT NULL,
	drugname VARCHAR(50) NOT NULL,
	source varchar(10) NOT NULL,
	CONSTRAINT uc_symbol UNIQUE(accessionID, drugname)
);

CREATE TABLE IF NOT EXISTS GeneDetail
(
	gneomeID INT NOT NULL,
	description VARCHAR(150),
	genetype VARCHAR(100),
	genegroup VARCHAR(100),
	chromosome VARCHAR(35),
	CONSTRAINT pk_geneDetail PRIMARY KEY(gneomeID)
);

CREATE TABLE IF NOT EXISTS GeneExternalID
(
	gneomeID INT NOT NULL,
	externalID VARCHAR(50) NOT NULL COMMENT 'Gene id assigned by an external database',
	externaldbID VARCHAR(50) NOT NULL COMMENT 'The ID of the external database',
	CONSTRAINT uc_externalID UNIQUE(gneomeID, externalID, externaldbID)
);

CREATE TABLE IF NOT EXISTS GeneSynonym
(
	gneomeID INT NOT NULL COMMENT 'ID of the main gene',
	symbol VARCHAR(45) NOT NULL COMMENT 'Synonym symbol',
	taxID varchar(10) NOT NULL
);

CREATE TABLE IF NOT EXISTS CV_variant
(
	gneomeCVID INT AUTO_INCREMENT COMMENT 'Internal ID for the clinvar variant',
	rsID VARCHAR(20) NOT NULL,
	chrom VARCHAR(45) NOT NULL COMMENT 'Reference seq',
	rspos VARCHAR(20) NOT NULL,
	CONSTRAINT pk_gneome_CV_ID PRIMARY KEY(gneomeCVID)
);

CREATE TABLE IF NOT EXISTS CV_external_db
(
	gneomeCVID INT  COMMENT 'Internal ID for the clinvar variant',
	externalID VARCHAR(20) NOT NULL,
	externaldbID VARCHAR(50) NOT NULL,
	CONSTRAINT uc_external_id UNIQUE(gneomeCVID, externalID, externaldbID)
);

CREATE TABLE IF NOT EXISTS CV_event_gene
(
	gneomeCVID INT NOT NULL COMMENT 'Internal ID for the clinvar variant',
	gneomeID INT NOT NULL COMMENT 'Internal gene id for the gene symbol',
	externalID VARCHAR(20) NOT NULL,
	externaldbID VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS CV_event_details
(
	gneomeCVID INT  COMMENT 'Internal ID for the clinvar variant',
	clnsig VARCHAR(20) NOT NULL,
	clnorigin VARCHAR(20) NOT NULL,
	vc VARCHAR(20) NOT NULL,
	nsf BOOLEAN NOT NULL,
	nsm BOOLEAN NOT NULL,
	nsn BOOLEAN NOT NULL,
	common BOOLEAN NOT NULL,
	pm BOOLEAN NOT NULL,
	CONSTRAINT pk_external_id PRIMARY KEY(gneomeCVID)
);

CREATE TABLE IF NOT EXISTS MEDGEN_gene_disease
(
	externalID VARCHAR(20) NOT NULL,
	externaldbID VARCHAR(20) NOT NULL,
	medgenID VARCHAR(20) NOT NULL COMMENT 'Medgen concept unique id',
	diseaseName VARCHAR(200) NOT NULL,
	sourceDB VARCHAR(30) NOT NULL,
	sourceID VARCHAR(20) NOT NULL,
	diseaseMIM INT NOT NULL
);

CREATE TABLE IF NOT EXISTS KEGGdisease
(
	gneomeKeggDiseaseID INT NOT NULL AUTO_INCREMENT,
	keggDiseaseID VARCHAR(10) NOT NULL,
	name VARCHAR(150) NOT NULL,
	description TEXT NOT NULL,
	category VARCHAR(20) NOT NULL COMMENT 'Disease category',
	envFactor TEXT COMMENT 'Environmental factors leading to disease',
	comment TEXT,
	CONSTRAINT pk_gneomeKeggDiseaseID PRIMARY KEY(gneomekeggDiseaseID),
	CONSTRAINT uc_keggDiseaseID UNIQUE(keggDiseaseID)
);

CREATE TABLE IF NOT EXISTS KEGGpathway
(
	keggDiseaseID VARCHAR(10) NOT NULL,
	pathway VARCHAR(50) NOT NULL,
	description varchar(100) NOT NULL COMMENT 'Description of the kegg pathway',
	CONSTRAINT uc_keggpathway UNIQUE(keggDiseaseID, pathway)
);

CREATE TABLE IF NOT EXISTS KEGGgene
(
	keggDiseaseID VARCHAR(10) NOT NULL,
	gneomeID INT NOT NULL COMMENT 'Internal gneomeID for the gene symbol',
	keggGeneID VARCHAR(15) NOT NULL COMMENT 'KEGG hsa:ID for the gene',
	keggOrthologyID VARCHAR(15) NOT NULL COMMENT 'KEGG ko:ID'
);

CREATE TABLE IF NOT EXISTS KEGGdrug
(
	keggDiseaseID VARCHAR(10) NOT NULL,
	drug varchar(20) NOT NULL COMMENT 'Drug ID',
	description varchar(50) NOT NULL COMMENT 'Description of the drug',
	keggDrugID VARCHAR(20) NOT NULL COMMENT 'KEGG id for the drug: DR:D[0-9]*'
);

CREATE TABLE IF NOT EXISTS KEGGmarker
(
	keggDiseaseID VARCHAR(10) NOT NULL,
	description varchar(50) NOT NULL COMMENT 'Description of the marker'
);

CREATE TABLE IF NOT EXISTS KEGGmarkerGene
(
	keggDiseaseID VARCHAR(10) NOT NULL COMMENT 'Will act as the foreign key to the Keggmarker table', 
	keggGeneID VARCHAR(20) NOT NULL COMMENT 'KEGG gene id that is HSA:[0-9]*',
	gneomeID INT NOT NULL COMMENT 'The gneome ID for the gene'
);

CREATE TABLE IF NOT EXISTS KEGGreference
(
	keggDiseaseID VARCHAR(10) NOT NULL,
	pubmedID VARCHAR(20) NOT NULL,
	description VARCHAR(25),
	CONSTRAINT uc_keggreference UNIQUE(keggDiseaseID, pubmedID, description)
);

CREATE TABLE IF NOT EXISTS util_common_words
(
	word VARCHAR(30) NOT NULL,
	CONSTRAINT uc_word UNIQUE(word)
);

CREATE TABLE IF NOT EXISTS util_country_names
(
	text VARCHAR(50),
	CONSTRAINT uc_country_names unique(text)
);

CREATE TABLE IF NOT EXISTS util_all_caps_symbols
(
	symbol VARCHAR(30),
	CONSTRAINT uc_symbol unique(symbol)
);

CREATE TABLE IF NOT EXISTS annotation_pathways
(
	pathwayID VARCHAR(30) NOT NULL,
	pathwayDescription VARCHAR(250) NOT NULL,
	gneomeID INT NOT NULL,
	origin VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS taxonomy
(
	taxID VARCHAR(10) NOT NULL,
	commonName VARCHAR(100) NOT NULL,
	species VARCHAR(100) NOT NULL,
	CONSTRAINT pk_taxonomyID PRIMARY KEY(taxID)
);

CREATE TABLE IF NOT EXISTS uniprot
(
	uniprot_entry VARCHAR(10) NOT NULL,
	gneomeID INT NOT NULL
);

CREATE TABLE IF NOT EXISTS pharmgkb_relationship
(
	gneomeID INT NOT NULL COMMENT 'Internal gneomeID for the gene symbol',
	entityName varchar(100) NOT NULL,
	entityID varchar(15) NOT NULL
);
ALTER TABLE geneExternalID
ADD CONSTRAINT fk_gene_main_external_id FOREIGN KEY (gneomeID) REFERENCES geneMain(gneomeID);

ALTER TABLE geneSynonym
ADD CONSTRAINT fk_gene_main_synonym FOREIGN KEY (gneomeID) REFERENCES geneMain(gneomeID);

ALTER TABLE geneDetail
ADD CONSTRAINT fk_gene_main_detail FOREIGN KEY (gneomeID) REFERENCES geneMain(gneomeID);

ALTER TABLE externalid
ADD CONSTRAINT fk_gene_main_external_id FOREIGN KEY (gneomeID) REFERENCES geneMain(gneomeID);

ALTER TABLE keggDrug
ADD CONSTRAINT fk_kegg_disease_drug FOREIGN KEY (keggDiseaseID) REFERENCES keggDisease(keggDiseaseID);

ALTER TABLE keggGene
ADD CONSTRAINT fk_kegg_disease_gene FOREIGN KEY (keggDiseaseID) REFERENCES keggDisease(keggDiseaseID);

ALTER TABLE keggPathway
ADD CONSTRAINT fk_kegg_disease_pathway FOREIGN KEY (keggDiseaseID) REFERENCES keggDisease(keggDiseaseID);

ALTER TABLE keggReference
ADD CONSTRAINT fk_kegg_disease_reference FOREIGN KEY (keggDiseaseID) REFERENCES keggDisease(keggDiseaseID);

ALTER TABLE cv_event_details
ADD CONSTRAINT fk_cv_variant_details FOREIGN KEY (gneomeCVID) REFERENCES cv_variant(gneomeCVID);

ALTER TABLE cv_event_gene
ADD CONSTRAINT fk_cv_variant_gene FOREIGN KEY (gneomeCVID) REFERENCES cv_variant(gneomeCVID);

ALTER TABLE cv_external_db
ADD CONSTRAINT fk_cv_variant_external_db FOREIGN KEY (gneomeCVID) REFERENCES cv_variant(gneomeCVID);

ALTER TABLE cv_external_db
ADD CONSTRAINT fk_cv_variant_external_db FOREIGN KEY (gneomeCVID) REFERENCES cv_variant(gneomeCVID);

ALTER TABLE annotation_pathways
ADD CONSTRAINT fk_gene_main_gneome_id FOREIGN KEY (gneomeID) REFERENCES geneMain(gneomeID);

ALTER TABLE GeneMain
ADD CONSTRAINT fk_taxonomy_gene_main FOREIGN KEY (taxID) REFERENCES taxonomy(taxID);

ALTER TABLE KEGGmarker
ADD CONSTRAINT fk_kegg_marker_disease FOREIGN KEY (keggDiseaseID) REFERENCES KEGGdisease(keggDiseaseID);

ALTER TABLE KEGGreference
ADD CONSTRAINT fk_kegg_reference_disease FOREIGN KEY (keggDiseaseID) REFERENCES KEGGdisease(keggDiseaseID);

DROP INDEX IF EXISTS  gd_main_index;
CREATE INDEX gd_main_index ON geneDetail(gneomeID, genetype, genegroup, chromosome);

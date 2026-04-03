# Patho2Clade
Pathogen Lineage &amp; Clade Assignment Pipeline

Patho2Clade is a command‑line pipeline for performing **offline lineage/clade assignment** for pathogen genomes using a combination of:

- **Snippy** — SNP calling from assembled genomes  
- **Usher** — phylogenetic placement  
- **matUtils** — clade/lineage extraction  

Originally developed for *Vibrio cholerae*, Patho2Clade is designed to be **easily extensible to other pathogens** by supplying the appropriate reference genome and phylogenetic tree.

---

## ✅ Features

- Batch processing of FASTA assemblies  
- Fully offline lineage detection  
- Automatic SNP calling and phylogenetic placement  
- Clade extraction from USHER placement  
- Generates renamed FASTA files containing the assigned clade  
- Supports any pathogen with available reference + UShER tree  
- Minimal dependencies, easy to install

---

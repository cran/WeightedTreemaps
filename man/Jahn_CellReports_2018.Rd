% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/data.R
\docType{data}
\name{Jahn_CellReports_2018}
\alias{Jahn_CellReports_2018}
\title{Data from the publication of Jahn et al., CellReports, 2018}
\format{
A data frame with 19790 rows and 12 variables
}
\source{
\url{https://pubmed.ncbi.nlm.nih.gov/30304686/}
}
\usage{
data(Jahn_CellReports_2018)
}
\description{
The dataset contains protein abundances of the Synechocystis sp.
PCC6803 proteome. Protein abundance was determined using shotgun
mass spectrometry. The data set also contains pathway information according to
the cyanobase hierarchical annotation:
}
\details{
\itemize{
  \item protein - protein ID
  \item condition - combination from light and CO2
  \item light - light intensity in umol photons / m2 * s
  \item co2_concentration - CO2 concentration in % vol
  \item mean_intensity - mean MS1 ion intensity
  \item mean_mass_fraction_norm - normalized mean mass fraction of protein
  \item sd_intensity - standard deviation from mean
  \item Process - functional annotation 1st level
  \item Pathway - functional annotation 2nd level
  \item Protein - functional annotation 3rd level
  \item Process.abbr - abbreviated Process
  \item Pathway.abbr - abbreviated Pathway
  \item Gene.names - trivial names of genes, if available
}
}
\keyword{datasets}

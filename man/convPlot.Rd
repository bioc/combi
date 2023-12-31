% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/convPlot.R
\name{convPlot}
\alias{convPlot}
\title{Plot the convegrence of the different parameter estimates in a line plot}
\usage{
convPlot(
  model,
  latent = is.null(View),
  nVars = Inf,
  Dim = 1L,
  View = NULL,
  size = 0.125
)
}
\arguments{
\item{model}{A fitted modelDI object}

\item{latent}{A boolean, should latent variable trajectory be plotted}

\item{nVars}{An integer, the number of variables to plot. By default all are plotted}

\item{Dim}{An integer, the dimension to be plotted}

\item{View}{An integer or character string, indicating the view
to be plotted (if latent = FALSE)}

\item{size}{The line size (see ?geom_path)}
}
\value{
A ggplot object containing the convergence plot
}
\description{
Plot the convegrence of the different parameter estimates in a line plot
}
\examples{
\dontrun{
data(Zhang)
#Unconstrained
microMetaboInt = combi(
list("microbiome" = zhangMicrobio, "metabolomics" = zhangMetabo),
distributions = c("quasi", "gaussian"), compositional = c(TRUE, FALSE),
logTransformGaussian = FALSE, verbose = TRUE)}
load(system.file("extdata", "zhangFits.RData", package = "combi"))
convPlot(microMetaboInt)
convPlot(microMetaboInt, Dim = 2)
convPlot(microMetaboInt, View = "microbiome")
}

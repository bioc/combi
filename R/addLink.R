#' Add a link on a compositional plot
#'@param DIplot A list with ggplot object where the links are to be added,
#'and data frames with coordinates (obtained by setting plot(..., returnCoords = TRUE))
#'@param links A matrix containing either feature names (two column matrix)
#'or approximate coordinates (four column matrix)
#'@param Views Indices or names of the views for which the links should be added
#'@param samples Sample names or approximate sample coordinates
#'@param variable Name of variable in environmental gradient for which link
#'should be plotted
#'@param Dims vector of length 2 referring to the model dimensions
#'@param addLabel A boolean, should arrow with label be plotted?
#'@param labPos The position of the label, as a numeric vector of length 2
#'@param projColour The colour of the projection, as character string
#'@param latentSize Size of the line from the origin to the latent variable dot
#'
#'@return A ggplot object with the links added
#'
#'@export
#' @examples
#' data(Zhang)
#' \dontrun{
#' #Unconstrained
#' microMetaboInt = combi(
#' list("microbiome" = zhangMicrobio, "metabolomics" = zhangMetabo),
#' distributions = c("quasi", "gaussian"), compositional = c(TRUE, FALSE),
#' logTransformGaussian = FALSE, verbose = TRUE)
#' }
#' load(system.file("extdata", "zhangFits.RData", package = "combi"))
#' Plot = plot(microMetaboInt, samDf = zhangMetavars, samCol = "ABX",
#'  returnCoords = TRUE)
#' addLink(Plot, links = cbind("OTU0565b3","OTUa14fb5"), Views = 1,
#'  samples = c(1,1))
#'@import ggplot2
addLink = function(DIplot, links, Views, samples, variable = NULL, Dims = c(1,2),
                   addLabel = FALSE, labPos = NULL, projColour = "grey",
                   latentSize = 0.25) {
    #Checks for the exported function
    stopifnot(is.matrix(links),
              is.numeric(Views) | is.character(Views), is.vector(samples),
              is.character(variable) | is.null(variable), length(Dims)==2,
              is.logical(addLabel),
              is.null(labPos) | (is.numeric(labPos) && length(labPos)==2),
              is.numeric(latentSize))
    if(any(names(DIplot) != c("Plot", "latentData", "featureData", "varData"))){
        stop("Provide list of plot and coordinates, obtained by calling
             plot(..., returnCoords = TRUE) on a combi object!")
    }
    dimNames = paste0("Dim", Dims)
    if(length(Views) == 1L) {
        Views = rep(Views, 2)
    } else if(length(Views) != 2L){
        stop("Please provide two views indicators")
        }
    if(is.numeric(links)){
        if(ncol(links) != 4L){
            stop("Provide numeric links matrix with four columns: first x and y of one taxon and then another.")
        }
        links1 = which.min(colSums((t(DIplot$featureData[[Views[1]]][,dimNames]) - links[,c(1,2)])^2))
        links2 = which.min(colSums((t(DIplot$featureData[[Views[2]]][,dimNames]) - links[,3:4])^2))
        # Closest to approximate coordinate
        linkNames = cbind((DIplot$featureData[[Views[1]]]$featNames)[links1],
                          (DIplot$featureData[[Views[2]]]$featNames)[links2])
    } else if(is.character(links)){
        if(ncol(links) != 2L){
            stop("Provide character links matrix with two columns.")
        }
        linkNames = links
    } else {
        stop("Provide links as two-column character of four column numeric matrix!")
    }
    if (is.numeric(samples)) {
        samples = which.min(colSums((t(DIplot$latentData[, dimNames]) - samples)^2))
        # Closest to approximate coordinate
        sampleNames = rownames(DIplot$latentData)[samples]
    } else {
        sampleNames = samples
    }

    if (is.numeric(variable)) {
        variable = which.min(colSums((t(DIplot$variables[,
                                                          dimNames]) - species)^2))
        # Closest to approximate coordinate
        varName = rownames(DIplot$variables)[variable]
    } else {
        varName = variable
    }

    #Exact coordinates
    sampleMat = if(is.null(variable)){
        DIplot$latentData[sampleNames, dimNames]
    } else {
        DIplot$varData[varName, dimNames]
    }
    linkMat = apply(linkNames, 1, function(ln){
                tmp = unlist(vapply(seq_along(Views), FUN.VALUE = numeric(2),
                                    function(i){
                    if(!(ln[i] %in% rownames((DIplot$featureData[[Views[i]]])))){
                        stop("Feature '", ln[i], "' not plotted!
                        Please check spelling or provide numeric coordinates.")
                    }
                    unlist(DIplot$featureData[[Views[i]]][ln[i], dimNames])
                }))
                names(tmp) = c("x", "y", "xend", "yend")
                tmp
        })
    #Draw the links between the features
    DIplot$Plot = DIplot$Plot + geom_segment(inherit.aes = FALSE,
                                               mapping = aes_string(x = "x", y = "y",
                                                                    xend = "xend", yend = "yend"),
                                               data = data.frame(t(linkMat)), linetype = "dotdash",
                                             col = "red")
    #Draw the line from the origin to the sample
    DIplot$Plot = DIplot$Plot + geom_segment(inherit.aes = FALSE,
                                             mapping = aes_string(x = 0, y = 0,
                                                                  xend = dimNames[1], yend = dimNames[2]),
                                             data = data.frame(sampleMat), size = latentSize)
    #Find the coordinates of the projections
    ## The slopes and intercepts of the links
    linkIntSlopes = apply(linkMat, 2, function(l){
        slope = (l["yend"]-l["y"])/(l["xend"]-l["x"])
        tmp = c(slope, l["y"]- slope*l["x"])
        names(tmp)  = c("slope", "intercept")
        tmp
    })
    ## The slope of the samples
    sampleSlopes = sampleMat[,2]/sampleMat[,1]
    # The coordinates of the intercept between projection and sample
    IntCoords = vapply(sampleSlopes, FUN.VALUE = numeric(4), function(l){
        Dim1 = (unname(linkMat[ c("y", "yend"),]+1/l*linkMat[ c("x", "xend"),])-0)/(1/l + l)
        Dim2 = Dim1*l
c(x1 = Dim1[1], x2 = Dim1[2], y1 = Dim2[1], y2 = Dim2[2])
    })
    dfTip = data.frame(x = linkMat["x",], y = linkMat["y",], xend = IntCoords["x1",], yend = IntCoords["y1",])
    dfStart = data.frame(x = linkMat["xend",], y = linkMat["yend",],
                         xend = IntCoords["x2",], yend = IntCoords["y2",])
    #The projection lines
    DIplot$Plot = DIplot$Plot + geom_segment(inherit.aes = FALSE,
                                               mapping = aes_string(x = "x", y = "y",
                                                                    xend = "xend", yend = "yend"),
                                               data = dfTip, linetype = "dashed", col = projColour)
    DIplot$Plot = DIplot$Plot + geom_segment(inherit.aes = FALSE,
                                               mapping = aes_string(x = "x", y = "y",
                                                                    xend = "xend", yend = "yend"),
                                               data = dfStart, linetype = "dashed", col = projColour)
    # Add a orange line for the projection
    DIplot$Plot = DIplot$Plot + geom_segment(inherit.aes = FALSE,
                                               col = "orange", mapping = aes_string(x = "x1",
                                                                                    y = "y1", xend = "x2", yend = "y2"),
                                               data = data.frame(t(IntCoords)), size = 0.25)
    if (addLabel) {
        # Add some annotation
        labPos = if (is.null(labPos)) {
            apply(DIplot$samples[, dimNames],
                  2, min) * 1.1
        } else {
            labPos
        }
        xLab = labPos[1]
        yLab = labPos[2]
        dfRed = within(dfRed, {
            xLab = xLab * 2
            yLab = yLab * 2
        })
        DIplot$plot = DIplot$plot +
            geom_segment(inherit.aes = FALSE,
                         mapping = aes_string(x = "xLab", y = "yLab",
                                              xend = "xend", yend = "yend"),
                         data = dfRed/2, arrow = arrow(length = unit(0.2,"cm")),
                         size = 0.25) + annotate("text", col = "orange",
                                                 label = "r~psi~s", x = xLab,
                                                 y = yLab, parse = TRUE,
                                                 size = 7)
    }
    DIplot$Plot
}
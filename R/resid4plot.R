#
#
#   Residual plots:
#         resid4plot       four panels with matching coordinates
#         resid1plot       one or more unrelated individual plots 
#         resid1panel      one panel of resid1plot
#
#   $Revision: 1.32 $    $Date: 2015/08/18 08:00:19 $
#
#

resid4plot <- local({

  Contour <- function(...,
                      pch, chars, cols, etch, size,
                      maxsize, meansize, markscale, symap, zap,
                      legend, leg.side, leg.args) {
    ## avoid passing arguments of plot.ppp to contour.default
    contour(...)
  }

  do.clean <- function(fun, ..., 
                       pch, chars, cols, etch, size,
                       maxsize, meansize, markscale, symap, zap,
                       legend, leg.side, leg.args,
                       nlevels, levels, labels, drawlabels, labcex) {
    ## avoid passing arguments of plot.ppp, contour.default to other functions
    do.call(fun, list(...)) 
  }

  do.lines <- function(x, y, defaulty=1, ...) {
    do.call("lines",
            resolve.defaults(list(x, y),
                             list(...),
                             list(lty=defaulty)))
  }

  resid4plot <-
    function(RES,
             plot.neg=c("image", "discrete", "contour", "imagecontour"),
             plot.smooth=c("imagecontour", "image", "contour", "persp"),
             spacing=0.1, outer=3, srange=NULL, monochrome=FALSE, main=NULL,
             xlab="x coordinate", ylab="y coordinate", rlab,
             col.neg=NULL, col.smooth=NULL,
             ...)
{
  plot.neg <- match.arg(plot.neg)
  if(missing(rlab)) rlab <- NULL
  rlablines <- if(is.null(rlab)) 1 else sum(nzchar(rlab))
  clip     <- RES$clip
  Yclip    <- RES$Yclip
  Z        <- RES$smooth$Z
  W        <- RES$W
  Wclip    <- Yclip$window
  type     <- RES$type
  typename <- RES$typename
  Ydens    <- RES$Ydens[Wclip, drop=FALSE]
  Ymass    <- RES$Ymass[Wclip]
  # set up 2 x 2 plot with space
  wide <- diff(W$xrange)
  high <- diff(W$yrange)
  space <- spacing * max(wide,high)
  width <- wide + space + wide
  height <- high + space + high
  outerspace <- outer * space
  outerRspace <- (outer - 1 + rlablines) * space
  plot(c(0, width) + c(-outerRspace, outerspace),
       c(0, height) + c(-outerspace, outerRspace),
       type="n", asp=1.0, axes=FALSE, xlab="", ylab="")
  # determine colour map for background
  if(is.null(srange)) {
    Yrange <- if(!is.null(Ydens)) summary(Ydens)$range else NULL
    Zrange <- if(!is.null(Z)) summary(Z)$range else NULL
    srange <- range(c(0, Yrange, Zrange), na.rm=TRUE)
  } else {
    stopifnot(is.numeric(srange) && length(srange) == 2)
    stopifnot(all(is.finite(srange)))
  }
  backcols <- beachcolours(srange, if(type=="eem") 1 else 0, monochrome)
  if(is.null(col.neg)) col.neg <- backcols
  if(is.null(col.smooth)) col.smooth <- backcols
  
  # ------ plot residuals/marks (in top left panel) ------------
  Xlowleft <- c(W$xrange[1],W$yrange[1])
  vec <- c(0, high) + c(0, space) - Xlowleft
  # shift the original window
  Ws <- shift(W, vec)
  # shift the residuals 
  Ys <- shift(Yclip,vec)

  # determine whether pre-plotting the window(s) is redundant
  redundant <- 
    (plot.neg == "image") && (type != "eem") && (Yclip$window$type == "mask")

  # pre-plot the window(s)
  if(!redundant) {
    if(!clip) 
      do.clean(plot, Ys$window, add=TRUE, ...)
    else
      do.clean(ploterodewin, Ws, Ys$window, add=TRUE, ...)
  }

  ## adjust position of legend associated with eroded window
  sep <- if(clip) Wclip$yrange[1] - W$yrange[1] else NULL
  
  ## decide whether mark scale should be shown
  showscale <- (type != "raw")
  
  switch(plot.neg,
         discrete={
           neg <- (Ys$marks < 0)
           ## plot negative masses of discretised measure as squares
           if(any(c("maxsize","meansize","markscale") %in% names(list(...)))) {
             plot(Ys[neg], add=TRUE, legend=FALSE, ...)
           } else {
             hackmax <- 0.5 * sqrt(area(Wclip)/Yclip$n)
             plot(Ys[neg], add=TRUE, legend=FALSE, maxsize=hackmax, ...)
           }
           ## plot positive masses at atoms
           plot(Ys[!neg], add=TRUE,
                leg.side="left", leg.args=list(sep=sep),
                show.all=TRUE, main="",
                ...)
         },
         contour = {
           Yds <- shift(Ydens, vec)
           Yms <- shift(Ymass, vec)
           Contour(Yds, add=TRUE, ...)
           do.call("plot",
                   resolve.defaults(list(x=Yms, add=TRUE),
                                    list(...), 
                                    list(use.marks=showscale,
                                         leg.side="left", show.all=TRUE,
                                         main="", leg.args=list(sep=sep))))
         },
         imagecontour=,
         image={
           Yds <- shift(Ydens, vec)
           Yms <- shift(Ymass, vec)
           if(redundant)
             do.clean(ploterodeimage,
                      Ws, Yds, rangeZ=srange, colsZ=col.neg,
                      ...)
           else if(type != "eem")
             do.clean(image,
                      Yds, add=TRUE, ribbon=FALSE,
                      col=col.neg, zlim=srange,
                      ...)
           if(plot.neg == "imagecontour")
             Contour(Yds, add=TRUE, ...)
           ## plot positive masses at atoms
           do.call("plot",
                   resolve.defaults(list(x=Yms, add=TRUE),
                                    list(...),
                                    list(use.marks=showscale,
                                         leg.side="left", show.all=TRUE,
                                         main="", leg.args=list(sep=sep))))
         }
         )
  # --------- plot smoothed surface (in bottom right panel) ------------
  vec <- c(wide, 0) + c(space, 0) - Xlowleft
  Zs <- shift.im(Z, vec)
  switch(plot.smooth,
         image={
           do.clean(image,
                    Zs, add=TRUE, col=col.smooth,
                    zlim=srange, ribbon=FALSE,
                    ...)
         },
         contour={
           Contour(Zs, add=TRUE, ...)
         },
         persp={ warning("persp not available in 4-panel plot") },
         imagecontour={
             do.clean(image,
                      Zs, add=TRUE, col=col.smooth, zlim=srange, ribbon=FALSE,
                      ...)
             Contour(Zs, add=TRUE, ...)
           }
         )
  lines(Zs$xrange[c(1,2,2,1,1)], Zs$yrange[c(1,1,2,2,1)])
  # -------------- lurking variable plots -----------------------
  # --------- lurking variable plot for x coordinate ------------------
  #           (cumulative or marginal)
  #           in bottom left panel
  if(!is.null(RES$xmargin)) {
    a <- RES$xmargin
    observedV <-    a$xZ
    observedX <-    a$x
    theoreticalV <- a$ExZ
    theoreticalX <- a$x
    theoreticalSD <- NULL
    if(is.null(rlab)) rlab <- paste("marginal of", typename)
  } else if(!is.null(RES$xcumul)) {
    a <- RES$xcumul
    observedX <- a$empirical$covariate
    observedV <- a$empirical$value
    theoreticalX <- a$theoretical$covariate
    theoreticalV <- a$theoretical$mean
    theoreticalSD <- a$theoretical$sd
    theoreticalHI <- a$theoretical$upper
    theoreticalLO <- a$theoretical$lower
    if(is.null(rlab)) rlab <- paste("cumulative sum of", typename)
  }
  # pretty axis marks
  pX <- pretty(theoreticalX)
  rV <- range(0, observedV, theoreticalV, theoreticalHI, theoreticalLO)
  if(!is.null(theoreticalSD))
    rV <- range(rV,
                theoreticalV+2*theoreticalSD,
                theoreticalV-2*theoreticalSD)
  pV <- pretty(rV)
  # rescale smoothed values
  rr <- range(c(0, observedV, theoreticalV, pV))
  yscale <- function(y) { high * (y - rr[1])/diff(rr) }
  xscale <- function(x) { x - W$xrange[1] }
  if(!is.null(theoreticalHI)) 
    do.call.matched(polygon,
                    resolve.defaults(
                      list(x=xscale(c(theoreticalX, rev(theoreticalX))),
                           y=yscale(c(theoreticalHI, rev(theoreticalLO)))),
                      list(...),
                      list(col="grey", border=NA)))
  do.clean(do.lines, xscale(observedX), yscale(observedV), 1, ...)
  do.clean(do.lines, xscale(theoreticalX), yscale(theoreticalV), 2, ...)
  if(!is.null(theoreticalSD)) {
    do.clean(do.lines,
             xscale(theoreticalX),
             yscale(theoreticalV + 2 * theoreticalSD),
             3, ...)
    do.clean(do.lines,
             xscale(theoreticalX),
             yscale(theoreticalV - 2 * theoreticalSD),
             3, ...)
  }
  axis(side=1, pos=0, at=xscale(pX), labels=pX)
  text(xscale(mean(theoreticalX)), - outerspace, xlab)
  axis(side=2, pos=0, at=yscale(pV), labels=pV)
  text(-outerRspace, yscale(mean(pV)), rlab, srt=90)
  
  # --------- lurking variable plot for y coordinate ------------------
  #           (cumulative or marginal)
  #           in top right panel
  if(!is.null(RES$ymargin)) {
    a <- RES$ymargin
    observedV <-    a$yZ
    observedY <-    a$y
    theoreticalV <- a$EyZ
    theoreticalY <- a$y
    theoreticalSD <- NULL
    if(is.null(rlab)) rlab <- paste("marginal of", typename)
  } else if(!is.null(RES$ycumul)) {
    a <- RES$ycumul
    observedV <- a$empirical$value
    observedY <- a$empirical$covariate
    theoreticalY <- a$theoretical$covariate
    theoreticalV <- a$theoretical$mean
    theoreticalSD <- a$theoretical$sd
    theoreticalHI <- a$theoretical$upper
    theoreticalLO <- a$theoretical$lower
    if(is.null(rlab)) rlab <- paste("cumulative sum of", typename)
  }
  # pretty axis marks
  pY <- pretty(theoreticalY)
  rV <- range(0, observedV, theoreticalV, theoreticalHI, theoreticalLO)
  if(!is.null(theoreticalSD))
    rV <- range(rV,
                theoreticalV+2*theoreticalSD,
                theoreticalV-2*theoreticalSD)
  pV <- pretty(rV)
  # rescale smoothed values
  rr <- range(c(0, observedV, theoreticalV, pV))
  yscale <- function(y) { y - W$yrange[1] + high + space}
  xscale <- function(x) { wide + space + wide * (rr[2] - x)/diff(rr) }
  if(!is.null(theoreticalHI)) 
    do.call.matched(polygon,
                    resolve.defaults(
                      list(x=xscale(c(theoreticalHI, rev(theoreticalLO))),
                           y=yscale(c(theoreticalY,  rev(theoreticalY)))),
                      list(...),
                      list(col="grey", border=NA)))
  do.clean(do.lines, xscale(observedV), yscale(observedY), 1, ...)
  do.clean(do.lines, xscale(theoreticalV), yscale(theoreticalY), 2, ...)
  if(!is.null(theoreticalSD)) {
    do.clean(do.lines,
             xscale(theoreticalV+2*theoreticalSD),
             yscale(theoreticalY),
             3, ...)
    do.clean(do.lines,
             xscale(theoreticalV-2*theoreticalSD),
             yscale(theoreticalY),
             3, ...)
  }
  axis(side=4, pos=width, at=yscale(pY), labels=pY)
  text(width + outerspace, yscale(mean(theoreticalY)), ylab, srt=90)
  axis(side=3, pos=height, at=xscale(pV), labels=pV)
  text(xscale(mean(pV)), height + outerRspace, rlab)
  #
  if(!is.null(main))
    title(main=main)
  invisible(NULL)
}

  resid4plot
})

#
#
#   Residual plot: single panel(s)
#
#

resid1plot <- local({

  Contour <- function(...,
                      pch, chars, cols, etch, size,
                      maxsize, meansize, markscale, symap, zap,
                      legend, leg.side, leg.args) {
    ## avoid passing arguments of plot.ppp to contour.default
    contour(...)
  }

  do.clean <- function(fun, ..., 
                       pch, chars, cols, etch, size,
                       maxsize, meansize, markscale, symap, zap,
                       legend, leg.side, leg.args,
                       nlevels, levels, labels, drawlabels, labcex) {
    ## avoid passing arguments of plot.ppp, contour.default to other functions
    do.call(fun, list(...)) 
  }

  resid1plot <- 
  function(RES, opt,
           plot.neg=c("image", "discrete", "contour", "imagecontour"),
           plot.smooth=c("imagecontour", "image", "contour", "persp"),
           srange=NULL, monochrome=FALSE, main=NULL,
           add=FALSE, show.all=!add, do.plot=TRUE,
           col.neg=NULL, col.smooth=NULL, 
           ...) {
    if(!any(unlist(opt[c("all", "marks", "smooth",
                         "xmargin", "ymargin", "xcumul", "ycumul")])))
      return(invisible(NULL))
    if(!add && do.plot) {
      ## determine size of plot area by calling again with do.plot=FALSE
      cl <- match.call()
      cl$do.plot <- FALSE
      b <- eval(cl, parent.frame())
      bb <- as.owin(b, fatal=FALSE)
      if(is.owin(bb)) {
        ## initialise plot area
        plot(bb, type="n", main="")
        force(show.all)
        add <- TRUE
      }
    }
    ## extract info
    clip  <- RES$clip
    Y     <- RES$Y
    Yclip <- RES$Yclip
    Z     <- RES$smooth$Z
    W     <- RES$W
    Wclip <- Yclip$window
    type  <- RES$type
    Ydens <- RES$Ydens[Wclip, drop=FALSE]
    Ymass <- RES$Ymass[Wclip]
    ## determine colour map
    if(opt$all || opt$marks || opt$smooth) {
      if(is.null(srange)) {
        Yrange <- if(!is.null(Ydens)) summary(Ydens)$range else NULL
        Zrange <- if(!is.null(Z)) summary(Z)$range else NULL
        srange <- range(c(0, Yrange, Zrange), na.rm=TRUE)
      }
      backcols <- beachcolours(srange, if(type=="eem") 1 else 0, monochrome)
      if(is.null(col.neg)) col.neg <- backcols
      if(is.null(col.smooth)) col.smooth <- backcols
    }
    ## determine main heading
    if(is.null(main)) {
      prefix <- if(opt$marks) NULL else
      if(opt$smooth) "Smoothed" else
      if(opt$xcumul) "Lurking variable plot for x coordinate\n" else 
      if(opt$ycumul) "Lurking variable plot for y coordinate\n" else
      if(opt$xmargin) "Lurking variable plot for x coordinate\n" else
      if(opt$ymargin) "Lurking variable plot for y coordinate\n" else NULL
      main <- paste(prefix, RES$typename)
    }
    ## ------------- residuals ---------------------------------
    if(opt$marks) {
      ## determine whether pre-plotting the window(s) is redundant
      redundant <- (plot.neg == "image") &&
                   (type != "eem") && (Yclip$window$type == "mask")
      ## pre-plot the window(s)
      if(redundant && !add) {
        z <- do.clean(plot,
                      as.rectangle(W), box=FALSE, main="",
                      do.plot=do.plot, ...)
      } else {
        if(!clip) 
          z <- do.clean(plot,
                        W, main="",
                        add=add, show.all=show.all, do.plot=do.plot, ...)
        else
          z <- do.clean(ploterodewin,
                        W, Wclip, main="",
                        add=add, show.all=show.all, do.plot=do.plot, ...)
      }
      bb <- as.owin(z)

      switch(plot.neg,
             discrete={
               neg <- (Y$marks < 0)
               ## plot negative masses of discretised measure as squares
               if(any(c("maxsize", "markscale") %in% names(list(...)))) {
                 z <- plot(Y[neg], add=TRUE,
                          show.all=show.all, do.plot=do.plot, ...)
               } else {
                 hackmax <- 0.5 * sqrt(area(Wclip)/Yclip$n)
                 z <- plot(Y[neg], add=TRUE, maxsize=hackmax,
                           show.all=show.all, do.plot=do.plot, ...)
               }
               ## plot positive masses at atoms
               zp <- plot(Y[!neg], add=TRUE,
                          show.all=show.all, do.plot=do.plot, ...)
               bb <- boundingbox(bb, z, zp)
           },
           contour = {
             z <- Contour(Ydens, add=TRUE, do.plot=do.plot, ...)
             bb <- boundingbox(bb, z)
           },
           imagecontour=,
           image={
             if(redundant) {
               z <- do.clean(ploterodeimage,
                             W, Ydens, rangeZ=srange, colsZ=col.neg,
                             add=add, show.all=show.all, main="", 
                             do.plot=do.plot, ...)
             } else if(type != "eem") {
               z <- do.clean(image,
                             Ydens, col=col.neg, zlim=srange, ribbon=FALSE,
                             add=TRUE, show.all=show.all, do.plot=do.plot,
                             main="", ...)
             }
             bb <- boundingbox(bb, z)
             if(plot.neg == "imagecontour") {
               z <- Contour(Ydens, add=TRUE,
                            show.all=show.all, do.plot=do.plot, ...)
               bb <- boundingbox(bb, z)
             }
             ## decide whether mark scale should be shown
             showscale <- (type != "raw")
             ## plot positive masses at atoms
             z <- do.call(plot,
                          resolve.defaults(list(x=Ymass, add=TRUE),
                                           list(...),
                                           list(use.marks=showscale,
                                                do.plot=do.plot)))
             bb <- boundingbox(bb, z)
           }
           )
    if(do.plot && show.all) title(main=main)
  }
  # -------------  smooth -------------------------------------
  if(opt$smooth) {
    if(!clip) {
      switch(plot.smooth,
           image={
             z <- do.clean(image,
                           Z, main="", axes=FALSE, xlab="", ylab="",
                           col=col.smooth, zlim=srange, ribbon=FALSE,
                           do.plot=do.plot, add=add, show.all=show.all, ...)
             bb <- as.owin(z)
           },
           contour={
             z <- Contour(Z, main="", axes=FALSE, xlab="", ylab="",
                          do.plot=do.plot, add=add, show.all=show.all, ...)
             bb <- as.owin(z)
           },
           persp={
             if(do.plot)
               do.clean(persp,
                        Z, main="", axes=FALSE, xlab="", ylab="", ...)
             bb <- NULL
           },
           imagecontour={
             z <- do.clean(image,
                           Z, main="", axes=FALSE, xlab="", ylab="",
                           col=col.smooth, zlim=srange, ribbon=FALSE,
                           do.plot=do.plot, add=add, show.all=show.all, ...)
             Contour(Z, add=TRUE, do.plot=do.plot, ...)
             bb <- as.owin(z)
           }
             )
      if(do.plot && show.all) title(main=main)             
    } else {
      switch(plot.smooth,
             image={
               do.clean(plot,
                        as.rectangle(W), box=FALSE, main=main,
                        do.plot=do.plot, add=add, ...)
               z <- do.clean(ploterodeimage,
                             W, Z, colsZ=col.smooth, rangeZ=srange,
                             do.plot=do.plot, ...)
               bb <- boundingbox(as.rectangle(W), z)
             },
             contour={
               do.clean(plot,
                        W, main=main,
                        do.plot=do.plot, add=add, show.all=show.all, ...)
               z <- Contour(Z, add=TRUE,
                            show.all=show.all, do.plot=do.plot, ...)
               bb <- as.owin(z)
             },
             persp={
               if(do.plot) 
                 do.clean(persp,
                          Z, main=main, axes=FALSE, xlab="", ylab="", ...)
               bb <- NULL
             },
             imagecontour={
               do.clean(plot,
                        as.rectangle(W), box=FALSE, main=main,
                        do.plot=do.plot, add=add, ...)
               z <- do.clean(ploterodeimage,
                             W, Z, colsZ=col.smooth, rangeZ=srange,
                             do.plot=do.plot, ...)
               Contour(Z, add=TRUE, do.plot=do.plot, ...)
               bb <- as.owin(z)
             }
             )
    }
  }

  # ------------  cumulative x -----------------------------------------
  if(opt$xcumul) {
    a <- RES$xcumul
    obs <- a$empirical
    theo <- a$theoretical
    do.clean(resid1panel,
             obs$covariate, obs$value,
             theo$covariate, theo$mean, theo$sd,
             "x coordinate", "cumulative mark", main=main,
             ...,
             do.plot=do.plot)
    bb <- NULL
  }
  
  # ------------  cumulative y -----------------------------------------
  if(opt$ycumul) {
    a <- RES$ycumul
    obs <- a$empirical
    theo <- a$theoretical
    do.clean(resid1panel,
             obs$covariate, obs$value,
             theo$covariate, theo$mean, theo$sd,
             "y coordinate", "cumulative mark", main=main,
             ...,
             do.plot=do.plot)
    bb <- NULL
  }
  ## ------------  x margin -----------------------------------------
  if(opt$xmargin) {
    a <- RES$xmargin
    do.clean(resid1panel,
             a$x, a$xZ, a$x, a$ExZ, NULL,
             "x coordinate", "marginal of residuals", main=main,
             ...,
             do.plot=do.plot)
    bb <- NULL
  }
  # ------------  y margin -----------------------------------------
  if(opt$ymargin) {
    a <- RES$ymargin
    do.clean(resid1panel,
             a$y, a$yZ, a$y, a$EyZ, NULL,
             "y coordinate", "marginal of residuals", main=main,
             ...,
             do.plot=do.plot)
    bb <- NULL
  }

  attr(bb, "bbox") <- bb  
  return(invisible(bb))
}

resid1plot
})


resid1panel <- local({

  do.lines <- function(x, y, defaulty=1, ...) {
      do.call("lines",
              resolve.defaults(list(x, y),
                               list(...),
                               list(lty=defaulty)))
  }

resid1panel <- function(observedX, observedV,
                        theoreticalX, theoreticalV, theoreticalSD, xlab, ylab,
                        ..., do.plot=TRUE)
{
  if(!do.plot) return(NULL)
  ## work out plot range
  rX <- range(observedX, theoreticalX)
  rV <- range(c(0, observedV, theoreticalV))
  if(!is.null(theoreticalSD))
    rV <- range(c(rV, theoreticalV + 2*theoreticalSD,
                  theoreticalV - 2*theoreticalSD))
  ## argument handling
  ## start plot
  plot(rX, rV, type="n", xlab=xlab, ylab=ylab, ...)
  do.lines(observedX, observedV, 1, ...)
  do.lines(theoreticalX, theoreticalV, 2, ...)
  if(!is.null(theoreticalSD)) {
    do.lines(theoreticalX, theoreticalV + 2 * theoreticalSD, 3, ...)
    do.lines(theoreticalX, theoreticalV - 2 * theoreticalSD, 3, ...)
  }
}

resid1panel
})

#
#
ploterodewin <- function(W1, W2, col.edge=grey(0.75), col.inside=rgb(1,0,0),
                         do.plot=TRUE, ...) {
  ## internal use only
  ## W2 is assumed to be an erosion of W1
  switch(W1$type,
         rectangle={
           z <- plot(W1, ..., do.plot=do.plot)
           plot(W2, add=TRUE, lty=2, do.plot=do.plot)
         },
         polygonal={
           z <- plot(W1, ..., do.plot=do.plot)
           plot(W2, add=TRUE, lty=2, do.plot=do.plot)
         },
         mask={
           Z <- as.im(W1)
           x <- as.vector(rasterx.mask(W1))
           y <- as.vector(rastery.mask(W1))
           ok <- inside.owin(x, y, W2)
           Z$v[ok] <- 2
           z <- plot(Z, ..., col=c(col.edge, col.inside),
                     add=TRUE, ribbon=FALSE, do.plot=do.plot)
         }
         )
  return(z)
}

ploterodeimage <- function(W, Z, ..., Wcol=grey(0.75), rangeZ, colsZ,
                           do.plot=TRUE) {
  # Internal use only
  # Image Z is assumed to live on a subset of mask W
  # colsZ are the colours for the values in the range 'rangeZ'

  if(W$type != "mask" && do.plot) {
    plot(W, add=TRUE)
    W <- as.mask(W)
  }
  
  # Extend the colour map to include an extra colour for pixels in W
  # (1) Add the desired colour of W to the colour map
  pseudocols <- c(Wcol, colsZ)
  # (2) Breakpoints
  bks <- seq(from=rangeZ[1], to=rangeZ[2], length=length(colsZ)+1)
  dZ <- diff(bks)[1]
  pseudobreaks <- c(rangeZ[1] - dZ, bks)
  # (3) Determine a fake value for pixels in W
  Wvalue <- rangeZ[1] - dZ/2

  # Create composite image on W grid
  # (with W-pixels initialised to Wvalue)
  X <- as.im(Wvalue, W)
  # Look up Z-values of W-pixels
  xx <- as.vector(rasterx.mask(W))
  yy <- as.vector(rastery.mask(W))
  Zvalues <- lookup.im(Z, xx, yy, naok = TRUE, strict=FALSE)
  # Overwrite pixels in Z
  inZ <- !is.na(Zvalues)
  X$v[inZ] <- Zvalues[inZ]

  z <- image(X, ..., add=TRUE, ribbon=FALSE, 
             col=pseudocols, breaks=pseudobreaks,
             do.plot=do.plot)
  out <- list(X, pseudocols, pseudobreaks)
  attr(out, "bbox") <- as.owin(z)
  return(out)
}


  

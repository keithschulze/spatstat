\name{dclf.sigtrace}
\alias{dclf.sigtrace}
\alias{mad.sigtrace}
\alias{mctest.sigtrace}
\title{
  Significance Trace of Cressie-Loosmore-Ford or Maximum Absolute
  Deviation Test
}
\description{
  Generates a Significance Trace of the
  Diggle(1986)/ Cressie (1991)/ Loosmore and Ford (2006) test or the
  Maximum Absolute Deviation test for a spatial point pattern.
}
\usage{
dclf.sigtrace(X, ...)
mad.sigtrace(X, ...)
mctest.sigtrace(X, fun=Lest, ..., exponent=1, alpha=0.05)
}
\arguments{
  \item{X}{
    Either a point pattern (object of class \code{"ppp"}, \code{"lpp"}
    or other class), a fitted point process model (object of class \code{"ppm"},
    \code{"kppm"} or other class) or an envelope object (class
    \code{"envelope"}). 
  }
  \item{\dots}{
    Arguments passed to \code{\link{envelope}}.
    Useful arguments include \code{fun} to determine the summary
    function, \code{nsim} to specify the number of Monte Carlo
    simulations, and \code{verbose=FALSE} to turn off the messages.
  }
  \item{fun}{
    Function that computes the desired summary statistic
    for a point pattern.
  }
  \item{exponent}{
    Positive number. The exponent of the \eqn{L^p} distance.
    See Details.
  }
  \item{alpha}{
    Significance level to be plotted (this has no effect on the calculation
    but is simply plotted as a reference value).
  }
}
\details{
  The Diggle (1986)/ Cressie (1991)/Loosmore and Ford (2006) test and the 
  Maximum Absolute Deviation test for a spatial point pattern
  are described in \code{\link{dclf.test}}.
  These tests depend on the choice of an interval of
  distance values (the argument \code{rinterval}).
  A \emph{significance trace} (Bowman and Azzalini, 1997;
  Baddeley et al, 2014, 2015)
  of the test is a plot of the \eqn{p}-value
  obtained from the test against the length of
  the interval \code{rinterval}.
  
  The command \code{dclf.sigtrace} performs 
  \code{\link{dclf.test}} on \code{X} using all possible intervals
  of the form \eqn{c(0,r)}, and returns the resulting \eqn{p}-values
  as a function of \eqn{r}.

  Similarly \code{mad.sigtrace} performs
  \code{\link{mad.test}} using all possible intervals
  and returns the \eqn{p}-values.

  More generally, \code{mctest.sigtrace} performs a test based on the
  \eqn{L^p} discrepancy between the curves. The deviation between two
  curves is measured by the \eqn{p}th root of the integral of
  the \eqn{p}th power of the absolute value of the difference
  between the two curves. The exponent \eqn{p} is
  given by the argument \code{exponent}. The case \code{exponent=2}
  is the Cressie-Loosmore-Ford test, while \code{exponent=Inf} is the
  MAD test.

  The result of each command
  is an object of class \code{"fv"} that can be plotted to
  obtain the significance trace. The plot shows the Monte Carlo
  \eqn{p}-value (solid black line), 
  the critical value \code{0.05} (dashed red line),
  and a pointwise 95\% confidence band (grey shading)
  for the \sQuote{true} (Neyman-Pearson) \eqn{p}-value.
  The confidence band is based on the Agresti-Coull (1998)
  confidence interval for a binomial proportion.

  If \code{X} is an envelope object and \code{fun=NULL} then
  the code will re-use the simulated functions stored in \code{X}. 
}
\value{
  An object of class \code{"fv"} that can be plotted to
  obtain the significance trace. 
}
\references{
  Agresti, A. and Coull, B.A. (1998)
  Approximate is better than \dQuote{Exact} for interval
   estimation of binomial proportions.
  \emph{American Statistician} \bold{52}, 119--126.

  Baddeley, A., Diggle, P., Hardegen, A., Lawrence, T.,
  Milne, R. and Nair, G. (2014)
  On tests of spatial pattern based on simulation envelopes.
  \emph{Ecological Monographs} \bold{84}(3) 477--489.

  Baddeley, A., Hardegen, A., Lawrence, L., 
  Milne, R.K., Nair, G.M. and Rakshit, S. (2015)
  Pushing the envelope: extensions of graphical
  Monte Carlo tests. Submitted for publication.

  Bowman, A.W. and Azzalini, A. (1997) 
  \emph{Applied smoothing techniques for data analysis: 
    the kernel approach with S-Plus illustrations}.
  Oxford University Press, Oxford.
}
\author{
  Adrian Baddeley, Andrew Hardegen, Tom Lawrence,
  Robin Milne, Gopalan Nair and Suman Rakshit.
  Implemented by
  Adrian Baddeley
  \email{Adrian.Baddeley@uwa.edu.au}
  \url{http://www.maths.uwa.edu.au/~adrian/}
  Rolf Turner
  \email{r.turner@auckland.ac.nz}
  and Ege Rubak
  \email{rubak@math.aau.dk}
}
\seealso{
  \code{\link{dclf.test}} for the tests;
  \code{\link{dclf.progress}} for progress plots.
  
  See \code{\link{plot.fv}} for information on plotting
  objects of class \code{"fv"}.
}
\examples{
  plot(dclf.sigtrace(cells, Lest, nsim=19))
}
\keyword{spatial}
\keyword{htest}

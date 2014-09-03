\name{linearKdot.inhom}
\alias{linearKdot.inhom}
\title{
  Inhomogeneous multitype K Function (Dot-type) for Linear Point Pattern
}
\description{
  For a multitype point pattern on a linear network,
  estimate the inhomogeneous multitype \eqn{K} function
  which counts the expected number of points (of any type)
  within a given distance of a point of type \eqn{i}.
}
\usage{
linearKdot.inhom(X, i, lambdaI, lambdadot, r=NULL, \dots,
                 correction="Ang", normalise=TRUE)
}
\arguments{
  \item{X}{The observed point pattern, 
    from which an estimate of the dot type \eqn{K} function
    \eqn{K_{i\bullet}(r)}{K[i.](r)} will be computed.
    An object of class \code{"lpp"} which 
    must be a multitype point pattern (a marked point pattern
    whose marks are a factor).
  }
  \item{i}{Number or character string identifying the type (mark value)
    of the points in \code{X} from which distances are measured.
    Defaults to the first level of \code{marks(X)}.
  }
  \item{lambdaI}{
    Intensity values for the points of type \code{i}. Either a numeric vector,
    a \code{function}, a pixel image
    (object of class \code{"im"} or \code{"linim"}) or
    a fitted point process model (object of class \code{"ppm"}
    or \code{"lppm"}).
  }
  \item{lambdadot}{
    Intensity values for all points of \code{X}. Either a numeric vector,
    a \code{function}, a pixel image
    (object of class \code{"im"} or \code{"linim"}) or
    a fitted point process model (object of class \code{"ppm"}
    or \code{"lppm"}).
  }
  \item{r}{numeric vector. The values of the argument \eqn{r}
    at which the \eqn{K}-function
    \eqn{K_{i\bullet}(r)}{K[i.](r)} should be evaluated.
    There is a sensible default.
    First-time users are strongly advised not to specify this argument.
    See below for important conditions on \eqn{r}.
  }
  \item{correction}{
    Geometry correction.
    Either \code{"none"} or \code{"Ang"}. See Details.
  }
  \item{\dots}{
    Arguments passed to \code{lambdaI} and \code{lambdadot} if
    they are functions.
  }
  \item{normalise}{
    Logical. If \code{TRUE} (the default), the denominator of the estimator is 
    data-dependent (equal to the sum of the reciprocal intensities at
    the points of type \code{i}), which reduces the sampling variability.
    If \code{FALSE}, the denominator is the length of the network.
  }
}
\value{
  An object of class \code{"fv"} (see \code{\link{fv.object}}).
}
\details{
  This is a counterpart of the function \code{\link[spatstat]{Kdot.inhom}} 
  for a point pattern on a linear network (object of class \code{"lpp"}).

  The argument \code{i} will be interpreted as
  levels of the factor \code{marks(X)}. 
  If \code{i} is missing, it defaults to the first
  level of the marks factor.

  The argument \code{r} is the vector of values for the
  distance \eqn{r} at which \eqn{K_{i\bullet}(r)}{Ki.(r)} should be evaluated. 
  The values of \eqn{r} must be increasing nonnegative numbers
  and the maximum \eqn{r} value must not exceed the radius of the
  largest disc contained in the window.
}
\references{
  Baddeley, A, Jammalamadaka, A. and Nair, G. (to appear)
  Multitype point process analysis of spines on the
  dendrite network of a neuron.
  \emph{Applied Statistics} (Journal of the Royal Statistical
   Society, Series C), In press.
}
\section{Warnings}{
  The argument \code{i} is interpreted as a
  level of the factor \code{marks(X)}. Beware of the usual
  trap with factors: numerical values are not
  interpreted in the same way as character values. 
}
\seealso{
 \code{\link{linearKdot}},
 \code{\link[spatstat]{linearK}}.
}
\examples{
   lam <- table(marks(chicago))/(summary(chicago)$totlength)
   lamI <- function(x,y,const=lam[["assault"]]){ rep(const, length(x)) }
   lam. <- function(x,y,const=sum(lam)){ rep(const, length(x)) }

   K <- linearKdot.inhom(chicago, "assault", lamI, lam.)

   \dontrun{
     fit <- lppm(chicago, ~marks + x)
     linearKdot.inhom(chicago, "assault", fit, fit)
   }
}
\author{Adrian Baddeley
  \email{Adrian.Baddeley@uwa.edu.au}
  \url{http://www.maths.uwa.edu.au/~adrian/}
}
\keyword{spatial}
\keyword{nonparametric}

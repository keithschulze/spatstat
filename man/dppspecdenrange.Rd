\name{dppspecdenrange}
\alias{dppspecdenrange}
\title{Range of Spectral Density of a Determinantal Point Process Model}
\description{
  Computes the range of the spectral density of a
  determinantal point process model.
} 
\usage{dppspecdenrange(model)}
\arguments{
  \item{model}{Model of class \code{"dppmodel"}.}
}
\value{Numeric value (possibly \code{Inf}).}
\author{
  Adrian Baddeley
  \email{Adrian.Baddeley@uwa.edu.au}
  \url{http://www.maths.uwa.edu.au/~adrian/}
  Rolf Turner
  \email{r.turner@auckland.ac.nz}
  and Ege Rubak
  \email{rubak@math.aau.dk}
}
\examples{
m <- dppBessel(lambda=100, alpha=0.05, sigma=1, d=2)
dppspecdenrange(m)
}
\seealso{
  \code{\link{dppspecden}}
}
\keyword{spatial}
\keyword{models}

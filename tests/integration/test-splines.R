
context("Extraction of results from spatial splines model")
########################

data(m1)
dat <- as.data.frame(m1)

fixed.fml <- phe_X ~ sex

n.obs     <- nrow(dat)
n.fixed   <- length(attr(terms(fixed.fml), 'term.labels'))
nlevels.fixed <- nlevels(dat$sex)
n.knots   <- c(4, 3)
n.splines <- prod(n.knots + 2)

# Use a different number of knots for rows and columns
res <- try(
  suppressMessages(
    remlf90(fixed = fixed.fml, 
            spatial = list(model = 'splines', 
                           coord = coordinates(m1),
                           n.knots = n.knots), 
            data = dat,
            method = 'em')
  )
)
  

test_that("The splines model runs with EM-REML without errors", {
  expect_that(!inherits(res, "try-error"), is_true())
})

test_that("coef() gets a named vector of coefficients", {
  expect_is(coef(res), 'numeric')
  expect_equal(length(coef(res)), nlevels.fixed + n.splines)
  expect_named(coef(res))
})

test_that("ExtractAIC() gets one number", {
  expect_is(extractAIC(res), 'numeric')
  expect_equal(length(extractAIC(res)), 1)
})

test_that("fitted() gets a vector of length N", {
  expect_is(fitted(res), 'numeric')
  expect_equal(length(fitted(res)), n.obs)
})

test_that("fixef() gets a named list of numeric vectors with estimated values and s.e.", {
  x <- fixef(res)
  expect_is(x, 'breedR_estimates')
  expect_named(x)
  expect_equal(length(x), n.fixed)
  for (f in x) {
    expect_is(f, 'numeric')
    expect_false(is.null(fse <- attr(f, 'se')))
    expect_is(fse, 'numeric')
    expect_equal(length(fse), length(f))
  }
})

test_that("get_pedigree() returns NULL", {
  expect_null(get_pedigree(res))
})

test_that("logLik() gets an object of class logLik", {
  expect_is(logLik(res), 'logLik')
})

test_that("model.frame() gets an Nx2 data.frame with a 'terms' attribute", {
  x <- model.frame(res)
  expect_is(x, 'data.frame')
  expect_is(terms(x), 'terms')
  expect_equal(dim(x), c(n.obs, n.fixed + 1))
})

test_that("model.matrix() gets a named list of fixed and random incidence matrices", {
  x <- model.matrix(res)
  expect_is(x, 'list')
  expect_named(x, names(res$effects))
  expect_equal(dim(x$sex), c(n.obs, nlevels.fixed))
  expect_is(x$spatial, 'sparseMatrix')
  expect_equal(dim(x$spatial), c(n.obs, n.splines))
})

test_that("nobs() gets the number of observations", {
  expect_equal(nobs(res), n.obs)
})

test_that("plot(, type = *) returns ggplot objects", {
  expect_is(plot(res, type = 'phenotype'), 'ggplot')
  expect_is(plot(res, type = 'fitted'), 'ggplot')
  expect_is(plot(res, type = 'spatial'), 'ggplot')
  expect_is(plot(res, type = 'fullspatial'), 'ggplot')
  expect_is(plot(res, type = 'residuals'), 'ggplot')
})

test_that("print() shows some basic information", {
  ## Not very informative currently...
  expect_output(print(res), 'Data')
})

test_that("ranef() gets a ranef.breedR object with random effect BLUPs and their s.e.", {
  x <- ranef(res)
  expect_is(x, 'ranef.breedR')
  expect_equal(length(x), 1)
  expect_named(x, c('spatial'))

  expect_is(x$spatial, 'numeric')
  expect_equal(length(x$spatial), n.splines)
  expect_false(is.null(xse <- attr(x$spatial, 'se')))
  
  expect_is(xse, 'numeric')
  expect_equal(length(xse), n.splines)
})

test_that("residuals() gets a vector of length N", {
  rsd <- residuals(res)
  expect_is(rsd, 'numeric')
  expect_equal(length(rsd), n.obs)
})

test_that("summary() shows summary information", {
  expect_output(print(summary(res)), 'Variance components')
  expect_output(print(summary(res)), 'knots:')
})

test_that("vcov() gets the covariance matrix of the spatial component of the observations", {
  x <- vcov(res)
  expect_is(x, 'Matrix')
  expect_equal(dim(x), rep(n.obs, 2))
})


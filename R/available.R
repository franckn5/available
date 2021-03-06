#' See if a name is available
#'
#' Searches performed
#' - Valid package name
#' - Already taken on CRAN
#' - Positive or negative sentiment
#' - Urban Dictionary
#' @param name Name of package to search
#' @param browse Whether browser should be opened for all web links,
#'        default = TRUE. Default can be changed by setting
#'        \code{available.browse} in \code{.Rprofile}. See \link[base]{Startup}
#'        for more details.
#' @param ... Additional arguments passed to [utils::available.packages()].
#' @importFrom memoise memoise
#' @examples
#' \dontrun{
#' # Check if the available package is available
#' available("available")
#'
#' # You can disable opening of browser windows with browse = FALSE
#' available("survival", browse = FALSE)
#'
#' # Or by setting a global option
#' options(available.browse = FALSE)
#' available("survival")
#' }
#' @export
available <- function(name, browse = getOption("available.browse", TRUE), ...) {
  res <- list(valid_package_name(name),
    available_on_cran(name, ...),
    available_on_bioc(name, ...),
    available_on_github(name))
  terms <- name_to_search_terms(name)
  res <- c(res,
    unlist(recursive = FALSE,
      lapply(terms,
      function(term) {
        list(
          get_bad_words(term),
          get_abbreviation(term),
          get_wikipidia(term),
          get_wiktionary(term),
          get_urban_data(term),
          get_sentiment(term))
          })))
  structure(res, class = "available_query", packagename = name,
            browse = browse)
}

#' @export
print.available_query <- function(x, ...) {
  if (!attr(x, "browse")) {
    base_browser <- getOption("browser")
    options(browser = "false")
    on.exit(options(browser = base_browser))
  }
  cat(cli::rule(attr(x, "packagename")), "\n", sep = "")
  for (i in x) {
    print(i)
  }
  invisible(x)
}

#' Check a new package name and possibly create it
#'
#' @inheritParams available
#' @param ... Additional arguments passed to [devtools::create()].
create <- function(name, ...) {
  print(available(name))

  ans <- yesno::yesno(glue::glue("Create package `{name}`?"))
  if (isTRUE(ans)) {
    if (!requireNamespace("devtools")) {
      stop("`devtools` must be installed to create a package", call. = FALSE)
    }
    devtools::create(name, ...)
  }
}

#' Suggest a package name based on a development package title or description
#'
#' If the package you are using already has a title, simply pass the path to
#' the package root in `path`. Otherwise use `title` to specify a potential
#' title.
#' @param path Path to a existing package to extract the title from.
#' @param field one of "Title" or "Description"
#' @param text text string to search.
#' @export
#' @examples
#' \dontrun{
#' # Default will use the title from the current path.
#' suggest()
#'
#' # Can also suggest based on the description
#' suggest(field = "Description")
#' }
#'
#' # Or by explictly using the text argument
#' suggest(text =
#'   "A Package for Displaying Visual Scenes as They May Appear to an Animal with Lower Acuity")
suggest <- function(path = ".",  field = c("Title", "Description"), text = NULL) {
  if (is.null(text)) {
    if (file.exists (path)) {
      field <- match.arg(field)
      text <- tryCatch(error = function (e) NA,
        unname(desc::desc(path)$get(field)))
    } else {
      text <- path
    }
    if (is.na(text)) {
      stop("No text found, please specify one with `text`.", call. = FALSE)
    }
  }

  namr(text)
}

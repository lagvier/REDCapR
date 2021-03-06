#' @name metadata_utilities
#' @export
#' @aliases regex_named_captures checkbox_choices
#' 
#' @title Manipulate and interpret the metadata of a REDCap project.
#'  
#' @description A collection of functions that assists handling REDCap project metadata.
#' 
#' @param pattern The regular expression pattern.  Required.
#' @param text The text to apply the regex against.  Required.
#' @param select_choices The text containing the choices that should be parsed to determine the \code{id} and \code{label} values.  Required.
#' @param perl Indicates if perl-compatible regexps should be used.  Optional.
#' 
#' @return Currently, a \code{data.frame} is returned a row for each match, and a column for each \emph{named} group witin a match.  For the \code{retrieve_checkbox_choices()} function, the columns will be.
#' \enumerate{
#'  \item \code{id}: The numeric value assigned to each choice (in the data dictionary).
#'  \item \code{label}: The label assigned to each choice (in the data dictionary).
#' }
#' @details 
#' The \code{regex_named_captures()} function is general, and not specific to REDCap; it accepts any arbitrary regular expression.  
#' It returns a \code{data.frame} with as many columns as named matches.
#' 
#' The \code{checkbox_choices()} function is specialized, and accommodates the "select choices" for a \emph{single} REDCap checkbox group (where multiple boxes can be selected).  
#' It returns a \code{data.frame} with two columns, one for the numeric id and one fo the text label.
#' 
#' @author Will Beasley
#' @references See the official documentation for permissible characters in a checkbox label. \emph{I'm bluffing here, because I don't know where this is located.  If you know, please tell me.}
#' 
#' @examples
#' library(REDCapR) #Load the package into the current R session.
#' #The weird ranges are to avoid the pipe character; PCRE doesn't support character negation.
#' pattern_boxes <- "(?<=\\A| \\| )(?<id>\\d{1,}), (?<label>[\x20-\x7B\x7D-\x7E]{1,})(?= \\| |\\Z)"
#' 
#' choices_1 <- paste0(
#'   "1, American Indian/Alaska Native | ", 
#'   "2, Asian | ",
#'   "3, Native Hawaiian or Other Pacific Islander | ",
#'   "4, Black or African American | ",
#'   "5, White | ",
#'   "6, Unknown / Not Reported")
#'   
#' #This calls the general function, and requires the correct regex pattern.
#' regex_named_captures(pattern=pattern_boxes, text=choices_1)
#' 
#' #This function is designed specifically for the checkbox values.
#' checkbox_choices(select_choices=choices_1)
#' 
#' \dontrun{
#' uri         <- "https://bbmc.ouhsc.edu/redcap/api/"
#' token       <- "9A81268476645C4E5F03428B8AC3AA7B"
#' 
#' ds_metadata <- redcap_metadata_read(redcap_uri=uri, token=token)$data
#' choices_2   <- ds_metadata[ds_metadata$field_name=="race", "select_choices_or_calculations"]
#' 
#' regex_named_captures(pattern=pattern_boxes, text=choices_2)
#' }

regex_named_captures <- function( pattern, text, perl=TRUE ) {
  match <- gregexpr(pattern, text, perl=perl)[[1]]
  capture_names <- attr(match, "capture.names")
  d <- as.data.frame(matrix(NA, nrow=length(attr(match, "match.length")), ncol=length(capture_names)))
  colnames(d) <- capture_names
  
  for( column_name in colnames(d) ) {
    d[, column_name] <- mapply( 
      function (start, len) substr(text, start, start+len-1),
      attr(match, "capture.start")[, column_name],
      attr(match, "capture.length")[, column_name] 
    )
  }
  return( d )
}

#' @rdname metadata_utilities
#' @export
checkbox_choices <- function( select_choices ) {
  #The weird ranges are to avoid the pipe character; PCRE doesn't support character negation.
  pattern_checkboxes <- "(?<=\\A| \\| )(?<id>\\d{1,}), (?<label>[\x21-\x7B\x7D-\x7E ]{1,})(?= \\| |\\Z)" 
  
  d <- regex_named_captures(pattern=pattern_checkboxes, text=select_choices)
  return( d )
}

# pattern_checkboxes <- "(?<=\\A| \\| )(?<id>\\d{1,}), (?<label>[\x20-\x7B\x7D-\x7E]{1,})(?= \\| |\\Z)"
# 
# choices_1 <- "1, American Indian/Alaska Native | 2, Asian | 3, Native Hawaiian or Other Pacific Islander | 4, Black or African American | 5, White | 6, Unknown / Not Reported"
# regex_named_captures(pattern=pattern_checkboxes, text=choices_1)
# 
# regmatches(choices, regexpr("(?<=\\A| \\| )(?<id>\\d{1,}), (?<label>[\\w ]{1,})(?= \\| |\\Z)", choices, perl=TRUE));
# choices_1 <- paste0(
#   "1, American Indian/Alaska Native | ", 
#   "2, Asian | ",
#   "3, Native Hawaiian or Other Pacific Islander | ",
#   "4, Black or African American | ",
#   "5, White | ",
#   "6, Unknown / Not Reported")

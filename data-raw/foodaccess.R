# Download and preprocess Food Access Atlas file
lcl <- "data-raw/access"
zfl <- "2019 Food Access Research Atlas Data.zip"
ufl <- "Food Access Research Atlas.csv"

if (!file.exists(lcl)) {
  src <- "https://ers.usda.gov/sites/default/files/_laserfiche/DataFiles/80591/2019%20Food%20Access%20Research%20Atlas%20Data.zip?v=60094"

  os <- .Platform$OS.type

  if (os == "windows") {
    d_mode <- "wb"
  } else {
    d_mode <- "w"
  }

  tmp <- tempfile(fileext = ".zip")
  tryCatch({
    exit_code <- download.file(src, tmp, quiet = TRUE, mode = d_mode)

  }, error = function(e) {
    conditionMessage(e)
  }, warning = function(w) {
    if (grepl("404", w$message) || grepl("resolve", w)) {
      war <- simpleWarning("Resource is no longer available, please contact package maintaner.")
      conditionMessage(war)
    } else if (grepl("Timeout", w)) {
      current_timeout <- getOption('timeout')
      msg1 <- paste("Timeout of", current_timeout, "seconds was reached.")
      msg2 <- "If you have slow internet access, consider setting a longer timeout by running:"
      msg3 <- "options(timeout=x) Where x is timeout duration in seconds."

      msgs <- c(msg1, msg2, msg3)

      conditionMessage(simpleWarning(msgs))
    } else {
      conditionMessage(w)
    }
  })

  # If the download failed without warning or errors
  if (exit_code != 0) {
    warning("The dataset was unable to be downloaded for some unknown reason.")
    return(NULL)
  }

  dir.create(lcl)

  # Move the zipped file to its final resting place
  res <- file.rename(from=tmp,
                     to=file.path(lcl, zfl))
  if (!res) {
    stop("Downloaded file was unable to be moved.")
  }
}

# Unzip the file
unzip(file.path(lcl, zfl), exdir = lcl, junkpaths = TRUE)

# After reaching out to the USDA in regards to the meaning of the "NULL"s present in the file,
# I learned that they can be treated as zeros. They do not represent missing data.
# readr will pull in most columns as type character due to the "NULL" strings present.
# Substitute "0" for "NULL" and then convert appropriate columns to numeric.
# guess_max = Inf necessary to prevent issues with read_csv assuming a column is numeric
# when only reading the first 1000 lines. In some cases the first "NULL" is after 1000 lines.
# TODO We could speed this up by telling read_csv what each column should be.
# Most columns contain some NULL strings, so tell readr to make all columns
# character type (except the first column).
c_types <- paste0(rep("c", 146), collapse = "")

c_types <- paste0("n", c_types)

foodaccess <- readr::read_csv(file.path(lcl, ufl), na = c("", "NA"), col_types = c_types)

foodaccess[foodaccess == "NULL"] <- "0"
foodaccess <- foodaccess %>%
  dplyr::mutate_at(c(4:ncol(foodaccess)), as.numeric)

# Rename first 25 columns for clarity and uniform lowercase
# More will be renamed later
new_colnames <- c("census_tract", "state", "county", "urban_flag", "pop2010",
                  "ohu2010", "group_quarters_flag", "num_in_group_quarters",
                  "pct_in_group_quarters", "li_la_1_10", "li_la_half_10",
                  "li_la_1_20", "li_la_vehicle", "la_lva_flag",
                  "low_income_tracts", "poverty_rate", "median_family_income",
                  "la_1_10", "la_half_10", "la_1_20", "la_tracts_half", "la_tracts_1",
                  "la_tracts_10", "la_tracts_20", "la_tracts_vehicle_20")

colnames(foodaccess)[1:25] <- new_colnames


# Remove Alaska observations until we can convert the old county data to their new counties.
#foodatlas <- foodatlas %>%
#  dplyr::filter(state != "Alaska")

# Convert Connecticut county names to work with usmapdata/usmap
foodaccess_only_ct <- foodaccess %>%
  dplyr::filter(state == "Connecticut")

ct_tracts <- foodaccess_only_ct$census_tract

# Couldn't do a simple name swap.
# New counties have different shapes encapsulating different census tracts.
# Iterate through each census tract and change them to the new associated county.
# The object ct_data was stored in the package via usethis::use_data
for (tract in ct_tracts) {
  tract_idx <- which(ct_data$census_tract == tract)
  new_county <- ct_data$new_county[tract_idx]
  tgt_idx <- which(foodaccess$census_tract == tract)
  foodaccess$county[tgt_idx] <- new_county
}

# Clean up, clean up
# Remove the unzipped files as we no longer need them (leave the zipped file)
files_for_removal <- list.files(path = lcl, pattern = ".csv")
res <- file.remove(file.path(lcl, files_for_removal))

rm(tgt_idx, new_county, tract_idx, tract, ct_tracts, foodaccess_only_ct)
rm(new_colnames, c_types, zfl, ufl, lcl, res, files_for_removal)

# Using default bzip2 compression. xz is slightly smaller (6,571KB vs 7,157KB), but takes much longer
usethis::use_data(foodaccess, overwrite = TRUE, compress = "bzip2")

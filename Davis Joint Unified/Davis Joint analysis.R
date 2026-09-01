#Author: Angela Shen

library(readxl)
library(dplyr)
library(purrr)
library(here)
library(stringr)
library(tidyr)

# ------------------------------------------------------------
# 1. File paths
# ------------------------------------------------------------

ADAfile <- here(
  "Davis Joint Unified",
  "raw data",
  "Davis Joint Unified ADA_copy.xlsx"
)

Mealfile <- here(
  "Davis Joint Unified",
  "raw data",
  "Davis Joint Unified Meal cleaned_copy.xlsx"
)


# ------------------------------------------------------------
# 2. Read data
# ------------------------------------------------------------

meal_all <- read_excel(
  Mealfile
)

ADA_all <- read_excel(
  ADAfile,
  col_names = FALSE
)


# ------------------------------------------------------------
# 3. Clean ADA data
# ------------------------------------------------------------

names(ADA_all) <- c(
  "school_info",
  "grade_level",
  "extra",
  "apportioned_present_enrollment"
)

ADA_all <- ADA_all |>
  mutate(
    school_name = if_else(
      !is.na(school_info) &
        str_detect(school_info, "Elementary"),
      school_info,
      NA_character_
    )
  ) |>
  fill(school_name)


ADA_summary <- ADA_all |>
  filter(
    school_info == "Regular"
  ) |>
  select(
    school_name,
    apportioned_present_enrollment
  )


# ------------------------------------------------------------
# 4. Clean meal data
# ------------------------------------------------------------

meal_all <- meal_all |>
  filter(
    !if_all(everything(), is.na)
  )

davis_meal <- meal_all |>
  filter(
    grepl("Elementary", `School Name`)
  ) |>
  select(
    school_name = `School Name`,
    Total
  )


# ------------------------------------------------------------
# 5. Standardize school names
# ------------------------------------------------------------

ADA_summary <- ADA_summary |>
  mutate(
    school_name = case_when(
      school_name == "Monarca Elementary (formerly CCE)" ~
        "Monarca Elementary",
      TRUE ~ school_name
    )
  )


# ------------------------------------------------------------
# 6. Check school-name matching
# ------------------------------------------------------------

setdiff(
  davis_meal$school_name,
  ADA_summary$school_name
)

setdiff(
  ADA_summary$school_name,
  davis_meal$school_name
)


# ------------------------------------------------------------
# 7. Combine ADA and meal data
# ------------------------------------------------------------

davis_final <- ADA_summary |>
  left_join(
    davis_meal,
    by = "school_name"
  )


# ------------------------------------------------------------
# 8. Convert attendance rate to numeric
# ------------------------------------------------------------

davis_final <- davis_final |>
  mutate(
    apportioned_present_enrollment =
      as.numeric(apportioned_present_enrollment)
  )


# ------------------------------------------------------------
# 9. Final check
# ------------------------------------------------------------

glimpse(davis_final)

davis_final
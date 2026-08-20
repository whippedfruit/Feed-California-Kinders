# ============================================================
# Ojai Unified School District
# Meal Distribution Data Processing
#
# Purpose:
#   Combine meal distribution data from multiple school sheets,
#   standardize school names and grade groups, and create a
#   summary table that matches attendance data.
#
# Author: Angela Shen
# Project: Ojai Kindmeal
# ============================================================


# ------------------------------------------------------------
# 1. Load packages
# ------------------------------------------------------------

library(readxl)
library(dplyr)
library(purrr)
library(here)


# ------------------------------------------------------------
# 2. Read meal workbook
# ------------------------------------------------------------
# Each sheet represents one school.
# The sheet name is used as the original school identifier.

file <- here(
  "Ojai Unified",
  "raw data",
  "Ojai Meal Totals 25-26 copy.xlsx"
)

sheets <- excel_sheets(file)


# ------------------------------------------------------------
# 3. Combine all school sheets
# ------------------------------------------------------------

meal_all <- map_dfr(
  sheets,
  function(sheet_name) {
    
    read_excel(
      file,
      sheet = sheet_name
    ) |>
      mutate(
        school = sheet_name
      )
    
  }
)


# ------------------------------------------------------------
# 4. Extract annual meal totals by grade group
# ------------------------------------------------------------
# Each grade-group section contains monthly meal counts
# followed by a TOTAL row.
#
# We use the TOTAL row directly rather than summing the
# monthly values.

ojai_meal <- meal_all |>
  filter(
    `Grades:TK & PREK` == "TOTAL" |
      `Grades: K-6` == "TOTAL" |
      `Grades: 7-12` == "TOTAL" |
      `Grades: 9-12` == "TOTAL" |
      `Grades:K-12` == "TOTAL"
  ) |>
  mutate(
    grade_group = case_when(
      `Grades:TK & PREK` == "TOTAL" ~ "TK & PREK",
      `Grades: K-6` == "TOTAL" ~ "K-6",
      `Grades: 7-12` == "TOTAL" ~ "7-12",
      `Grades: 9-12` == "TOTAL" ~ "9-12",
      `Grades:K-12` == "TOTAL" ~ "K-12",
      TRUE ~ NA_character_
    )
  ) |>
  select(
    school,
    grade_group,
    Breakfast,
    Lunch
  )


# ------------------------------------------------------------
# 5. Standardize school names
# ------------------------------------------------------------
# Keep the original sheet name in `school`.
# Create `school_name` to match the attendance data.

ojai_meal <- ojai_meal |>
  mutate(
    school_name = case_when(
      
      school == "Meiners Oaks Early Elementary" ~
        "Meiners Oaks",
      
      school == "Topa Topa Elementary" ~
        "Topa Topa",
      
      school == "Mira Monte Elementary" ~
        "Mira Monte",
      
      school == "Nordhoff Junior High & High Sch" ~
        "Nordhoff Junior High",
      
      school == "Legacy High School" ~
        "Legacy High",
      
      school == "Summit School" ~
        "Summit",
      
      TRUE ~ school
    )
  )


# ------------------------------------------------------------
# 6. Calculate total meals
# ------------------------------------------------------------

ojai_meal <- ojai_meal |>
  mutate(
    Total_meals =
      coalesce(Breakfast, 0) +
      coalesce(Lunch, 0)
  )


# ------------------------------------------------------------
# 7. Final meal dataset
# ------------------------------------------------------------

ojai_meal <- ojai_meal |>
  select(
    school_name,
    grade_group,
    Breakfast,
    Lunch,
    Total_meals
  )
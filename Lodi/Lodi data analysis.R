# ------------------------------------------------------------
# Lodi data analysis
# ------------------------------------------------------------

library(readxl)
library(dplyr)
library(stringr)
library(purrr)
library(here)

# ------------------------------------------------------------
# Import data
# 1st Excel sheet represents breakfast, 2nd lunch
# ------------------------------------------------------------

file <- here(
  "Lodi",
  "cleaned data",
  "Lodi Data_copy.xlsx"
)

ADA_meal <- map_dfr(
  excel_sheets(file),
  \(sheet_name) {
    read_excel(file, sheet = sheet_name) |>
      mutate(meal_kind = sheet_name)
  }
)


file2 <- here(
  "Lodi",
  "cleaned data",
  "Lodi FreeReduced eligibility_copy.xlsx"
)

Eligibility <- map_dfr(
  excel_sheets(file2),
  \(sheet_name) {
    read_excel(file2, sheet = sheet_name) |>
      mutate(grade = sheet_name)
  }
)


Eligibility <- Eligibility |>
  filter(
    !is.na(`...1`) |
      row_number() == min(which(is.na(`...1`)))
  )

Preschool_data <- read_excel(
  here(
    "Lodi",
    "cleaned data",
    "Lodi Preschool eligibility.xlsx")
)
  
  
  
preschool_meals <- Preschool_data |>
  select(
    School,
    Total,
    `Average Daily Attendance`,
  ) |>
  mutate(
    meals_per_person_day =
      Total / (`Average Daily Attendance`*180
                )
  )
  
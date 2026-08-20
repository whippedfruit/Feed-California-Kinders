# ------------------------------------------------------------
# Ventura ADA analysis
# ------------------------------------------------------------

library(readxl)
library(dplyr)
library(stringr)
library(purrr)
library(here)


# ------------------------------------------------------------
# Import ADA data
# Each Excel sheet represents one school
# ------------------------------------------------------------

library(here)

file <- here(
  "Ventura Unified",
  "extracted data",
  "Ventura 8:13:2025 - 6:4:2026 ADA clear_copy.xlsx"
)

sheets <- excel_sheets(file)

ADA_all <- map_dfr(
  sheets,
  function(sheet_name){
    
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
# Remove completely empty columns
# ------------------------------------------------------------

ADA_clean <- ADA_all |>
  select(
    where(~ !all(is.na(.)))
  )


# ------------------------------------------------------------
# Standardize column names
# ------------------------------------------------------------

ADA_clean <- ADA_clean |>
  rename(
    school_name = School,
    grade = Grd,
    enrollment = Enrollment,
    attendance = Attendance,
    absence = Absences,
    ADA_percent = `ADA %`
  )


# ------------------------------------------------------------
# Identify and remove school total rows
# ------------------------------------------------------------

ADA_clean <- ADA_clean |>
  mutate(
    row_type = case_when(
      `...4` == "School Totals:" ~ "school_total",
      TRUE ~ "grade"
    )
  ) |>
  filter(
    row_type == "grade"
  )


# ------------------------------------------------------------
# Remove adult program grades
# Grades 17 and 18 are outside study scope
# ------------------------------------------------------------

ADA_clean <- ADA_clean |>
  filter(
    !grade %in% c("17", "18")
  )


# ------------------------------------------------------------
# Keep elementary grades only and standardize grade names
# Ventura data includes PS through Grade 5
# ------------------------------------------------------------

ADA_clean <- ADA_clean |>
  mutate(
    grade = case_when(
      
      grade %in% c("PS", "TK") ~ grade,
      
      grade == "K" ~ "K",
      
      grade %in% c(
        "1",
        "2",
        "3",
        "4",
        "5"
      ) ~ grade,
      
      TRUE ~ NA_character_
      
    )
  ) |>
  filter(
    !is.na(grade)
  )


# ------------------------------------------------------------
# Keep final ADA variables
# ------------------------------------------------------------

ADA_clean <- ADA_clean |>
  select(
    school_name,
    grade,
    enrollment,
    attendance,
    absence,
    ADA_percent
  )

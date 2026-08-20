# ============================================================
# Ojai Unified School District
# Attendance Data Processing
#
# Purpose:
#   Read attendance records, clean school and grade information,
#   summarize attendance by school and grade group, and create
#   a dataset that matches the meal distribution data.
#
# Author: Angela Shen
# Project: Ojai Kindmeal
# ============================================================


# ------------------------------------------------------------
# 1. Load packages
# ------------------------------------------------------------

library(readxl)
library(dplyr)
library(stringr)
library(here)


# ------------------------------------------------------------
# 2. Read attendance workbook
# ------------------------------------------------------------

attendance_file <- here(
  "Ojai Unified",
  "raw data",
  "Ojai Attendance 25-26 copy.xlsx"
)

attendance <- read_excel(
  attendance_file,
  sheet = "Attndance Data"
)

# ------------------------------------------------------------
# 3. Extract school codes
# ------------------------------------------------------------

attendance <- attendance |>
  mutate(
    school_code = str_extract(Track, "(?<=T )[A-Z]+")
  )


# ------------------------------------------------------------
# 4. School lookup table
# ------------------------------------------------------------

school_lookup <- tibble(
  school_code = c(
    "MO",
    "MM",
    "TT",
    "SUM",
    "NHS",
    "NJHS",
    "LHS"
  ),
  
  school_name = c(
    "Meiners Oaks",
    "Mira Monte",
    "Topa Topa",
    "Summit",
    "Nordhoff High School",
    "Nordhoff Junior High",
    "Legacy High"
  )
)


# ------------------------------------------------------------
# 5. Match school codes to school names
# ------------------------------------------------------------

attendance <- attendance |>
  left_join(
    school_lookup,
    by = "school_code"
  )


# ------------------------------------------------------------
# 6. Convert grade codes
# ------------------------------------------------------------

attendance <- attendance |>
  mutate(
    
    grade_name = case_when(
      
      Grade == "TK" ~ "TK",
      
      Grade == "00" ~ "K",
      
      Grade == "01" ~ "1",
      
      Grade == "02" ~ "2",
      
      Grade == "03" ~ "3",
      
      Grade == "04" ~ "4",
      
      Grade == "05" ~ "5",
      
      Grade == "06" ~ "6",
      
      Grade == "07" ~ "7",
      
      Grade == "08" ~ "8",
      
      Grade == "09" ~ "9",
      
      Grade == "10" ~ "10",
      
      Grade == "11" ~ "11",
      
      Grade == "12" ~ "12",
      
      TRUE ~ NA_character_
      
    )
    
  )

# ------------------------------------------------------------
# 7. Create grade groups
# ------------------------------------------------------------
# Grade groups are defined to match the meal distribution data.
# Some schools only report meals by broader grade categories.

attendance <- attendance |>
  mutate(
    
    grade_group = case_when(
      
      # Meiners Oaks
      school_code == "MO" ~ "TK",
      
      # Mira Monte & Topa Topa
      school_code %in% c("MM", "TT") &
        grade_name %in% c(
          "K", "1", "2", "3",
          "4", "5", "6"
        ) ~ "K-6",
      
      # Summit reports one combined TK-12 category
      school_code == "SUM" ~ "TK-12",
      
      # Nordhoff Junior High
      school_code == "NJHS" &
        grade_name %in% c("7", "8") ~ "7-8",
      
      # Nordhoff High School
      school_code == "NHS" &
        grade_name %in% c(
          "9",
          "10",
          "11",
          "12"
        ) ~ "9-12",
      
      # Legacy High
      school_code == "LHS" &
        grade_name %in% c(
          "9",
          "10",
          "11",
          "12"
        ) ~ "9-12",
      
      TRUE ~ NA_character_
      
    )
    
  )


# ------------------------------------------------------------
# 8. Summarize attendance
# ------------------------------------------------------------

attendance_summary <- attendance |>
  
  filter(
    !is.na(grade_group)
  ) |>
  
  group_by(
    school_name,
    grade_group
  ) |>
  
  summarise(
    
    total_actual_present =
      sum(
        `Actual Present`,
        na.rm = TRUE
      ),
    
    .groups = "drop"
    
  )


# ------------------------------------------------------------
# 9. Combine Nordhoff
# ------------------------------------------------------------
# Meal data combines Nordhoff Junior High and Nordhoff High
# School into one 7-12 category.
#
# Therefore attendance is aggregated to the same level.

attendance_summary <- attendance_summary |>
  
  mutate(
    
    school_name = case_when(
      
      school_name %in% c(
        "Nordhoff Junior High",
        "Nordhoff High School"
      ) ~ "Nordhoff Junior High",
      
      TRUE ~ school_name
      
    ),
    
    grade_group = case_when(
      
      school_name == "Nordhoff Junior High" &
        grade_group %in% c(
          "7-8",
          "9-12"
        ) ~ "7-12",
      
      TRUE ~ grade_group
      
    )
    
  ) |>
  
  group_by(
    
    school_name,
    grade_group
    
  ) |>
  
  summarise(
    
    total_actual_present =
      sum(
        total_actual_present
      ),
    
    .groups = "drop"
    
  )


# ------------------------------------------------------------
# 10. Check results
# ------------------------------------------------------------

attendance_summary

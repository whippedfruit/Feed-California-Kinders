# ============================================================
# Ojai Unified School District
# Final Attendance and Meal Analysis
#
# Purpose:
#   Combine attendance and meal distribution data and calculate
#   breakfast and lunch participation rates.
#
# Author: Angela Shen
# Project: Ojai Kindmeal
# ============================================================

# ------------------------------------------------------------
# 1. Load packages
# ------------------------------------------------------------

library(dplyr)


# ------------------------------------------------------------
# 2. Combine attendance and meal data
# ------------------------------------------------------------
# Attendance and meal data are matched by:
#
#   school_name + grade_group
#
# Meiners Oaks and Summit have non-matching grade groups
# between the attendance and meal datasets. These cases are
# retained and flagged below rather than modifying the data.

ojai_final <- attendance_summary |>
  left_join(
    ojai_meal,
    by = c(
      "school_name",
      "grade_group"
    )
  )


# ------------------------------------------------------------
# 3. Calculate meal participation rates
# ------------------------------------------------------------

ojai_final <- ojai_final |>
  mutate(
    
    breakfast_rate =
      Breakfast / total_actual_present,
    
    lunch_rate =
      Lunch / total_actual_present,
    
    total_rate =
      Total_meals / total_actual_present
    
  )


# ------------------------------------------------------------
# 4. Flag grade-group mismatches
# ------------------------------------------------------------
# These schools have different grade-group definitions between
# attendance and meal data.
#
# Meiners Oaks:
#   ADA  = TK
#   Meal = TK & PREK
#
# Summit:
#   ADA  = TK-12
#   Meal = K-12

ojai_final <- ojai_final |>
  mutate(
    
    grade_group_match = case_when(
      
      school_name == "Meiners Oaks" &
        grade_group == "TK" ~
        "No: ADA = TK; Meal = TK & PREK",
      
      school_name == "Summit" &
        grade_group == "TK-12" ~
        "No: ADA = TK-12; Meal = K-12",
      
      TRUE ~
        "Yes"
      
    )
    
  )


# ------------------------------------------------------------
# 5. Final check
# ------------------------------------------------------------

ojai_final

glimpse(ojai_final)
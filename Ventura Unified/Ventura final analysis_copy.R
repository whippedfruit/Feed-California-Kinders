# ------------------------------------------------------------
# Ventura Final Analysis
# ------------------------------------------------------------

library(readxl)
library(dplyr)
library(stringr)
library(purrr)
library(ggplot2)

# ------------------------------------------------------------
# Combine ADA and Meal data
# ------------------------------------------------------------
# Match students to meal data using standardized school name
# and grade.

ventura_analysis <- ADA_clean |>
  left_join(
    ventura_meal,
    by = c(
      "school_name",
      "grade"
    )
  )


# ------------------------------------------------------------
# Calculate total meals
# ------------------------------------------------------------
# Missing Breakfast or Lunch values indicate that no meal data
# were recorded for that meal type. These are treated as zero
# when calculating the total number of meals.

ventura_analysis <- ventura_analysis |>
  mutate(
    total_meals =
      coalesce(Breakfast, 0) +
      coalesce(Lunch, 0)
  )

# ------------------------------------------------------------
# Number of student school days in the 2025-26 school year
# ------------------------------------------------------------

school_days <- 178

# ------------------------------------------------------------
# Calculate meal participation rate
# ------------------------------------------------------------
# Meal counts are cumulative across the school year.
# Average Daily Enrollment (ADE) is therefore multiplied by
# the number of student school days.

ventura_analysis <- ventura_analysis |>
  mutate(
    meal_rate =
      total_meals /
      (enrollment * school_days) *
      100
  )

plot_data <- ventura_analysis |>
  mutate(
    breakfast_rate = Breakfast / (attendance * 178) * 100,
    lunch_rate = Lunch / (attendance * 178) * 100
  )

# ------------------------------------------------------------
# Classify grades by school-day structure
# ------------------------------------------------------------
# TK and K are treated as half-day grades.
# Grades 1-5 are treated as full-day grades.

ventura_analysis <- ventura_analysis |>
  mutate(
    grade_type = case_when(
      grade %in% c("TK", "K") ~ "Half-day",
      grade %in% c("1", "2", "3", "4", "5") ~ "Full-day",
      TRUE ~ NA_character_
    )
  )

# ------------------------------------------------------------
# Quality checks for the final analysis dataset
# ------------------------------------------------------------


# ------------------------------------------------------------
# 1. Check whether ADA_clean has duplicate school-grade rows
# ------------------------------------------------------------

ADA_clean |>
  count(
    school_name,
    grade
  ) |>
  filter(
    n > 1
  )


# ------------------------------------------------------------
# 2. Check whether the ADA + Meal join created duplicate rows
# ------------------------------------------------------------

ventura_analysis |>
  count(
    school_name,
    grade
  ) |>
  filter(
    n > 1
  )


# ------------------------------------------------------------
# 3. Check number of observations by grade
# ------------------------------------------------------------

ventura_analysis |>
  count(
    grade
  )


# ------------------------------------------------------------
# 4. Check number of observations by grade type
# ------------------------------------------------------------

ventura_analysis |>
  count(
    grade_type
  )


# ------------------------------------------------------------
# 5. Check for missing meal data
# ------------------------------------------------------------

ventura_analysis |>
  mutate(
    meal_status = case_when(
      !is.na(Breakfast) & !is.na(Lunch) ~ "Breakfast + Lunch",
      !is.na(Breakfast) & is.na(Lunch) ~ "Breakfast only",
      is.na(Breakfast) & !is.na(Lunch) ~ "Lunch only",
      TRUE ~ "No meal data"
    )
  ) |>
  count(
    meal_status
  )


# ------------------------------------------------------------
# 6. Identify observations with missing meal data
# ------------------------------------------------------------

ventura_analysis |>
  filter(
    is.na(Breakfast) & is.na(Lunch)
  ) |>
  select(
    school_name,
    grade
  )


# ------------------------------------------------------------
# 7. Check meal-rate distribution
# ------------------------------------------------------------

ventura_analysis |>
  summarise(
    min_meal_rate = min(
      meal_rate,
      na.rm = TRUE
    ),
    max_meal_rate = max(
      meal_rate,
      na.rm = TRUE
    ),
    mean_meal_rate = mean(
      meal_rate,
      na.rm = TRUE
    ),
    median_meal_rate = median(
      meal_rate,
      na.rm = TRUE
    )
  )


# ------------------------------------------------------------
# 8. Identify unusually high meal rates
# ------------------------------------------------------------

ventura_analysis |>
  filter(
    meal_rate > 100
  ) |>
  select(
    school_name,
    grade,
    enrollment,
    Breakfast,
    Lunch,
    total_meals,
    meal_rate
  )


# ------------------------------------------------------------
# 9. Check final school-grade coverage
# ------------------------------------------------------------

ventura_analysis |>
  count(
    school_name,
    grade
  ) |>
  arrange(
    school_name,
    grade
  )

# ------------------------------------------------------------
# Descriptive analysis: Meal rate by grade
# ------------------------------------------------------------

ventura_analysis |>
  group_by(grade) |>
  summarise(
    n = n(),
    mean_meal_rate = mean(
      meal_rate,
      na.rm = TRUE
    ),
    median_meal_rate = median(
      meal_rate,
      na.rm = TRUE
    ),
    sd_meal_rate = sd(
      meal_rate,
      na.rm = TRUE
    ),
    min_meal_rate = min(
      meal_rate,
      na.rm = TRUE
    ),
    max_meal_rate = max(
      meal_rate,
      na.rm = TRUE
    ),
    .groups = "drop"
  )

# ------------------------------------------------------------
# Descriptive analysis: Half-day vs Full-day
# ------------------------------------------------------------

ventura_analysis |>
  filter(
    !is.na(grade_type)
  ) |>
  group_by(grade_type) |>
  summarise(
    n = n(),
    mean_meal_rate = mean(
      meal_rate,
      na.rm = TRUE
    ),
    median_meal_rate = median(
      meal_rate,
      na.rm = TRUE
    ),
    sd_meal_rate = sd(
      meal_rate,
      na.rm = TRUE
    ),
    min_meal_rate = min(
      meal_rate,
      na.rm = TRUE
    ),
    max_meal_rate = max(
      meal_rate,
      na.rm = TRUE
    ),
    .groups = "drop"
  )

# ------------------------------------------------------------
# Meal rate by grade
# ------------------------------------------------------------

ventura_analysis |>
  filter(
    !is.na(grade_type)
  ) |>
  group_by(
    grade,
    grade_type
  ) |>
  summarise(
    n = n(),
    mean_meal_rate = mean(
      meal_rate,
      na.rm = TRUE
    ),
    median_meal_rate = median(
      meal_rate,
      na.rm = TRUE
    ),
    sd_meal_rate = sd(
      meal_rate,
      na.rm = TRUE
    ),
    .groups = "drop"
  ) |>
  arrange(
    factor(
      grade,
      levels = c("TK", "K", "1", "2", "3", "4", "5")
    )
  )

# ------------------------------------------------------------
# Grade-level descriptive statistics
# ------------------------------------------------------------

grade_summary <- ventura_analysis |>
  filter(
    grade %in% c("TK", "K", "1", "2", "3", "4", "5")
  ) |>
  mutate(
    grade = factor(
      grade,
      levels = c("TK", "K", "1", "2", "3", "4", "5")
    )
  ) |>
  group_by(grade) |>
  summarise(
    n = n(),
    mean_meal_rate = mean(
      meal_rate,
      na.rm = TRUE
    ),
    median_meal_rate = median(
      meal_rate,
      na.rm = TRUE
    ),
    sd_meal_rate = sd(
      meal_rate,
      na.rm = TRUE
    ),
    .groups = "drop"
  )

grade_summary

# ------------------------------------------------------------
# Preparing for plots
# Since Preschool meal seems to have some problems, PS data are excluded from the plots
# ------------------------------------------------------------
ventura_meals_per_person <- ventura_analysis |>
  mutate(
   breakfast_per_person_day = 
     Breakfast / (attendance * 178),
   
   lunch_per_person_day =
     Lunch / (attendance * 178), 
   
   total_meals_per_person_day =
     (Breakfast +Lunch )/ (attendance * 178)
  )


ventura_TK5 <- ventura_meals_per_person |>
  filter(
    grade %in% c("TK","K", "1", "2", "3", "4", "5")
  )

ventura_TK5 |>
  select(
    school_name,
    grade,
    breakfast_per_person_day,
    lunch_per_person_day,
    total_meals_per_person_day
  )

# ------------------------------------------------------------
# Figure 1: Breakfast Meals per Person per Day
# ------------------------------------------------------------

ggplot(
  ventura_TK5,
  aes(
    x = breakfast_per_person_day,
    y = school_name,
    color = grade
  )
) +
  # Draw 1-5 first
  geom_point(
    data = ventura_TK5 |>
      filter(!grade %in% c("TK", "K")),
    size = 3
    ) +
  # Then draw TK & K, so that TK & K can overlap 1-5
  geom_point(
    data = ventura_TK5 |>
      filter(grade %in% c("TK", "K")),
    size = 3
  ) +
  scale_x_continuous(
    breaks = seq(0,1, by = 0.25)
  ) +
  scale_color_manual(
    values = c (
      "TK" = "#E57373",
      "K" = "#C62828",
      "1" = "#42A5F5",
      "2" = "#26A69A",
      "3" = "#66BB6A",
      "4" = "#00897B",
      "5" = "#00569B"
    )
  ) +
  labs(
    title = "Ventura - Breakfast Meals per Person per Day",
    x = "Breakfast meals per person per day",
    y = "School",
    color = "Grade"
  ) +
  theme_minimal()

# ------------------------------------------------------------
# Figure 2: Lunch Meals per Person per Day
# ------------------------------------------------------------

ggplot(
  ventura_TK5,
  aes(
    x = lunch_per_person_day,
    y = school_name,
    color = grade
  )
) +  # Draw 1-5 first
  geom_point(
    data = ventura_TK5 |>
      filter(!grade %in% c("TK", "K")),
    size = 3
  ) +
  # Then draw TK & K, so that TK & K can overlap 1-5
  geom_point(
    data = ventura_TK5 |>
      filter(grade %in% c("TK", "K")),
    size = 3
  ) +
  scale_x_continuous(
    breaks = seq(0,1, by = 0.25)
  ) +
  scale_color_manual(
    values = c (
      "TK" = "#E57373",
      "K" = "#C62828",
      "1" = "#42A5F5",
      "2" = "#26A69A",
      "3" = "#66BB6A",
      "4" = "#00897B",
      "5" = "#00569B"
    )
  ) +
  labs(
    title = "Ventura - Lunch Meals per Person per Day",
    x = "Lunch meals per person per day",
    y = "School",
    color = "Grade"
  ) +
  theme_minimal()

# ------------------------------------------------------------
# Figure 3: Total Meals per Person per Day
# ------------------------------------------------------------

ggplot(
  ventura_TK5,
  aes(
    x = total_meals_per_person_day,
    y = school_name,
    color = grade
  )
) +  # Draw 1-5 first
  geom_point(
    data = ventura_TK5 |>
      filter(!grade %in% c("TK", "K")),
    size = 3
  ) +
  # Then draw TK & K, so that TK & K can overlap 1-5
  geom_point(
    data = ventura_TK5 |>
      filter(grade %in% c("TK", "K")),
    size = 3
  ) +
  scale_x_continuous(
    breaks = seq(0,2, by = 0.25)
  ) +
  scale_color_manual(
    values = c (
      "TK" = "#E57373",
      "K" = "#C62828",
      "1" = "#42A5F5",
      "2" = "#26A69A",
      "3" = "#66BB6A",
      "4" = "#00897B",
      "5" = "#00569B"
    )
  ) +
  labs(
    title = "Ventura - Total Meals per Person per Day",
    x = "Total meals per person per day",
    y = "School",
    color = "Grade"
  ) +
  theme_minimal()


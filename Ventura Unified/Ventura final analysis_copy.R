# ------------------------------------------------------------
# Ventura Final Analysis
# ------------------------------------------------------------

library(readxl)
library(dplyr)
library(stringr)
library(purrr)


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
# Figure 1: Meal service rate by grade
# ------------------------------------------------------------

library(ggplot2)

grade_order <- c(
  "TK",
  "K",
  "1",
  "2",
  "3",
  "4",
  "5"
)

plot_data <- ventura_analysis |>
  filter(
    grade %in% grade_order
  ) |>
  mutate(
    grade = factor(
      grade,
      levels = grade_order
    )
  )

ggplot(
  plot_data,
  aes(
    x = grade,
    y = meal_rate
  )
) +
  geom_boxplot(
    width = 0.6,
    outlier.shape = NA
  ) +
  geom_jitter(
    width = 0.12,
    alpha = 0.6
  ) +
  labs(
    x = "Grade",
    y = "Meal service rate (%)",
    title = "Meal service rate by grade"
  ) +
  theme_minimal()

ggplot(
  ventura_analysis |>
    filter(
      grade %in% c("TK", "K", "1", "2", "3", "4", "5")
    ) |>
    mutate(
      grade = factor(
        grade,
        levels = c("TK", "K", "1", "2", "3", "4", "5")
      )
    ),
  aes(
    x = grade,
    y = meal_rate
  )
) +
  geom_boxplot(
    width = 0.55,
    outlier.shape = NA
  ) +
  geom_jitter(
    width = 0.10,
    alpha = 0.6
  ) +
  labs(
    x = "Grade",
    y = "Meal service rate (%)",
    title = "Meal service rate by grade"
  ) +
  theme_minimal()

# ------------------------------------------------------------
# Figure 2: Meal service rate by school - K Grade
# ------------------------------------------------------------

plot_K <- plot_data |>
  filter(
    grade == "K"
  ) |>
  select(
    school_name,
    breakfast_rate,
    lunch_rate
  ) |>
  pivot_longer(
    cols = c(breakfast_rate, lunch_rate),
    names_to = "meal_type",
    values_to = "participation_rate"
  ) |>
  mutate(
    meal_type = case_when(
      meal_type == "breakfast_rate" ~ "Breakfast",
      meal_type == "lunch_rate" ~ "Lunch"
    )
  )

ggplot(
  plot_K,
  aes(
    x = participation_rate,
    y = school_name,
    color = meal_type
  )
) +
  geom_point(size = 3) +
  labs(
    x = "Meal participation rate (%)",
    y = "School",
    color = "Meal",
    title = "Meal participation rate by school — Kindergarten"
  ) +
  theme_minimal()

# ------------------------------------------------------------
# Figure 3: Meal service rate by school - TK Grade
# ------------------------------------------------------------

plot_TK <- plot_data |>
  filter(
    grade == "TK"
  ) |>
  select(
    school_name,
    breakfast_rate,
    lunch_rate
  ) |>
  pivot_longer(
    cols = c(breakfast_rate, lunch_rate),
    names_to = "meal_type",
    values_to = "participation_rate"
  ) |>
  mutate(
    meal_type = case_when(
      meal_type == "breakfast_rate" ~ "Breakfast",
      meal_type == "lunch_rate" ~ "Lunch"
    )
  )

ggplot(
  plot_TK,
  aes(
    x = participation_rate,
    y = school_name,
    color = meal_type
  )
) +
  geom_point(size = 3) +
  labs(
    x = "Meal participation rate (%)",
    y = "School",
    color = "Meal",
    title = "Meal participation rate by school — TK"
  ) +
  theme_minimal()
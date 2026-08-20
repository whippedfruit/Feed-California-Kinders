# ------------------------------------------------------------
# Ventura meal analysis
# ------------------------------------------------------------

library(readxl)
library(dplyr)
library(stringr)
library(purrr)
library(here)


# ------------------------------------------------------------
# Import Ventura meal data
# ------------------------------------------------------------
# The first row contains a school name rather than column names,
# so the file is imported without using the first row as headers.

mealfile <- here(
  "Ventura Unified",
  "extracted data",
  "Ventura Meal clear_copy.xlsx"
)

meal_raw <- read_excel(
  mealfile,
  col_names = FALSE
)


# ------------------------------------------------------------
# Create row IDs and cleaned labels
# ------------------------------------------------------------

meal_raw2 <- meal_raw |>
  mutate(
    row_id = row_number(),
    label = str_trim(as.character(...1))
  )


# ------------------------------------------------------------
# Grades included in the study
# ------------------------------------------------------------

meal_grades <- c(
  "Pre-K",
  "TK",
  "K",
  "1",
  "2",
  "3",
  "4",
  "5"
)


# ------------------------------------------------------------
# School-name lookup
# ------------------------------------------------------------
# Meal-school names do not always match the school names used
# in the ADA data. This lookup converts meal-school names to
# the standardized school names used in ADA_clean.

ventura_school_lookup <- tibble(
  
  meal_school = c(
    "Atlas K-8",
    "Citrus Glen Elementary",
    "Elmhurst Elementary",
    "EP Foster Elementary",
    "Foothill High School",
    "Juanamaria Elementary",
    "Junipero Serra Elementary",
    "Lemon Grove K-8",
    "Lincoln Elementary",
    "Loma Vista Elementary",
    "Montalvo Elementary",
    "Mound Elementary",
    "Pierpont Elementary",
    "Poinsettia Elementary",
    "Portola Elementary",
    "Sheridan Way",
    "Sunset K-8",
    "Will Rogers Elementary"
  ),
  
  school_name = c(
    "ATLAS",
    "Citrus Glen Elementary School",
    "Elmhurst Elementary School",
    "E. P. Foster Elementary School",
    "Homestead",
    "Juanamaria Elementary School",
    "Junipero Serra Elementary School",
    "Lemon Grove School",
    "Lincoln Elementary School",
    "Loma Vista Elementary School",
    "Montalvo Elementary School",
    "Mound Elementary School",
    "Pierpont Elementary School",
    "Poinsettia Elementary School",
    "Portola Elementary School",
    "Sheridan Way Elementary School",
    "Sunset School",
    "Will Rogers Elementary School"
  )
)

# ------------------------------------------------------------
# Function to extract one Breakfast or Lunch table
# ------------------------------------------------------------

extract_meal_table <- function(
    data,
    start_row,
    end_row,
    meal_type
) {
  
  block <- data |>
    slice(start_row:end_row)
  
  # Find the row containing "Grade"
  grade_row <- which(
    block$label == "Grade"
  )[1]
  
  # Identify the Total column
  header_values <- as.character(
    block[grade_row, ]
  )
  
  total_col <- which(
    header_values == "Total"
  )[1]
  
  # Extract rows below the table header
  result <- block |>
    slice((grade_row + 2):n())
  
  # Extract grade and Total values
  result <- tibble(
    grade = result$label,
    total = as.numeric(
      result[[total_col]]
    )
  )
  
  # Standardize Homestead grade labels
  result <- result |>
    mutate(
      grade = str_remove(
        grade,
        "\\s*-\\s*Homestead$"
      )
    )
  
  # Remove non-grade rows
  result <- result |>
    filter(
      !is.na(grade),
      grade != "",
      !grade %in% c(
        "Meal Total:",
        "Breakfast Total:",
        "Lunch Total:"
      )
    )
  
  # Keep only grades included in the analysis
  result <- result |>
    filter(
      grade %in% meal_grades
    )
  
  # Rename total column according to meal type
  names(result)[2] <- meal_type
  
  result
}


# ------------------------------------------------------------
# Identify school sections
# ------------------------------------------------------------
# Each school appears at the beginning of its section.
# Some schools also appear again in a school-total row.
# We therefore keep only the first occurrence of each school.
#
# The final row of the file contains statistics for all schools
# combined and is excluded from the analysis.

meal_raw2 <- meal_raw2 |>
  filter(
    row_id < 622
  )

school_positions <- meal_raw2 |>
  filter(
    label %in% ventura_school_lookup$meal_school
  ) |>
  group_by(label) |>
  summarise(
    row_id = min(row_id),
    .groups = "drop"
  ) |>
  rename(
    meal_school = label
  ) |>
  arrange(row_id)


# ------------------------------------------------------------
# Define the end of each school section
# ------------------------------------------------------------

school_positions <- school_positions |>
  mutate(
    end_row = lead(row_id) - 1
  )

school_positions$end_row[
  is.na(school_positions$end_row)
] <- max(meal_raw2$row_id)


# ------------------------------------------------------------
# Extract Breakfast and Lunch data for each school
# ------------------------------------------------------------

ventura_meal_list <- map(
  seq_len(nrow(school_positions)),
  
  function(i) {
    
    school <- school_positions$meal_school[i]
    start <- school_positions$row_id[i]
    end <- school_positions$end_row[i]
    
    school_rows <- meal_raw2 |>
      filter(
        row_id >= start,
        row_id <= end
      )
    
    
# --------------------------------------------------------
# Homestead special case
# --------------------------------------------------------
    # The Meal file identifies Homestead under
    # "Foothill High School". Although the table is labeled
    # "Breakfast", we confirmed that these data are actually
    # Lunch data. Homestead does not provide Breakfast.
    
    if (school == "Foothill High School") {
      
      meal_start <- school_rows |>
        filter(
          label == "Breakfast"
        ) |>
        pull(row_id)
      
      lunch <- extract_meal_table(
        meal_raw2,
        start_row = meal_start,
        end_row = end,
        meal_type = "Lunch"
      )
      
      return(
        lunch |>
          mutate(
            meal_school = school
          )
      )
    }
    
    
    # --------------------------------------------------------
    # Standard Breakfast + Lunch schools
    # --------------------------------------------------------
    
    breakfast_start <- school_rows |>
      filter(
        label == "Breakfast"
      ) |>
      pull(row_id)
    
    lunch_start <- school_rows |>
      filter(
        label == "Lunch"
      ) |>
      pull(row_id)
    
    
    # Extract Breakfast
    breakfast <- extract_meal_table(
      meal_raw2,
      start_row = breakfast_start,
      end_row = lunch_start - 1,
      meal_type = "Breakfast"
    )
    
    
    # Extract Lunch
    lunch <- extract_meal_table(
      meal_raw2,
      start_row = lunch_start,
      end_row = end,
      meal_type = "Lunch"
    )
    
    
    # Combine Breakfast and Lunch
    full_join(
      breakfast,
      lunch,
      by = "grade"
    ) |>
      mutate(
        meal_school = school
      )
  }
)


# ------------------------------------------------------------
# Combine all schools
# ------------------------------------------------------------

ventura_meal <- bind_rows(
  ventura_meal_list
)


# ------------------------------------------------------------
# Standardize grade names
# ------------------------------------------------------------
# Pre-K in the Meal data corresponds to PS in the ADA data.

ventura_meal <- ventura_meal |>
  mutate(
    grade = case_when(
      grade == "Pre-K" ~ "PS",
      TRUE ~ grade
    )
  )


# ------------------------------------------------------------
# Standardize school names
# ------------------------------------------------------------
# Convert Meal school names to the names used in ADA_clean.

ventura_meal <- ventura_meal |>
  left_join(
    ventura_school_lookup,
    by = "meal_school"
  )


# ------------------------------------------------------------
# Keep final Meal variables
# ------------------------------------------------------------

ventura_meal <- ventura_meal |>
  select(
    school_name,
    grade,
    Breakfast,
    Lunch,
    meal_school
  )
    
# -----------------------------------------
# Breakfast
# -----------------------------------------

if (length(breakfast_start) > 0) {
  
  breakfast <- extract_meal_table(
    meal_raw2,
    start_row = breakfast_start[1],
    end_row = lunch_start[1] - 1,
    meal_type = "Breakfast"
  )
  
} else {
  
  breakfast <- tibble(
    grade = character(),
    Breakfast = numeric()
  )
  
}


# -----------------------------------------
# Lunch
# -----------------------------------------

if (length(lunch_start) > 0) {
  
  lunch <- extract_meal_table(
    meal_raw2,
    start_row = lunch_start[1],
    end_row = end,
    meal_type = "Lunch"
  )
  
} else {
  
  lunch <- tibble(
    grade = character(),
    Lunch = numeric()
  )
  
}


# -----------------------------------------
# Combine Breakfast and Lunch
# -----------------------------------------

full_join(
  breakfast,
  lunch,
  by = "grade"
) |>
  mutate(
    meal_school = school
  )



# ------------------------------------------------------------
# Combine all schools
# ------------------------------------------------------------

ventura_meal <- bind_rows(
  ventura_meal_list
)


# ------------------------------------------------------------
# Standardize grade names
# ------------------------------------------------------------
# Pre-K in the Meal data corresponds to PS in the ADA data.

ventura_meal <- ventura_meal |>
  mutate(
    grade = case_when(
      grade == "Pre-K" ~ "PS",
      TRUE ~ grade
    )
  )


# ------------------------------------------------------------
# Standardize school names
# ------------------------------------------------------------

ventura_meal <- ventura_meal |>
  left_join(
    ventura_school_lookup,
    by = "meal_school"
  )


# ------------------------------------------------------------
# Correct known data-entry typo
# ------------------------------------------------------------
# Poinsettia Elementary School has one erroneous Grade 02
# Breakfast value of 1. This row is removed from the Meal data.

ventura_meal <- ventura_meal |>
  filter(
    !(
      school_name == "Poinsettia Elementary School" &
        grade == "2" &
        Breakfast == 1
    )
  )


# ------------------------------------------------------------
# Final Meal dataset
# ------------------------------------------------------------

ventura_meal <- ventura_meal |>
  select(
    school_name,
    grade,
    Breakfast,
    Lunch,
    meal_school
  )

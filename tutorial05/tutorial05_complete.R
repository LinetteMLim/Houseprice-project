#################################
# Tutorial 5: Data Manipulation #
#################################

## Packages
library(tidyverse) # Load our packages here
library(broom) # If not installed - function for installing?

?tidyverse
browseVignettes(package = "tidyverse")

## Assign data
# The tidyverse has its own package for reading in data: readr
?readr

# readr uses a very similar format to base r functions. For example, 
# we can read in a csv file using the read_csv() function, which is 
# similar to base R's read.csv() function.
dat <- read.csv("movies.csv")

##########
# Exercise
##########

# Change the above code to use readr's read_csv() function. Assign
# the output to a different object. What do you notice is different 
# about the two functions?

dat1 <- read_csv("movies.csv")
class(dat1) # the movies_csv() function creates a tibble

vignette("tibble")

#######
# dplyr
#######

vignette("dplyr")

# we use the dplyr package to manipulate our data. Manipulation 
# operations can generally be broken down into three basic steps:

## (Filtering on) rows
filter(dat, title_type == "Feature Film")

## (Selecting or mutating on) columns
select(dat, thtr_rel_month)
mutate(dat, rel_mon = month.abb[thtr_rel_month])

## Group by and summarise into a single row
by_month <- group_by(dat, thtr_rel_month)
summarise(by_month, n = n())

##########
# The pipe
##########

# Filtering, selecting and summarising aren't very useful on their 
# own. Their true power comes from combining them together into a 
# single operation. This is where the pipe comes in.

dat %>%
  filter(title_type == "Feature Film") %>% # filter on the rows
  select(thtr_rel_month) %>% # select one column
  mutate(month = month.abb[thtr_rel_month]) %>% # change to month abbreviation
  group_by(month) %>% # group data by month
  summarise(n = n()) %>% # perform a summary operation (count the n per month)
  arrange(desc(n)) # sort in descending order

# Here, we perform 6 operations, one after the other, to manipulate 
# our dataset.

##########
# Exercise
##########

# Using the dplyr functions above with the pipe operator %>% 
# 1. Filter the movies dataset for "Horror" films in the genre 
# column. Which is the most popular month for Horror films to be 
# released?

dat %>%
  filter(genre == "Horror") %>%
  mutate(month = month.abb[thtr_rel_month]) %>%
  group_by(month) %>%
  summarise(n = n()) %>%
  arrange(desc(n))

# 2. Using the dplyr commands you have learned, find the actor 
# (actor1) with the most award wins. 

dat %>%
  filter(best_actor_win == "yes") %>%
  group_by(actor1) %>%
  summarise(n = n()) %>%
  arrange(desc(n))

#######################
# Complex operations...
#######################

# As we improve our dplyr skills, we can perform more complex 
# operations. Let's say we have a hunch about horror films, i.e.
# that, compared with other films, they're more likely to be 
# released in October for Halloween. How might we check this hunch?
# First, we'd need to check the underlying pattern of releases for 
# all films across the year. Let's recycle our code from above, but
# convert the n into proportions.

dat %>%  
  mutate(month = month.abb[thtr_rel_month]) %>% 
  group_by(month) %>% 
  summarise(n = n()) %>%
  mutate(prop_month = round(n / sum(n), 3)) %>% # mutate after our summarise to find the proportion
  arrange(desc(prop_month))

##########
# Exercise
##########

# Using the code above as a template, perform the same operation on 
# a subset of horror films

dat %>%
  filter(genre == "Horror") %>%
  mutate(month = month.abb[thtr_rel_month]) %>% 
  group_by(month) %>% 
  summarise(n = n()) %>%
  mutate(prop_month = round(n / sum(n), 3)) %>% # mutate after our summarise to find the proportion
  arrange(desc(prop_month))

#############
# Visualising
#############

# Now that we know the relative frequency of releases for films, it 
# would be good to be able to visualise these. We could perform 
# some of these grouping and summarise operations directly within 
# ggplot. However, we'll use dplyr here to show how we can 
# manipulate data and then output the results into visualisations.

# Note: try breaking the code below at different points to see what
# is happening to the data at each stage.

dat %>%
  select(genre, thtr_rel_month) %>% # just keep the two relevant cols
  mutate(horror = genre == "Horror") %>% # make a new logical col for horror films
  group_by(thtr_rel_month, horror) %>% # perform a nested grouping operation (release month, then T/F horror)
  summarise(n = n()) %>% # get a raw count for each group
  pivot_wider(names_from = horror, values_from = n) %>% # change the shape of our data
  ungroup() %>%
  mutate(All = round(`FALSE` / sum(`FALSE`), 3), # calculate proportions for all films
         Horror = `TRUE` / sum(`TRUE`, na.rm = TRUE)) %>% # calculate proportions for horror films
  select(thtr_rel_month, All, Horror) %>% # drop all other columns
  pivot_longer(cols = c("All", "Horror"), names_to = "film_type") %>% # change the shape again!
  mutate(month = factor(month.abb[thtr_rel_month], levels = month.abb)) %>% # create a factor for months
  ggplot(aes(month, value)) + # plot the data
  geom_col(aes(fill = film_type), position = "dodge") +
  labs(title = "Proportion of Theatrical Releases by Month", y = "proportion") 

# The code above is quite complex: not only are we filtering and 
# grouping, we are also spreading and gathering our data using the 
# pivot longer and pivot wider functions. These functions change 
# the shape of our dataset, and are necessary here because of the 
# way dplyr performs different calculations. For now though, we 
# don't need to worry too much about them. What's important to note 
# is the way we have used the pipe %>% to chain different operations 
# together, to create a visualisation of our initial question. How 
# would you interpret the bar plot?

##########
# Exercise
##########

# Are feature films getting longer? Use the dplyr functions you've 
# learned about today to find out whether the average running time 
# of feature films has increased in recent years.

dat %>%
  filter(title_type == "Feature Film") %>%
  select(runtime, thtr_rel_year) %>%
  group_by(thtr_rel_year) %>%
  summarise(av_runtime = mean(runtime)) %>%
  ggplot(aes(thtr_rel_year, av_runtime)) +
  geom_line() +
  geom_smooth(col = "red", se = FALSE) +
  labs(title = "Average Theatrical Running Time", 
       subtitle = "Feature Films", 
       x = "Release Year", 
       y = "Average Running Time (minutes)")

#######
# Extra
#######

# Are films that win best picture awards longer than average? 
# How would we test for statistical significance?

# 1. Are they longer?
with(dat[dat$best_pic_win == "yes",], mean(runtime))
with(dat, mean(runtime, na.rm = TRUE))

#2. Is the difference statistically significant?
#a) what is our sample size of "winners"?
nrow(dat[dat$best_pic_win == "yes",])
#b) Is it below 30?
nrow(dat[dat$best_pic_win == "yes",]) < 30
#c) So what test do we perform..?
t.test(x = dat[dat$best_pic_win == "yes", "runtime"], # our "different" mean
       alternative = "greater", # we think winning films are longer, so the mean should be greater
       conf.level = 0.95, # set our confidence level to 95%
       mu = mean(dat[,"runtime"], na.rm = TRUE)) # our "population" mean (estimated from our sample)
#d) How about if we didn't have reason to believe they were longer,
# but that they could also be shorter..?
t.test(x = dat[dat$best_pic_win == "yes", "runtime"],
       alternative = "two.sided", # checking both sides now, so 2.5% threshold on each side
       conf.level = 0.95,
       mu = mean(dat[,"runtime"], na.rm = TRUE))

# Our critical values (t scores) with 6 degrees of freedom:
qt(0.95, df = 6) # in a one-sided test, 5% is all on one side means our critical value is lower.
qt(0.975, df = 6) # in a two-sided test, 2.25% on each side means we need a bigger t value to pass our critical value!

# Note that I didn't use dplyr for any of these operations; with 
# base R programming skills, I didn't need to - I could simply 
# perform the necessary subsetting within the t.test() function.
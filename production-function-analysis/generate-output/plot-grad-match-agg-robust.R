# Start
rm(list = ls())
library(dplyr)
library(data.table)
library(magrittr)
library(ggplot2)
library(stargazer)
library(RColorBrewer)

# Load data
setwd("~/Dropbox (Personal)/calibration2019/")

data  <- fread('./data//submissions-data.csv') %>% tbl_df
gradient_data  <- fread('./analysis/robustness/higher-waittime/gradient/output/gradient.csv')
probability_data  <- fread('./analysis/robustness/higher-waittime/matching-probability/output/matching-probability.csv')

data %<>%
  left_join(gradient_data, by = "index") %>%
  left_join(probability_data, by = "index")


# Add variables
data$pra_range  <- cut(data$r_cpra, c(-0.01,
                                      10,
                                      90,
                                      100))

setDT(data)
data[category == 'p'
     & ((r_abo != 'O'
         & d_abo == 'O') |
          (r_abo == 'AB' 
           & (d_abo == 'A' | d_abo == 'B' ))), Category := 'Overdemanded']
data[category == 'p'
     & ((r_abo == 'O'
         & d_abo != 'O') |
          (d_abo == 'AB' 
           & (r_abo == 'A' | r_abo == 'B' ))), Category := 'Underdemanded']
data[category == 'p'
     & is.na(Category),
     Category := 'Selfdemanded']
data[category == 'a'
     & d_abo == 'O',
     Category := 'Altruist O']
data[category == 'a'
     & d_abo != 'O',
     Category := 'Altruist non-O']
data[category == 'c',
     Category := 'Unpaired']
#data[category == 'c'
#     & r_abo != 'O',
#     cat := 'unpaired non-O']


# Collapse data
collapsed_data <- 
  data %>%
  group_by(Category, category, pra_range) %>%
  summarize(df = mean(df, na.rm = TRUE),
            matching_probability = mean(matching_probability, na.rm = TRUE),
            N = n(), M = n()+40)


# Aesthetic options
textsize = 16

color_palette_that_i_want <- brewer.pal(n = 5, name = "Blues")


collapsed_data$pra_range <- as.character(collapsed_data$pra_range)
collapsed_data[1,3] <- "Altruist"
collapsed_data[2,3] <- "Altruist"
collapsed_data[3,3] <- "[0,10)"
collapsed_data[6,3] <- "[0,10)"
collapsed_data[9,3] <- "[0,10)"
collapsed_data[12,3] <- "[0,10)"
collapsed_data[4,3] <- "[10,90)"
collapsed_data[7,3] <- "[10,90)"
collapsed_data[10,3] <- "[10,90)"
collapsed_data[13,3] <- "[10,90)"
collapsed_data[5,3] <- "[90,100]"
collapsed_data[8,3] <- "[90,100]"
collapsed_data[11,3] <- "[90,100]"
collapsed_data[14,3] <- "[90,100]"

collapsed_data$pra_range <- as.factor(collapsed_data$pra_range)
colnames(collapsed_data)[c(3)] <- "PRA"


# Aggregated
ggplot(data = collapsed_data, aes(x = df, y = matching_probability)) +
  geom_point(aes(shape = PRA), color = 'black',  size = 5) +
  geom_point(aes(shape = PRA,color = Category),size = 4) +
  scale_shape_manual(values=c(15,16, 17, 18,19)) +
  #geom_point(aes(color = Category),size = 2) +
  geom_abline(intercept = 0, slope = 1) +
  xlim(-0.1,2.05) + ylim(0, 1) +
  theme_minimal() +
  scale_colour_brewer() +
  theme(legend.text=element_text(size=10)) +
  theme(text = element_text(size=16)) +
  #ggtitle('Private vs. Social Value of Submissions') +
  xlab('Marginal Product') + ylab('Match Probability') +
  theme(legend.key.size = unit(0.4, "cm"))
ggsave('./output-for-manuscript/figures/marginal-product-aggregated-high.pdf')




# Start
rm(list = ls())
library(dplyr)
library(data.table)
library(magrittr)
library(ggplot2)
library(stargazer)
library(RColorBrewer)

# Load data
setwd("~/Dropbox (Personal)/calibration2019/")

data  <- fread('./data//submissions-data.csv') %>% tbl_df
gradient_data  <- fread('./analysis/robustness/lower-waittime/gradient/output/gradient.csv')
probability_data  <- fread('./analysis/robustness/lower-waittime/matching-probability/output/matching-probability.csv')

data %<>%
  left_join(gradient_data, by = "index") %>%
  left_join(probability_data, by = "index")


# Add variables
data$pra_range  <- cut(data$r_cpra, c(-0.01,
                                      10,
                                      90,
                                      100))

setDT(data)
data[category == 'p'
     & ((r_abo != 'O'
         & d_abo == 'O') |
          (r_abo == 'AB' 
           & (d_abo == 'A' | d_abo == 'B' ))), Category := 'Overdemanded']
data[category == 'p'
     & ((r_abo == 'O'
         & d_abo != 'O') |
          (d_abo == 'AB' 
           & (r_abo == 'A' | r_abo == 'B' ))), Category := 'Underdemanded']
data[category == 'p'
     & is.na(Category),
     Category := 'Selfdemanded']
data[category == 'a'
     & d_abo == 'O',
     Category := 'Altruist O']
data[category == 'a'
     & d_abo != 'O',
     Category := 'Altruist non-O']
data[category == 'c',
     Category := 'Unpaired']
#data[category == 'c'
#     & r_abo != 'O',
#     cat := 'unpaired non-O']


# Collapse data
collapsed_data <- 
  data %>%
  group_by(Category, category, pra_range) %>%
  summarize(df = mean(df, na.rm = TRUE),
            matching_probability = mean(matching_probability, na.rm = TRUE),
            N = n(), M = n()+40)


# Aesthetic options
textsize = 16

color_palette_that_i_want <- brewer.pal(n = 5, name = "Blues")


collapsed_data$pra_range <- as.character(collapsed_data$pra_range)
collapsed_data[1,3] <- "Altruist"
collapsed_data[2,3] <- "Altruist"
collapsed_data[3,3] <- "[0,10)"
collapsed_data[6,3] <- "[0,10)"
collapsed_data[9,3] <- "[0,10)"
collapsed_data[12,3] <- "[0,10)"
collapsed_data[4,3] <- "[10,90)"
collapsed_data[7,3] <- "[10,90)"
collapsed_data[10,3] <- "[10,90)"
collapsed_data[13,3] <- "[10,90)"
collapsed_data[5,3] <- "[90,100]"
collapsed_data[8,3] <- "[90,100]"
collapsed_data[11,3] <- "[90,100]"
collapsed_data[14,3] <- "[90,100]"

collapsed_data$pra_range <- as.factor(collapsed_data$pra_range)
colnames(collapsed_data)[c(3)] <- "PRA"


# Aggregated
ggplot(data = collapsed_data, aes(x = df, y = matching_probability)) +
  geom_point(aes(shape = PRA), color = 'black',  size = 5) +
  geom_point(aes(shape = PRA,color = Category),size = 4) +
  scale_shape_manual(values=c(15,16, 17, 18,19)) +
  #geom_point(aes(color = Category),size = 2) +
  geom_abline(intercept = 0, slope = 1) +
  xlim(-0.1,2.05) + ylim(0, 1) +
  theme_minimal() +
  scale_colour_brewer() +
  theme(legend.text=element_text(size=10)) +
  theme(text = element_text(size=16)) +
  #ggtitle('Private vs. Social Value of Submissions') +
  xlab('Marginal Product') + ylab('Match Probability') +
  theme(legend.key.size = unit(0.4, "cm"))
ggsave('./output-for-manuscript/figures/marginal-product-aggregated-low.pdf')











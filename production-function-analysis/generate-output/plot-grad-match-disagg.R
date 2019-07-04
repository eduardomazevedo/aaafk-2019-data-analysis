# Start
rm(list = ls())
library(dplyr)
library(data.table)
library(magrittr)
library(ggplot2)
library(stargazer)

# Load data
setwd("~/Dropbox (Personal)/calibration2019/")

data  <- fread('./output/shrinkedMP.csv') %>% tbl_df

# Add variables
data$pra_range  <- cut(data$r_cpra, c(-0.1,
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
            shrinkedMP = mean(shrinkedMP, na.rm = TRUE),
            N = n(), M = n()+30)


# Aesthetic options
textsize = 16

color_palette_that_i_want <- brewer.pal(n = 5, name = "Blues")

# Plots
# Individual level
ggplot(data = data, aes(x = shrinked , y = MP,
                        color = Category)) +
  geom_point(shape = 1, size = 2, color = 'blue') +
  geom_point() +
  geom_abline(intercept = 0, slope = 1) +
  xlim(-1,2.5) + ylim(0, 1) +
  theme_minimal() +
  scale_colour_brewer() +
  theme(legend.text=element_text(size=10)) +
  theme(text = element_text(size=16)) +
  #ggtitle('Private vs. Social Value of Submissions') +
  xlab('Marginal Product') + ylab('Match Probability') +
  theme(legend.key.size = unit(0.4, "cm"))
ggsave('./output-for-manuscript/figures/marginal-product-disaggregated.pdf')

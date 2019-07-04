# The newest version of lubridate (and possibly other packages in the tidyverse) requires 
# CCTZ (a C++ time zone package) which requires a newer version of gcc than 4.4.7, which is 
# the standard that comes with Red Hat Enterprise Linux 6.  Further, the new version of 
# tidyverse insists on the newest lubridate.

# UPDATE: gcc has been updated, so plain old install.packages("tidyverse") should work.
# Although, you might need to run "scl enable devtoolset-4 bash" from the command prompt 
# to enable the new version of gcc (5.3.1) on your account
#
# If this doens't work, then the workaround is to install tinyverse 1.2.0 off of Github by 
# using the devtools package to run devtools::install_github("todyverse/tidyverse@v1.2.0").

# Start
rm(list = ls())
library(data.table)
#suppressMessages(library(tidyverse)#)
library(magrittr)
library(dplyr)
library(ggplot2)
suppressMessages(library(stargazer))
library(haven)
library(lubridate)
library(ggthemes)
library(RColorBrewer)
library(DescTools)

# Define colors
# Colors from Edu's previous paper
custom_red  <- "#D55855"
custom_blue <- "#BFD9EF"

# Colors from RColorBewer blue palette
# This 4 colors come from RColorBrewer blue 4. But I replaced the first two by grays because we 
# will assign that to non-NKR
custom_scale_2 <- c("#DEEBF7", "#3182BD")
custom_scale_4 <- c("#F6F6F6", "#D4D4D4", "#6BAED6", "#2171B5")
custom_scale_6 <- c("#F6F6F6", "#D4D4D4", "#E0E8FF", "#A9CCEA", "#6BAED6", "#2171B5")

for (suffix in c("-perfect","")){
# Load data
data_file <- paste0("./datasets/transplant-level-data-full",suffix,".dta")
# the latin1 encoding is required to get Haven to play well with Stata 13.
tx_data   <- read_stata(data_file, encoding='latin1') %>% tbl_df

#####
# Efficiency bar plot

plot_data <- 
  tx_data                                                                            %>%
  filter(is_pke == 1)                                                                %>%
  filter(`_s_abo_don` == "O")                                                        %>%
  mutate(inefficient       = as.numeric(`_s_abo` != "O"))                            %>%
  mutate(category          = recode(ch,
                                      "nkr"    = "nkr",
                                      "apd"    = "apd/unos",
                                      "unos"   = "apd/unos",
                                      .default = tx_category))                       %>%
  mutate(highly_sensitized = (`_s_end_cpra` >= 90),
         highly_sensitized = ifelse(is.na(highly_sensitized), 0, highly_sensitized)) %>%
  select(category, highly_sensitized, inefficient)

       plot_data$category  <- factor(plot_data$category, 
                              c("nkr", "apd/unos", "external pke",                        "internal pke"))
levels(plot_data$category) <- c("NKR", "APD/UNOS", "Other platforms\n(across hospitals)", "Other platforms\n(within hospital)")

# Plot data with breakdown by sensitization
plot_data_sensitization <-
  plot_data                                                     %>%
  group_by(category)                                            %>%
  mutate(n_category           = n())                            %>%
  group_by(category, n_category, highly_sensitized)             %>%
  summarise(total_inefficient = sum(inefficient))               %>%
  mutate(m                    = total_inefficient / n_category) %>%
  mutate(sensitization        = ifelse(highly_sensitized == 1,
                                       "Recipient PRA ≥ 90",
                                       "Recipient PRA < 90"
                                )
  )
#mutate(sensitization        = ifelse((highly_sensitized == 1),
#            "Highly sensitized recipients",
#            "Non highly sensitized recipients"))

contingency_table <- 
  plot_data                                                           %>% 
  mutate_if(is.factor, as.character)                                  %>% 
  group_by(category)                                                  %>% 
  summarize(ineff = sum(inefficient),eff=sum(1-inefficient))          %>%
  filter(category %in% c("NKR","Other platforms\n(within hospital)")) %>%
  data.frame(row.names=.$category)                                    %>% 
  select("ineff","eff")                                               

res <- fisher.test(contingency_table)
if (res$p.value<0.01) {
  x<-"$p<0.01$ % This pct sign makes a LaTeX comment"
} else {
  x<-paste0("$p=",round(res$p.value,2)," % This pct sign makes a LaTeX comment")
}

write(x, file = paste0("./constants/c-nkr-other-within-prop-ineff-pvalue",suffix,".txt"))


# Plot with the breakdown
ggplot(NULL, aes(x = category, y = m))                          +
  geom_bar(data     = plot_data_sensitization,
           aes(y    = m, 
               fill = sensitization %>% factor(levels = c("Recipient PRA ≥ 90",
                                                          "Recipient PRA < 90")
                                        )
               ),
           stat     = "identity",
           position = "stack",
           color    = "black", width = 0.8)                     +
  geom_errorbar(data     = plot_data,
                aes(ymin = m - 1.96*se, 
                    ymax = m + 1.96*se),
                width    = 0.1)                                 +
  ylim(0, 0.25) + scale_y_continuous(labels = scales::percent_format(accuracy = 1))  +
  labs(fill = "", x = "", 
          y = "% O donors matched to non-O patients") +
  theme_bw()                                                    +
  theme(legend.position="bottom",legend.direction="horizontal") +
  scale_fill_manual(values = custom_scale_2) +
  theme(panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
         text = element_text(size = 12))

ggsave(paste0("./figures/efficiency-with-sensitization",suffix,".pdf"), width = 16.2/2, height = 10.0/2,device=cairo_pdf)

x <- round(100*plot_data %>% filter(category=="NKR") %>% pull(m),1)
write(paste0(x,"% This pct sign makes a LaTeX comment"), file = paste0("./constants/c-percentage-inefficient-nkr",suffix,".txt"))

x <- round(100*plot_data %>% filter(category=="Other platforms\n(within hospital)") %>% pull(m),1)
write(paste0(x,"% This pct sign makes a LaTeX comment"), file = paste0("./constants/c-percentage-inefficient-other-within",suffix,".txt"))

####
# Fragmentation over time plots

plot_data <- tx_data                                          %>%
  filter(is_pke == 1)                                         %>%
  select(ch, tx_category, `_s_tx_date`)                       %>%
  mutate( tx_category = recode(tx_category,
                                 `internal pke` = "within hospital",
                                 .default       = "across hospitals"),
         nkr_category = recode(ch,
                                    "nkr"  = "NKR",
                                    "apd"  = "APD/UNOS",
                                    "unos" = "APD/UNOS",
                                 .default  = "Other platforms"),
             category = paste0(nkr_category, " ", tx_category)) %>%
  rename(date = `_s_tx_date`)                                   %>%
  select(category, date)                                        %>%
  arrange(date)                                                 %>%
  mutate(year = year(date))

plot_data <-
  plot_data             %>%
  count(year, category) %>%
  filter(year >= 2008, year <= 2014)

plot_data$category <- factor(plot_data$category,
                                c( "NKR across hospitals",             "NKR within hospital",
                                   "APD/UNOS across hospitals",        "APD/UNOS within hospital",
                                   "Other platforms across hospitals", "Other platforms within hospital"))

p <- ggplot(data = plot_data,
            aes(x = year , y = n, fill = category, group = category))

# Area plot
p + 
  geom_area(size = 0.3, color = "black")                        +
  geom_line(position = "stack")                                 +
  labs(fill = "", x = "Year", y = "Number of Transplants")      +
  theme_bw()                                                    +
  theme(legend.position="bottom",legend.direction="horizontal") +
  scale_fill_manual(values = custom_scale_6)                    +
  theme(# remove the vertical grid lines
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank(),
    text = element_text(size = 12)
    # explicitly set the horizontal lines (or they will disappear too)
    # panel.grid.major.y = element_line( size=.1, color="black" )
  )

ggsave(paste0("./figures/fragmentation-area",suffix,".pdf"), width = 16.2/2, height = 10.0/2) 


n_nkr_tx_2014 <- 
      plot_data                                      %>%
      filter(year==2014,
             substr(plot_data$category,1,3)=="NKR")  %>%
      pull(n)                                        %>%
      sum()

x <- 100*n_nkr_tx_2014/n_tx_2014
x <- round(x,1)

write(paste0(x,"% This pct sign makes a LaTeX comment"), file = paste0("./constants/c-nkr-tx-over-pke-tx-2014",suffix,".txt"))

# All years
n_tx <- 
      plot_data %>%
      pull(n)   %>%
      sum()

n_internal_tx <- 
      plot_data                                             %>%
      filter(category == "Other platforms within hospital") %>%
      pull(n)                                               %>%
      sum()

x <- n_internal_tx / n_tx
x <- 100 * x
x <- round(x)

write(x, file = "./constants/c-percentage-transplants-internal-all-years.txt")

n_nkr_tx <- 
      plot_data                                      %>%
      filter(substr(plot_data$category,1,3)=="NKR")  %>%
      pull(n)                                        %>%
      sum()

n_apd_unos_tx <- 
      plot_data                                           %>%
      filter(substr(plot_data$category,1,8)=="APD/UNOS")  %>%
      pull(n)                                             %>%
      sum()

x <- n_nkr_tx/n_apd_unos_tx
x <- floor(x)

write(paste0(x,"% This pct sign makes a LaTeX comment"), file = paste0("./constants/c-nkr-tx-over-apd-unos-tx-all-years",suffix,".txt"))
}

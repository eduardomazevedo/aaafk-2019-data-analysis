# Start
rm(list = ls())
library(dplyr)
library(magrittr)
library(broom)
library(rpart)
library(rpart.plot)
library(rattle)

setwd("~/Dropbox (Personal)/calibration2019//")

# Load data
data <- read.csv('./output/regressionTree.csv', header=TRUE) %>% tbl_df

colnames(data)[colnames(data)=="r_abo"] <- "Patient_Blood_Type"
colnames(data)[colnames(data)=="d_abo"] <- "Donor_Blood_Type"
colnames(data)[colnames(data)=="r_cpra"] <- "Patient_PRA"



# Fit regression trees
# Specification 1: only variables that the exchanges have.
fit_1_pairs <- 
  rpart(data = data %>%
          filter(category == 'p'),
        control = rpart.control(cp = 0.02),
        xval = 10,
        df ~ Patient_Blood_Type + Donor_Blood_Type + Patient_PRA)

fit_1_altruists <- 
  rpart(data = data %>%
          filter(category == 'a'),
        control = rpart.control(cp = 0.02),
        xval = 10,
        df ~ Donor_Blood_Type )

fit_1_chips <- 
  rpart(data = data %>%
          filter(category == 'c'),
        control = rpart.control(cp = 0.02),
        xval = 10,
        df ~ Patient_Blood_Type + Patient_PRA)

pdf("./output-for-manuscript/regressionTreeABOr_cpra.pdf",width=7,height=5)
par(mfrow=c(1,3)) 
node.fun2 <- function(x, labs, digits , varlen)
{
  paste(labs, "\ndev", x$frame$dev)
}
rpart.plot(fit_1_altruists,                   
           box.palette="GnBu",
           branch.lty=4, shadow.col="gray",type=4,extra = 1, 
           nn=TRUE, main="Altruists",cex.main=1) #,node.fun = node.fun2)

rpart.plot(fit_1_pairs,                   
           box.palette="GnBu",
           branch.lty=4, shadow.col="gray",type=4,extra = 1,
           nn=TRUE, main="Pairs",cex.main=1) #, node.fun = node.fun2)

rpart.plot(fit_1_chips,                   
           box.palette="GnBu",
           branch.lty=4, shadow.col="gray",type=4,extra = 1,
           nn=TRUE, main="Unpaired Patients",cex.main=1) #, node.fun = node.fun2)


#title("Regression Tree for Marginal Products with ABO and r_cpra", outer=TRUE,line = -1)
dev.off()

# Fit regression trees
# Specification 11: only variables that the exchanges have.
fit_1_pairs <- 
  rpart(data = data %>%
          filter(category == 'p'),
        #control = rpart.control(minbucket = 10),
        xval = 10,
        rewards ~ r_abo + d_abo + r_cpra)

fit_1_altruists <- 
  rpart(data = data %>%
          filter(category == 'a'),
        xval = 10,
        rewards ~ r_abo + d_abo + r_cpra)

pdf("./output-for-manuscript/regressionTreeRewards.pdf",width=7,height=5)
par(mfrow=c(1,2)) 
node.fun2 <- function(x, labs, digits , varlen)
{
  paste(labs, "\ndev", x$frame$dev)
}
rpart.plot(fit_1_altruists,                   
           box.palette="GnBu",
           branch.lty=4, shadow.col="gray",type=4,extra = 1, 
           nn=TRUE, main="Altruists",cex.main=1) #,node.fun = node.fun2)

rpart.plot(fit_1_pairs,                   
           box.palette="GnBu",
           branch.lty=4, shadow.col="gray",type=4,extra = 1,
           nn=TRUE, main="Pairs",cex.main=1) #, node.fun = node.fun2)

title("Regression Tree for Rewards with ABO and r_cpra", outer=TRUE,line = -1)
dev.off()




# Specification 2: add demand variables.
fit_2_pairs <- 
  rpart(data = data %>%
          filter(category == 'p'),
        xval = 10,
        df ~ r_abo + d_abo + r_cpra + demand_type)

fit_2_altruists <- 
  rpart(data = data %>%
          filter(category == 'a'),
        xval = 10,
        df ~ r_abo + d_abo + r_cpra)

# Specification 3: add match power.
fit_3_pairs <- 
  rpart(data = data %>%
          filter(category == 'p'),
        xval = 10,
        df ~ r_abo + d_abo + r_cpra +
          demand_type +
          dmp + rmp)

fit_3_altruists <- 
  rpart(data = data %>%
          filter(category == 'a'),
        xval = 10,
        df ~ r_abo + d_abo + r_cpra +
          dmp)


## OMERS ORIGINAL CODE

# Regression Trees
# fitall <- rpart(df ~ category + r_abo + d_abo +
#                d_age + r_age +
#                d_weight + r_weight +
#                rmp + dmp + r_cpra + 
#                demand,
#              xval= 10,
#              data=regrclass)
# 
# 
# fitaltall <- rpart(df ~  + d_abo +
#                   d_age +
#                   d_weight +
#                   dmp,
#                 xval= 10,
#                 data=altruistic)
# 
# fitalt1 <- rpart(df ~  + d_abo +
#                      d_age +
#                      d_weight,
#                    xval= 10,
#                    data=altruistic)
# 
# fitpairall <- rpart(df ~ r_abo + d_abo +
#                    d_age + r_age +
#                    d_weight + r_weight +
#                    rmp + dmp + r_cpra + 
#                    demand,
#                  xval= 10,
#                  data=pair)
# 
# fitpair1 <- rpart(df ~ r_abo + d_abo +
#                    d_age + r_age +
#                    d_weight + r_weight + r_cpra,
#                  xval= 10,
#                  data=pair)
# 
# fitpair2 <- rpart(df ~ r_abo + d_abo +
#                     d_age + r_age +
#                     d_weight + r_weight +
#                     r_cpra + 
#                     demand,
#                   xval= 10,
#                   data=pair)
# 
# # Cool graphs
# post(fitall, file = "treeall.ps", 
#      title = "Regression Tree for Marginal Products")
# 
# post(fitpairall, file = "treeallpair.ps", 
#      title = "Regression Tree for Marginal Products of Pairs")
# 
# post(fitaltall, file = "treeallalt.ps", 
#      title = "Regression Tree for Marginal Products of Altruistic Donors")
# 
# post(fitpair1, file = "treepair1.ps", 
#      title = "Regression Tree for Marginal Products of Pairs with ABO and r_cpra")
# 
# post(fitpair2, file = "treepair2.ps", 
#      title = "Regression Tree for Marginal Products of Pairs without Match Power")
# 
# post(fitalt1, file = "treeall1.ps", 
#      title = "Regression Tree for Marginal Products of Altruistic Donors without Match Power")
# 


#printcp(fit) # display the results 
#plotcp(fit) # visualize cross-validation results 
#summary(fit) # detailed summary of splits

#plot(fit, uniform=TRUE, 
#main="Regression Tree for Marginal Products")
#text(fit, use.n=TRUE, all=TRUE, cex=.8)

# For Pairs
pdf("./output-for-manuscript/regressionTreePairs.pdf",width=7,height=5)
par(mfrow=c(1,3)) 
rpart.plot(fit_1_pairs,                   
           box.palette="GnBu",
           branch.lty=3, shadow.col="gray",type=4, 
           nn=TRUE, main="Only ABO and r_cpra",cex.main=1)

rpart.plot(fit_2_pairs,                   
           box.palette="GnBu",
           branch.lty=3, shadow.col="gray",type=4, 
           nn=TRUE, main="Add Demand Type",cex.main=1)

rpart.plot(fit_3_pairs,                   
           box.palette="GnBu",
           branch.lty=3, shadow.col="gray",type=4, 
           nn=TRUE, main="Add Match Power",cex.main=1)

title("Regression Tree for Marginal Products of Pairs", outer=TRUE,line = -1)
dev.off()

# For Altruists

pdf("./output-for-manuscript/regressionTreeAltruistics.pdf",width=7,height=5)
par(mfrow=c(1,3)) 
rpart.plot(fit_1_altruists,                   
           box.palette="GnBu",
           branch.lty=3, shadow.col="gray",type=4, 
           nn=TRUE, main="Only ABO and r_cpra",cex.main=1)

rpart.plot(fit_2_altruists,                   
           box.palette="GnBu",
           branch.lty=3, shadow.col="gray",type=4, 
           nn=TRUE, main="Add Demand Type",cex.main=1)

rpart.plot(fit_3_altruists,                   
           box.palette="GnBu",
           branch.lty=3, shadow.col="gray",type=4, 
           nn=TRUE, main="Add Match Power",cex.main=1)

title("Regression Tree for Marginal Products of Altruistic Donors", outer=TRUE,line = -1)
dev.off()

# For Spec 1

pdf("./output-for-manuscript/regressionTreeABOr_cpra.pdf",width=7,height=5)
par(mfrow=c(1,2)) 
rpart.plot(fit_1_altruists,                   
           box.palette="GnBu",
           branch.lty=3, shadow.col="gray",type=4, 
           nn=TRUE, main="Altruists",cex.main=1)

rpart.plot(fit_1_pairs,                   
           box.palette="GnBu",
           branch.lty=3, shadow.col="gray",type=4, 
           nn=TRUE, main="Pairs",cex.main=1)

title("Regression Tree for Marginal Products with ABO and r_cpra", outer=TRUE,line = -1)
dev.off()

# For Spec 2

pdf("./output-for-manuscript/regressionTreeDemand.pdf",width=7,height=5)
par(mfrow=c(1,2)) 
rpart.plot(fit_2_altruists,                   
           box.palette="GnBu",
           branch.lty=3, shadow.col="gray",type=4, 
           nn=TRUE, main="Altruists",cex.main=1)

rpart.plot(fit_2_pairs,                   
           box.palette="GnBu",
           branch.lty=3, shadow.col="gray",type=4, 
           nn=TRUE, main="Pairs",cex.main=1)

title("Regression Tree for Marginal Products with ABO,r_cpra and Demand Type", cex.main=0.8,
      outer=TRUE,line = -1)
dev.off()

# For Spec 3

pdf("./output-for-manuscript/regressionTreeMatchPower.pdf",width=7,height=5)
par(mfrow=c(1,2)) 
rpart.plot(fit_3_altruists,                   
           box.palette="GnBu",
           branch.lty=3, shadow.col="gray",type=4, 
           nn=TRUE, main="Altruists",cex.main=1)

rpart.plot(fit_3_pairs,                   
           box.palette="GnBu",
           branch.lty=3, shadow.col="gray",type=4, 
           nn=TRUE, main="Pairs",cex.main=1)

title("Regression Tree for Marginal Products with ABO, r_cpra, Demand Type and Matching Power",
      cex.main=0.8,
      outer=TRUE,line = -1)
dev.off()
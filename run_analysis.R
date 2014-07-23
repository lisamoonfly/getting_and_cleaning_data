library(data.table)
#group1
dtSubjectTrain <- fread("subject_train.txt")
dtSubjectTest <- fread("subject_test.txt")
head(dtSubjectTrain)
head(dtSubjectTest)
#group2
dtActivityTrain <- fread("Y_train.txt")
dtActivityTest <- fread("Y_test.txt")
head(dtActivityTrain)
head(dtActivityTest)
#group3
dtTrain <- data.table(read.table("X_train.txt"))
dtTest <- data.table(read.table("X_test.txt"))
head(dtTrain)
head(dtTest)
#Concatenate the data tables
#group1
dtSubject <- rbind(dtSubjectTrain, dtSubjectTest)
setnames(dtSubject, "V1", "subject")
head(dtSubject)
#group2
dtActivity <- rbind(dtActivityTrain, dtActivityTest)
setnames(dtActivity, "V1", "activityNum")
head(dtActivity)
#group3
dt <- rbind(dtTrain, dtTest)
head(dt)
#merge colums
#groups 1-2
dtSubject <- cbind(dtSubject, dtActivity)
#groups 1-2-3
dt <- cbind(dtSubject, dt)
head(dt) 
#set key
setkey(dt, subject, activityNum)
##extract mean and standard deviation
#Add the "features.txt" file. 
#to tell which variables in dt are measurements for the mean and standard deviation
dtFeatures <- fread("features.txt")
setnames(dtFeatures, names(dtFeatures), c("featureNum", "featureName"))
#Subset only measurements for the mean and standard deviation
dtFeatures <- dtFeatures[grepl("mean\\(\\)|std\\(\\)", featureName)]
head(dtFeatures)
#Convert the column numbers to a vector of variable names matching columns in dt
dtFeatures$featureCode <- dtFeatures[, paste0("V", featureNum)]
head(dtFeatures)
#Subset these variables using variable names
select <- c(key(dt), dtFeatures$featureCode)
dt <- dt[, select, with = FALSE]
head(dt)
head(dtFeatures$featureCode)
## Use descriptive activities name
#Add the "activity_labels.tx" file.
dtActivityNames <- fread("activity_labels.txt")
setnames(dtActivityNames, names(dtActivityNames), c("activityNum", "activityName"))
##Label with descriptive activity names
#merge activity labels
dt <- merge(dt, dtActivityNames, by = "activityNum", all.x = TRUE)
head(dt)
#Add activityName as a key
setkey(dt, subject, activityNum, activityName)
#Melt the data table to reshape it from a short and wide format to a tall and narrow format
library(reshape2)
dt <- data.table(melt(dt, key(dt), variable.name = "featureCode"))
#merge activity name
dt <- merge(dt, dtFeatures[, list(featureNum, featureCode, featureName)], by = "featureCode", all.x = TRUE)
head(dt)
#Create a new variable, activity that is equivalent to activityName as a factor class 
dt$activity <- factor(dt$activityName)
#Create a new variable, feature that is equivalent to featureName as a factor class
dt$feature <- factor(dt$featureName)
head(dt)
#Seperate features from featureName using the helper function grepthis
grepthis <- function(regex) {
    grepl(regex, dt$feature)
}
## Features with 2 categories
n <- 2
y <- matrix(seq(1, n), nrow = n)
x <- matrix(c(grepthis("^t"), grepthis("^f")), ncol = nrow(y))
dt$featDomain <- factor(x %*% y, labels = c("Time", "Freq"))
x <- matrix(c(grepthis("Acc"), grepthis("Gyro")), ncol = nrow(y))
dt$featInstrument <- factor(x %*% y, labels = c("Accelerometer", "Gyroscope"))
x <- matrix(c(grepthis("BodyAcc"), grepthis("GravityAcc")), ncol = nrow(y))
dt$featAcceleration <- factor(x %*% y, labels = c(NA, "Body", "Gravity"))
x <- matrix(c(grepthis("mean()"), grepthis("std()")), ncol = nrow(y))
dt$featVariable <- factor(x %*% y, labels = c("Mean", "SD"))
## Features with 1 category
dt$featJerk <- factor(grepthis("Jerk"), labels = c(NA, "Jerk"))
dt$featMagnitude <- factor(grepthis("Mag"), labels = c(NA, "Magnitude"))
## Features with 3 categories
n <- 3
y <- matrix(seq(1, n), nrow = n)
x <- matrix(c(grepthis("-X"), grepthis("-Y"), grepthis("-Z")), ncol = nrow(y))
dt$featAxis <- factor(x %*% y, labels = c(NA, "X", "Y", "Z"))
head(dt)
#Check to make sure all possible combinations of feature are accounted for by 
#all possible combinations of the factor class variables.
r1 <- nrow(dt[, .N, by = c("feature")])
r2 <- nrow(dt[, .N, by = c("featDomain", "featAcceleration", "featInstrument", "featJerk", "featMagnitude", "featVariable", "featAxis")])
r1 == r2
##create a tidy data set
#Create a data set with the average of each variable for each activity and each subject
setkey(dt, subject, activity, featDomain, featAcceleration, featInstrument, featJerk, featMagnitude, featVariable, featAxis)
dtTidy <- dt[, list(count = .N, average = mean(value)), by = key(dt)]
head(dtTidy)
#export tidy data
write.table(dtTidy, "R:dtTidy.txt", quote = FALSE, sep="\t", row.names = FALSE)
























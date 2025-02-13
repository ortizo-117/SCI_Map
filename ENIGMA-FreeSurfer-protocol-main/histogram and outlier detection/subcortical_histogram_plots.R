#################################################
#################################################
#This R script generates histograms for each subcortical structure 
# Outputs 21 + 1 ICV histogram = 22 histogram plots (.png format)
#
#In addition it will output a text file with numerical summaries that will need to be uploaded to the ENIGMA website
#
#################################################
#
#  Run this script in the same directory as your LandRvolumes.csv file. All of the output will go into the same folder.
#
#  Written by Derrek Hibar for the ENIGMA Consortium (2011)
#  Updated for R 4.4.0 compatibility
#
#################################################

# Read in data file with readr for better handling of missing values
if (!require("readr")) install.packages("readr")
library(readr)

if (!require("dplyr")) install.packages("dplyr")
library(dplyr )

# Define input and output paths
input_path <- "C:/Users/kramerlab/Documents/freesurfer_SCI_extra_subjects/ENIGMA_outputs/measures/LandRvolumes.csv"
output_dir <- "C:/Users/kramerlab/Documents/freesurfer_SCI_extra_subjects/ENIGMA_outputs/measures"

# Create output directory if it doesn't exist
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# Set working directory to output location
setwd(output_dir)

# Read the data
data <- read_csv(input_path, 
                 col_types = cols(),
                 na = c("", "NA", "x", "X"))

# Check number of subjects for histogram bins
hbins <- if(nrow(data) > 200) 100 else NULL

# Get column names
cnames <- colnames(data)

# Create a file to store summary statistics
stats_file <- file.path(output_dir, "SummaryStats.txt")
file.create(stats_file)

# Loop through each structure and make plots
for(x in seq(2, length(cnames)-2, 2)) {
	badsegs=0;
	ind=which(data[,x]=="x")
	ind2=which(data[,x]=="X")
	ind3=which(is.na(data[,x]))
	index=c(ind,ind2,ind3);
	if(length(index) > 0){
		interm=as.numeric(as.vector(pull(data[-index,x])));
		badsegs=badsegs+length(index)
		cat(paste("You marked ", as.character(badsegs), " subjects as poorly segmented in the ", cnames[x], "\n", sep=''));
	}else {
		interm=as.numeric(as.vector(pull(data[,x])));
		cat(paste("None of the subjects in the ", cnames[x], " were marked as poorly segmented\n", sep=''));
	}
	
	# Check for negative values
	if(any(interm < 0, na.rm = TRUE)) {
		stop("Some volume values are negative. Please check your data and mark invalid values with 'x'.")
	}
	
	# Calculate statistics
	mu <- mean(interm, na.rm = TRUE)
	sdev <- sd(interm, na.rm = TRUE)
	n.used <- length(interm)
	stats <- c(cnames[x], badsegs, n.used, mu, sdev)
	
	# Write statistics to the output directory
	write.table(t(as.matrix(stats)), 
				file = stats_file, 
				append = TRUE, 
				quote = FALSE, 
				col.names = FALSE,
				row.names = FALSE,
				sep = "\t")
	
	# Create histogram in the output directory
	png(file.path(output_dir, paste0(cnames[x], "_hist.png")))
	hist(interm, 
		 nclass = hbins, 
		 main = cnames[x],
		 xlab = "Volume",
		 ylab = "Frequency")
	dev.off()

	struct1=interm;
	dropsubs=which(is.na(data[,x]));
	
	####################################
	
	badsegs=0;
	ind=which(data[,x+1]=="x")
	ind2=which(data[,x+1]=="X")
	ind3=which(is.na(data[,x+1]))
	index=c(ind,ind2,ind3);

	if(length(index) > 0){
		interm=as.numeric(as.vector(pull(data[-index,x+1])));
		badsegs=badsegs+length(index)
		cat(paste("You marked ", as.character(badsegs), " subject(s) as poorly segmented in the ", cnames[x+1], '\n', sep=''));
	} else {
		interm=as.numeric(as.vector(pull(data[,x+1])));
		cat(paste("None of the subjects in the ", cnames[x+1], " were marked as poorly segmented\n", sep=''));
	}
	
	#Check to make sure there are not any missing values
	miss=which(interm=="");
	if(length(miss)>0){
		stop("There were missing values detected in your LandRvolumes.csv file. Open your LandRvolumes.csv file \
		in Excel and locate any blank cells. Missing values should be marked with the letter x in the LandRvolumes.csv \
		file. \n\n");
	}

	#Check to make sure none of the values are negative
	negs=which(interm<0);
	if(length(negs)>0){
		stop("Some of your volume values are negative. This does not makes sense. Open your LandRvolumes.csv file \
		in Excel and set negative volume values and poorly segmented values to the letter x in the file.\n\n");
	}
		
	#Get the summary statistic values
	mu=mean(interm);
	sdev=sd(interm);
	n.used=length(interm);
	stats=c(cnames[x+1], badsegs, n.used, mu, sdev);
	
	write.table(t(as.matrix(stats)), file="SummaryStats.txt", append=T, quote=F, col.names=F,row.names=F,sep="\t");
	
	png(paste(cnames[x+1],"_hist.png",sep=""))
	hist(interm, nclass=hbins, main=cnames[x+1]);
	dev.off()
	
	#combine indices to drop them from the asymmetry measures
	combinedrop=unique(c(dropsubs, index));
	
	################################################
	
	#Calculate simple asymmetry measure (L-R)/(L+R)
	if(length(combinedrop)>0){
		bothfull1=data[-combinedrop,x];
		bothfull2=data[-combinedrop,(x+1)];
		bothfull=cbind(as.numeric(as.matrix(bothfull1)),as.numeric(as.matrix(bothfull2)));
	} else {
		bothfull=cbind(as.numeric(as.matrix(data[,x])),as.numeric(as.matrix(data[,x+1])));
	}
	asymm.num=bothfull[,1]-bothfull[,2];
	asymm.denom=bothfull[,1]+bothfull[,2];
	asymm=asymm.num/asymm.denom;

	#Get the average bilateral summary statistic values
	mu=mean(asymm.denom/2);
	sdev=sd(asymm.denom/2);
	n.used=length(asymm.denom/2);
	stats=c(paste("Avg_",cnames[x],"_",cnames[x+1],sep=""), length(combinedrop), n.used, mu, sdev);
	
	write.table(t(as.matrix(stats)), file="SummaryStats.txt", append=T, quote=F, col.names=F,row.names=F,sep="\t");

	#Get the asymmetry summary statistic values
	mu=mean(asymm);
	sdev=sd(asymm);
	n.used=length(asymm);
	stats=c(paste("Assym_",cnames[x],"_",cnames[x+1],sep=""), length(combinedrop), n.used, mu, sdev);
	
	write.table(t(as.matrix(stats)), file="SummaryStats.txt", append=T, quote=F, col.names=F,row.names=F,sep="\t");
	
	png(paste("Assym_",cnames[x],"_",cnames[x+1],".png",sep=""))
	hist(asymm, nclass=hbins, main=paste("Assym_",cnames[x],"_",cnames[x+1],"_hist",sep=""));
	dev.off()
}
	

################################################
	#Generate histogram plot for ICV
	badsegs=0;
	ind=which(data$ICV=="x")
	ind2=which(data$ICV=="X")
	ind3=which(is.na(data$ICV))
	index=c(ind,ind2,ind3);

	if(length(index) > 0){
		interm=as.numeric(as.vector(data$ICV[-index]));
		badsegs=badsegs+length(index)
		cat(paste("You marked ", as.character(badsegs), " subject(s) as poorly segmented in the ICV\n", sep=''));
	} else {
		interm=as.numeric(as.vector(data$ICV));
		cat(paste("None of the subjects in the ICV were marked as poorly segmented\n", sep=''));
	}
	
	#Check to make sure there are not any missing values
	miss=which(interm=="");
	if(length(miss)>0){
		stop("There were missing values detected in your LandRvolumes.csv file. Open your LandRvolumes.csv file \
		in Excel and locate any blank cells. Missing values should be marked with the letter x in the LandRvolumes.csv \
		file. \n\n");
	}
	
	#Get the summary statistic values
	mu=mean(interm);
	sdev=sd(interm);
	n.used=length(interm);
	stats=c("ICV", badsegs, n.used, mu, sdev);
	
	write.table(t(as.matrix(stats)), file="SummaryStats.txt", append=T, quote=F, col.names=F,row.names=F,sep="\t");
	print(interm)
	
	png("ICV_hist.png")
	hist(interm, nclass=hbins, main="ICV");
	dev.off()
	
##############################################
#Output an R data file to store the plot data
save.image(file = file.path(output_dir, "ENIGMA_Plots.RData"))

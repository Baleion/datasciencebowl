###libraries
library(imager)
library(magrittr)
library(oro.dicom)
library(oro.nifti)
library(readr)


patient_dir_list <- dir(getwd())
sprintf("Number of patients: %d",length(patients))



#Call each patient one at a time and convert their corresponding images, plot, and remove artifacts
build_dataframe<- function(patient_dir_list, path_of_csv, size_x = 64, size_y = 64, num_slices = 100, plots = FALSE, stop_on_one = FALSE){
  
  #Declare empty dataframe
  full_data <- data.frame()
  
  ###Utility subfuction for transformation of image
  
  transform_image <- function(image,rescale_int,rescale_slope){
    image <- replace(image,image == -2000,0)
    if (rescale_slope != 1) {
      image = as.integer(rescale_slope * image)
    }
    image <- image + rescale_int
    
    return(image)
  }

  #Get an idea of the progress
  n_times <- length(patient_dir_list)
  
  for(patient in patient_dir_list){
  
  p <- readDICOM(patient)
  #Get header values for ID, intercept, and slope
  rescale_int <- extractHeader(p$hdr[1],'RescaleIntercept', numeric = TRUE)
  rescale_slope <- extractHeader(p$hdr[1],'RescaleSlope', numeric = TRUE)
  pt_id <- extractHeader(p$hdr[1],'PatientID', numeric = FALSE)
  

  #Combine slices into a 3d array
  slice2three <- create3D(p, pixelData = TRUE) 
  cmg <- as.cimg(slice2three)
  
  if(plots)
    {
  plot(cmg) #Uncomment for sanity Check
  hist(cmg)
  }
  
  #Convert pixel intensity to hu
  to_Hu <- transform_image(cmg, rescale_int = rescale_int, rescale_slope = rescale_slope)  
  #Cleaning
  rm(slice2three)
  rm(cmg)
  rm(p)
  
  resized <- imager::resize(to_Hu, size_x = size_x, size_y = size_y, size_z = num_slices)
  to_array <- drop(as.array(resized))
  transformed <- as.vector(t(as.matrix(to_array)))
  transformed <- list(patientID = c(pt_id), transformed)
  
  rm(to_array)
  rm(resized)
  rm(to_Hu)
  #Here is where the magic happens, build a dataframe!
  full_data <- rbind(full_data, unlist(transformed),stringsAsFactors = FALSE)
  rm(transformed)
  
  #Be able to exit the loop to make sure everything is going well
  if(stop_on_one){
    View(full_data)
    stop("Stop initiated on first iteration")}
  
  pt_left <- n_times-1
  sprintf("Iterations to go %d",pt_left)
  
  }
  #Write the df to csv
  colnames(full_data)<-'PatientID'
  
  tryCatch(
  write_csv(full_data,path = path_of_csv),
  error = function(c){
    save(full_data)
  }
  )
  }

build_dataframe(patient_dir_list, path = 'E:/DSB/sample_patients1.csv')

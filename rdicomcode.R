  ###Author: Alex Wohletz
  ###datasciencebowl preprocr
  ###libraries
  library(imager)
  library(magrittr)
  library(oro.dicom)
  library(oro.nifti)
  library(readr)
  
  
  patient_dir_list <- dir(getwd())
  
  stage1_labels <- read.csv("E:/DSB/stage1_labels.csv/stage1_labels") #Change path to match
  
  
  #Call each patient one at a time and convert their corresponding images, plot, and remove artifacts
  build_dataframe<- function(patient_dir_list, path_of_csv, label_df,size_x = 64, size_y = 64, num_slices = 100,...){
    
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
    pt_done <- 0
    print(paste('The number of patients is: ', n_times))
    
    
    for(patient in patient_dir_list){
    
    p <- readDICOM(patient)
    #Get header values for ID, intercept, and slope
    rescale_int <- extractHeader(p$hdr[1],'RescaleIntercept', numeric = TRUE)
    rescale_slope <- extractHeader(p$hdr[1],'RescaleSlope', numeric = TRUE)
    pt_id <- extractHeader(p$hdr[1],'PatientID', numeric = FALSE)
    slices_pt <- extractHeader(p$hdr[1],'GroupLength', numeric = TRUE)
    
    if(slices_pt < num_slices){
      warning("Slices mismatched")
      next
    }
  
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
    
    resized <- tryCatch(imager::resize(to_Hu, size_x = size_x, size_y = size_y, size_z = num_slices),
                        error = function(e){
                          print(conditionMessage(e))
                          resized <- array(dim = c(size_x, size_y,size_y))
                        })
    to_array <- drop(as.array(resized))
    transformed <- as.vector(t(as.matrix(to_array)))
    transformed <- list(PatientID = c(pt_id), transformed)
    
    rm(to_array)
    rm(resized)
    rm(to_Hu)

    #Here is where the magic happens, build a dataframe!
    full_data <- rbind(full_data, unlist(transformed))
    rm(transformed)
    
    #Be able to exit the loop to make sure everything is going well
    if(stop_on_one){
      colnames(full_data)<-c('PatientID')
      View(full_data)
      full_data <- merge(full_data,label_df, by.x = 'PatientID', by.y = 'PatientID', all.x = TRUE)
      return(full_data)
      stop("Stop initiated on first iteration")}
    
    #Progress indicator
    
    pt_done <- pt_done + 1
    left <- n_times - pt_done
    print(paste("Iterations to go:",left, "Patient Id:",pt_id))
    }
    
    #Merge dataframes
    tryCatch(
    colnames(full_data)<-c('PatientID'),
    full_data <- merge(full_data,label_df, by.x = 'PatientID', by.y = 'PatientID', all.x = TRUE),
    error = function(c){
    print(conditionMessage(c))
    return(full_data)
      })
    
    #Write to csv
    tryCatch(
      
    write_csv(full_data,path = path_of_csv),
    error = function(c){
    return(full_data)
    }
    )
    return(full_data)
    }
  
  df<- build_dataframe(patient_dir_list, path_of_csv ='E:/DSB/stage1_patients.csv', size_x = 32, size_y = 32, num_slices = 30,stop_on_one = FALSE, label_df = stage1_labels)

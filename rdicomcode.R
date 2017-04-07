  ###Author: Alex Wohletz
  ###datasciencebowl preprocr
  ###libraries
  library(imager)
  library(magrittr)
  library(oro.dicom)
  library(oro.nifti)
  library(readr)
  library(BiocGenerics)
  library(EBImage)
  
  patient_dir_list <- dir(getwd())
  
  stage1_labels <- read.csv("E:/DSB/stage1_labels.csv/stage1_labels.csv") #Change path to match
  
  
  #Call each patient one at a time and convert their corresponding images, plot, and remove artifacts
  build_dataframe<- function(patient_dir_list, path_of_csv, label_df,size_x = 64, size_y = 64, num_slices = 100,plots = FALSE, n_iterations = length(patient_dir_list)){
    
    #Declare empty vectors for storying the output
    pixel_array <- array(dim = c(length(patient_dir_list),(size_x*size_y*num_slices)))
    patient_ids <- array(dim = c(length(patient_dir_list),1))
    
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

    
    ##################BEGIN LOOP###############    
    
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
    
    #Resize the original 3d image into a much smaller format for covnet
    resized <- tryCatch(imager::resize(to_Hu, size_x = size_x, size_y = size_y, size_z = num_slices),
                        error = function(e){
                          print(conditionMessage(e))
                          resized <- array(dim = c(size_x, size_y,size_y))
                        })
    #Flatten the pixel array into a single vector
    to_array <- drop(as.array(resized))
    transformed <- as.vector(t(as.matrix(to_array)))
    
    #Append the flattened vector to the pixel array
    pixel_array[pt_done+1,] <- transformed
    patient_ids[pt_done+1,] <- pt_id
    
    #Cleaning
    rm(to_array)
    rm(resized)
    rm(to_Hu)
    rm(transformed)
  

    #Progress indicator
    pt_done <- pt_done + 1
    left <- n_times - pt_done
    print(paste("Iterations to go:",left, "Patient Id:",pt_id))
    
    #Be able to exit the loop to make sure everything is going well
    if(n_iterations == pt_done){
      full_data <- cbind.data.frame(patient_ids,pixel_array)
      colnames(label_df) <-c('PatientID','cancer')
      colnames(full_data)<-colnames<-c('PatientID',paste('Pixel',1:(size_x*size_y*num_slices)))
      full_data <- merge(full_data,label_df, by.x = 'PatientID', by.y = 'PatientID', all.x = TRUE)
      View(full_data)
      return(full_data)
      stop("Stop initiated on first iteration")}
    
    
    }
    
    
                                         ############END OF LOOP##############
    
    #Merge dataframes
    tryCatch(
    full_data <- cbind.data.frame(patient_ids,pixel_array),
    colnames(label_df) <-c('PatientID','cancer'),
    colnames(full_data)<-colnames<-c('PatientID',paste('Pixel',1:(size_x*size_y*num_slices))),
    full_data <- merge(full_data,label_df, by.x = 'PatientID', by.y = 'PatientID', all.x = TRUE),
    write_csv(full_data,path = path_of_csv),
    save(full_data, file = 'full_data.rda'),
    return(full_data),
    
    error = function(c){
    
    View(full_data)  
    print(conditionMessage(c))
    return(full_data)
    
      })                       
    
    }
  
  
#CHECK THE FUNCTION CALL TO VERIFY IT iS CORRECT  
  df<-list()
  df<- build_dataframe(patient_dir_list, path_of_csv ='E:/DSB/sampe_patients_test1.csv', size_x = 50, size_y = 50, num_slices = 40, label_df = stage1_labels, n_iterations = 1)

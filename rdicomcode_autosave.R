  ###Author: Alex Wohletz
  ###datasciencebowl preprocr
  ###libraries
  library(imager)
  library(oro.dicom)
  library(readr)

  
  patient_dir_list <- dir(getwd())
  
  stage1_labels <- read.csv("E:/DSB/stage1_labels.csv/stage1_labels.csv") #Change path to match
  
  
  #Call each patient one at a time and convert their corresponding images, plot, and remove artifacts
  build_dataframe<- function(patient_dir_list, path_of_csv, label_df,size_x = 64, size_y = 64, num_slices = 50,plots = FALSE, n_iterations = NULL){
    
    #Declare some variables
    SAVE_POINT <- 100 #This variable will increment
   
    pixel_array <- array(dim = c(length(patient_dir_list[1:SAVE_POINT]),(size_x*size_y*num_slices)))
    patient_ids <- array(dim = c(length(patient_dir_list[1:SAVE_POINT]),1))
    chunk <- 0
    index_save <- 0
    end_list <- which(patient_dir_list == tail(patient_dir_list, n = 1))

    
    ###Utility subfuction for transformation of image
    
    transform_image <- function(image,rescale_int,rescale_slope){
      image <- replace(image,image == -2000,0)
      if (rescale_slope != 1) {
        image = rescale_slope * image
      }
      image <- image + rescale_int
      image <- EBImage::normalize(image, separate=TRUE, ft=c(0,1), inputRange = c(-1000,400))#Not working yet
      return(image)
    }
    
    ###Function to construct the full data frame
    
    combine <- function(patient_ids,pixel_array,label_df){
    combined <- cbind.data.frame(patient_ids,pixel_array)
    colnames(label_df) <-c('PatientID','cancer')
    colnames(combined)<-colnames<-c('PatientID',paste('Pixel',1:(size_x*size_y*num_slices)))
    merged <- merge(combined,label_df, by.x = 'PatientID', by.y = 'PatientID', all.x = TRUE)
    return(merged)
    
    }
  
    
    #Get an idea of the progress
    n_times <- length(patient_dir_list)
    pt_done <- 0
    print(paste('The number of patients is: ', n_times))
    

    
    ##################BEGIN LOOP###############    
    
    for(patient in patient_dir_list){
    
    SAVE_SIZE <- 100 #This variable will not increment.
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
    slice2three <- create3D(p) 
    cmg <- imager::as.cimg(slice2three)
    rm(slice2three)
    rm(p)
    
    if(plots)
      {
    plot(cmg) #Uncomment for sanity Check
    hist(cmg)
    }
    
    #Resize the original 3d image into a much smaller format for covnet
    resized <- tryCatch(imager::resize(cmg, size_x = size_x, size_y = size_y, size_z = num_slices),
                        error = function(e){
                          print(conditionMessage(e))
                          resized <- array(NA,dim = c(size_x*size_y*num_slices))
                        })
    rm(cmg)
    
    #Flatten the pixel array into a single vector
    to_array <- drop(as.array(resized))
    #Convert pixel intensity to hu
    to_Hu <- transform_image(to_array, rescale_int = rescale_int, rescale_slope = rescale_slope)
    
    #Cleaning
    rm(to_array)
    
    transformed <- as.vector(t(as.matrix(to_Hu)))
    
    #Append the flattened vector to the pixel array
    pixel_array[pt_done+1,] <- transformed
    patient_ids[pt_done+1,] <- pt_id
    
    #Cleaning
    rm(to_Hu)
    rm(transformed)
  

    #Progress indicator
    pt_done <- pt_done + 1
    left <- n_times - pt_done
    print(paste("Iterations to go:",left, "Patient Id:",pt_id))
    
    
    ####SAVE POINT#############
    if(pt_done == SAVE_POINT){
      full_data <- combine(patient_ids,pixel_array,label_df)
      index_save <- index_save + 1
      #Save the current data and retain the file name for easy look up
      file_name <- paste('save_',index_save,".rda", sep = "")
      save(full_data, file = file_name)

      print('Saved data successfully')
      
      SAVE_POINT <-SAVE_POINT+SAVE_POINT
      
      rm(pixel_array)
      rm(file_name)
      rm(full_data)
      
      if(SAVE_SIZE > length(pt_done:end_list)){
        pixel_array <- array(dim = c(length(patient_dir_list[pt_done:end_of_list]),(size_x*size_y*num_slices)))
        patient_ids <- array(dim = c(length(patient_dir_list[pt_done:end_of_list]),1))
      }
      else{
      pixel_array <- array(dim = c(length(patient_dir_list[pt_done:SAVE_POINT]),(size_x*size_y*num_slices)))
      patient_ids <- array(dim = c(length(patient_dir_list[pt_done:SAVE_POINT]),1))
      }
    }
    
    
    #Be able to exit the loop to make sure everything is going well
    
    if(!is.null(n_iterations)){
      
      if(n_iterations == pt_done){
      full_data <- combine(patient_ids,pixel_array,label_df)
      #View and save the current data.
      View(full_data)
      chunk <- chunk + 1
      file_name = paste('chunk_',chunk,".rda", sep = "")
      save(full_data, file = file_name)
      return(full_data)
      }
      }
    
    }
    
    
                                         ############END OF LOOP##############
    
    
    #Write the csv and save the data
  
    full_data <- combine(patient_ids,pixel_array,label_df)
    save(full_data, file = 'full_data.rda')
    write_csv(full_data,path = path_of_csv)
    return(full_data)
                        
    
    }
  
  
#CHECK THE FUNCTION CALL TO VERIFY IT iS CORRECT  

  df<- build_dataframe(patient_dir_list[400:1595], path_of_csv ='E:/DSB/stage1_patients_complete.csv', label_df = stage1_labels)

  
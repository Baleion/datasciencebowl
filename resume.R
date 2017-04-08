merge_save_points <- function(new_rda, old_rda){
  
  old<-load(old_rda)
  new<- load(new_rda)
  final<-rbind.data.frame(old,new)
  return(final)
}


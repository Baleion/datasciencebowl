# -*- coding: utf-8 -*-
"""
Created on Thu Mar 30 23:27:02 2017

@author: Alex
"""


import os
import dicom
import pandas as pd
import matplotlib.pyplot as plt
import cv2
import numpy as np
import math


IMG_PX_SIZE = 150
HM_SLICES = 20

#Chunks yields a list of chunks of length n
def chunks( l,n ):
    count=0
    for i in range(0, len(l), n):
        if(count < HM_SLICES):
            yield l[i:i + n]
            count=count+1
#Mean function to average the chunks
def mean(l):
    return sum(l)/len(l)



def process_data(patient,labels_df, img_px_size = 50, hm_slices = 20, visualize = False): #Grab first patient in list of patients
        
        label = labels_df.get_value(patient,'cancer') #Get the value at the first index of the column cancer
        path = data_dir + patient #splice together the path of the sample images plus the current image
        slices = [dicom.read_file(path + '/' +s) for s in os.listdir(path)] #Grab slice and read it into dicom pkg
        slices.sort(key = lambda x: int(x.ImagePositionPatient[2]))
    
    #Resizing the 3rd dimension of the image, the number of slices
        new_slices = []
        slices = [cv2.resize(np.array(each_slice.pixel_array),(IMG_PX_SIZE, IMG_PX_SIZE)) for each_slice in slices]
        chunk_sizes = math.floor(len(slices)/HM_SLICES)
    
        for slice_chunk in chunks(slices, chunk_sizes):
              slice_chunk = list(map(mean, zip(*slice_chunk)))
              new_slices.append(slice_chunk)
    #Not sure if the logic statements are still necessary
 
        if len(new_slices) == HM_SLICES-1:
            new_slices.append(new_slices[-1])

        if len(new_slices) == HM_SLICES-2:
            new_slices.append(new_slices[-1])
            new_slices.append(new_slices[-1])

        if len(new_slices) == HM_SLICES+2:
            new_val = list(map(mean, zip(*[new_slices[HM_SLICES-1],new_slices[HM_SLICES],])))
            del new_slices[HM_SLICES]
            new_slices[HM_SLICES-1] = new_val

        if len(new_slices) == HM_SLICES+1:
            new_val = list(map(mean, zip(*[new_slices[HM_SLICES-1],new_slices[HM_SLICES],])))
            del new_slices[HM_SLICES]
            new_slices[HM_SLICES-1] = new_val
                    
        print(len(slices), len(new_slices))
     #Visualize the slices   
        if visualize:  
            fig = plt.figure()  
            for num, each_slice in enumerate(slices[:12]):
                y = fig.add_subplot(3,4, num+1)
                new_image = cv2.resize(np.array(each_slice.pixel_array),(IMG_PX_SIZE, IMG_PX_SIZE))
                y.imshow(new_image)
                plt.show()
    #One hot encoding of the labels
        if label == 1: 
            label = np.array([0,1])
            
        elif label == 0: 
            label = np.array([1,0])
        
        return np.array(new_slices),label

#Declare an empty list for the processed data        
much_data = []

data_dir = "E:\\DSB\\sample_images\\"
patients = os.listdir(data_dir)
path = "E:\\DSB\\stage1_labels.csv\\stage1_labels.csv"
labels_df = pd.read_csv(path, index_col = 0)
    
    
for num, patient in enumerate(patients):
    if num%100==0:
        print(num)
    try:
        img_data, label = process_data(patient, labels_df, img_px_size = IMG_PX_SIZE, hm_slices = HM_SLICES)
        much_data.append([img_data, label])
    except KeyError as e:
           print('This is unlabled data')
           
np.save('muchdata--{}--{}--{}--.npy'.format(IMG_PX_SIZE, IMG_PX_SIZE, HM_SLICES),much_data)
           


# -*- coding: utf-8 -*-
"""
Created on Wed Apr 19 17:18:25 2017

@author: Raymond Taylor
"""

import matplotlib.pyplot as plt
import numpy as np
from keras.utils.np_utils import to_categorical
from keras.models import Sequential
from keras.layers import Dense, Dropout, Activation, Flatten
from keras.layers import Conv2D, MaxPooling2D, Conv3D, MaxPooling3D
from keras.utils import np_utils
from keras import backend as K
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.preprocessing import StandardScaler
from sklearn import preprocessing




#chunksize = 10 ** 6
#csv_chunks = pd.read_csv("E:/DSB/stage1_patients_complete_NA_removed.csv", chunksize = chunksize)
#df = pd.concat(chunk for chunk in csv_chunks)

df = pd.read_csv("D:/Spyder/stage1_patients_complete.csv")
#stage1_labels =  pd.read_csv("E:/DSB/stage1_labels.csv")
stage2 = pd.read_csv("E:/DSB/stage2_patients.csv")
#df = pd.read_csv("E:/DSB/stage1_patients.csv")
df.dropna(how = 'any' ,inplace = True)
df.shape[1]
PatID = df.pop('PatientID')
cancer = df.pop('cancer')
X = preprocessing.MinMaxScaler().fit(df).transform(df)
X = StandardScaler().fit(df).transform(df)
X = np.reshape(X, [-1, 32, 32, 50, 1])
#X = np.reshape(X, [-1, 32, 32, 40, 1])

cancer = LabelEncoder().fit(cancer).transform(cancer)
cancer_cat = to_categorical(cancer)

#stage1_ID = stage1_labels.pop('id')
#stage1_labels =  preprocessing.MinMaxScaler().fit(stage1_labels).transform(stage1_labels)
#stage1_labels = StandardScaler().fit(stage1_labels).transform(stage1_labels)
#stage1_labels = np.reshape(X, [-1, 32, 32, 50, 1])

stage2.dropna(how='any', inplace = True)
stage2_ID = stage2.pop('PatientID')
stage2 =  preprocessing.MinMaxScaler().fit(stage2).transform(stage2)
stage2 = StandardScaler().fit(stage2).transform(stage2)
stage2 = np.reshape(X, [-1, 32, 32, 50, 1])

#X_train, X_test, y_train, y_test = train_test_split(X, cancer_cat, test_size=0.10, random_state=42)


'''
Creates a keras model with 3D CNNs and returns the model.
'''
pool_size = (2,2,2)
kernel_size = (2,2,2)
input_shape = (32,32,50,1)
#input_shape = (64,64,100,1)

model = Sequential()

model.add(Conv3D(16, kernel_size, padding='valid',input_shape=input_shape))
model.add(Activation('relu'))
model.add(MaxPooling3D(pool_size=pool_size))
model.add(Conv3D(32, kernel_size))
model.add(Activation('relu'))
model.add(MaxPooling3D(pool_size=pool_size))
model.add(Conv3D(64, kernel_size))
model.add(Activation('relu'))
model.add(MaxPooling3D(pool_size=pool_size))
model.add(Dropout(0.25))
model.add(Flatten())
model.add(Dense(512))
model.add(Activation('relu'))
model.add(Dropout(0.5))
model.add(Dense(128))
model.add(Activation('relu'))
model.add(Dropout(0.5))
model.add(Dense(2))
model.add(Activation('softmax'))
model.compile(loss='categorical_crossentropy', optimizer='adadelta', metrics=['accuracy'])

history = model.fit(X, cancer_cat,batch_size=64,epochs=120 ,verbose=1,validation_split=0.1)
yPred = model.predict(stage2)

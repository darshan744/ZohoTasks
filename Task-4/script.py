#!/usr/bin/env python3

import subprocess as sp
import os
from collections import Counter
reportFile="report.txt"
statFile="stat.txt"

class DataRecord:
    overhead:float
    command : str
    sharedObject:str
    symbol : str
    space : str
    def __init__(self , overhead:float , command:str , sharedObject:str , symbol:str , space:str):
        self.overhead = overhead
        self.command = command
        self.sharedObject = sharedObject
        self.symbol = symbol
        if space == '[.]':
            self.space = 'user-space'
        else:
            self.space = 'kernel-space'
    def __str__(self) -> str:
        return f"Overhead : {self.overhead} , Command : {self.command} , SharedObject : {self.sharedObject} , Symbol : {self.symbol}"

dataRecords : list[DataRecord] = []


def parseReportFile():
    with open(reportFile) as file:
        for line in file:
            # starting lines are skipped
            if line.startswith('#') or line.startswith('\n'):
                continue
            # remove trailing spaces 
            line = line.strip()
            # split it to get overhead , command , sharedobject and symbol
            l = line.split(None , 3)
            # some new lines are there hence skipped
            if len(l) == 0:
                continue
            # replace percentage to make it float
            l[0] = l[0].replace('%' , '')
            if len(l) > 3:
                # in symbol `[.]` is replaced by splitting and the new line at last is removed 
                symbolSplit = l[3].split(None , 1)
                l[3] = symbolSplit[1].replace('\n','')
                l.append(symbolSplit[0])
            # creating a dataobject for storing
            record = DataRecord(overhead=float(l[0]), command=l[1] , sharedObject=l[2] ,symbol=l[3] ,space=l[4])
            dataRecords.append(record)
            
parseReportFile()
print("The hottest function is : " , dataRecords[0].symbol)    
counter = Counter()
def maximumRanFunction():
    for record in dataRecords:
        counter[record.symbol]+=1
    # most_common(1) lists the passed number of keys to give back
    # we need the most common one hence only one so we pass one
    print("Most common Function that was executed is : " , counter.most_common(1))

# most called function findings
maximumRanFunction()

# find the specifc time with time elapsed
# Split the time 
# the first part is the total seconds ran by the program
def findTotalTimeRan():
    with open(statFile) as file:
        for line in file:
            if not line.__contains__('time elapsed'):
                continue
            splits = line.strip().split(None)
            return float(splits[0])
        return 0

totalTimeRan = findTotalTimeRan()

topHotspotFunctions = dataRecords[0:3]

def calculateHotFunctionTimings():
    for record in topHotspotFunctions:
        currentRecordRanTime = (totalTimeRan * record.overhead) / 100
        currentRecordRanTime = currentRecordRanTime * 1000
        print(f"The function {record.symbol} ran for total of {currentRecordRanTime} ms.")

calculateHotFunctionTimings()

def findTimeSpentOnEachSpace():
    length = len(dataRecords)
    userSpaceCount = 0
    kernelSpaceCount = 0
    for record in dataRecords:
        if record.space == "user-space":
            userSpaceCount += 1
        else:
            kernelSpaceCount += 1
    userSpacePercentage = userSpaceCount / length * 100
    kernelSpacePercentage = kernelSpaceCount / length * 100

    print("User space time spent percentage : " , userSpacePercentage , " %")

    print("Kernel space time spent percentage : " , kernelSpacePercentage , " %")

findTimeSpentOnEachSpace()
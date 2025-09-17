#!/usr/bin/env python3

import sys
import subprocess as sp
import os
from collections import Counter

duckDb="/home/darshan-pt7976/dev/ZohoTasks/Task-4/duckdb/build/release/duckdb"
databaseFile = "/home/darshan-pt7976/dev/ZohoTasks/Task-4/test.db"
recordFile="/home/darshan-pt7976/dev/ZohoTasks/Task-4/perf.data"
reportFile="/home/darshan-pt7976/dev/ZohoTasks/Task-4/report.txt"
statFile="/home/darshan-pt7976/dev/ZohoTasks/Task-4/stat.txt"

queryNumber = 1
if len(sys.argv) > 1:
    qn = int(sys.argv[1])
    if qn > 22:
        print("Please enter a valid query number between 1 and 22")
        exit(1)
    queryNumber = qn
else:
    print("Please pass the query number to be executed")
    exit(1)


print(f"[INFO] Running query specified {queryNumber}")

def runQuery():
    try:
        command = f'sudo perf stat -o {statFile} {duckDb} {databaseFile} -c \'pragma tpch({queryNumber})\''
        print(f'[INFO] Running command {command}')
        sp.run(command, shell=True , check=True ,capture_output=True)
        print(f'[INFO] stat command ran successfully')
    except sp.CalledProcessError as e:
        print("[ERROR] stat Comand failed : " , e.stderr)

    try:
        command = f'sudo perf record -o {recordFile} {duckDb} {databaseFile} -c \'pragma tpch({queryNumber})\''
        print(f'[INFO] Running command {command}')
        sp.run(command, shell=True , check=True ,capture_output=True)
        print(f'[INFO] record command ran successfully')
    except sp.CalledProcessError as e:
        print("[ERROR] Record Comand failed : " , e.stderr)
    try:
        command = f'sudo perf report --stdio > {reportFile}'
        print(f'[INFO] Running command {command}')
        sp.run(command, shell=True , check=True ,capture_output=True)
        print('[INFO] Report command ran successfully')
    except sp.CalledProcessError as e:
        print(f"[ERROR] --stdio failed {e.stderr}")
        exit(1)


runQuery()

print('[SUCCESS] Queries ran successfully')
print('[INFO] Running analysis on the reports generated')

########################################
#      Parsing and statistics          #
########################################

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

print('[INFO] Ran to check total time spent by top 3 functions')

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
#!/usr/bin/env python3

import subprocess as sp
from collections import Counter
import json

duckDb="/home/darshan-pt7976/dev/ZohoTasks/Task-4/duckdb/build/release/duckdb"
databaseFile = "/home/darshan-pt7976/dev/ZohoTasks/Task-4/test.db"
recordFile="/home/darshan-pt7976/dev/ZohoTasks/Task-4/perf.data"
reportFile="/home/darshan-pt7976/dev/ZohoTasks/Task-4/report.txt"
statFile="/home/darshan-pt7976/dev/ZohoTasks/Task-4/stat.txt"

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

# stats dict
jsonData = {}
dataRecords : list[DataRecord] = []

allStats = []

overallStats = {}


def runQuery(queryNumber : int):
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

def getFunctionName(s : str):
    index = s.rfind('(')
    if index != -1:
        without_args = s[:index]
    else:
        without_args = s

    return without_args

def parseReportFile():
    dataRecords : list[DataRecord] = []
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
                # these symbol tells us what space they are running 
                # [.] -> user space
                # [k] -> kernel space 
                symbolSplit = l[3].split(None , 1)
                l[3] = symbolSplit[1].replace('\n','')
                l.append(symbolSplit[0])
            # creating a dataobject for storing
            # key = l[3]
            l[3] = getFunctionName(l[3])
            # value = l[3]
            # dummyData[key] = value
            record = DataRecord(overhead=float(l[0]), command=l[1] , sharedObject=l[2] ,symbol=l[3] ,space=l[4])
            dataRecords.append(record)
    return dataRecords
             
def mostCalledFunction():
    counter = Counter()
    for record in dataRecords:
        counter[record.symbol]+=1
    # most_common(1) gives us back the a list of tuples and 1 means it gives us only the first one
    # we need the most common one hence only one so we pass one
    # we get a tuple inside a list 
    # [('func name' , repetition_times)]
    jsonData['common_function'] = {'name' : counter.most_common(1)[0][0] , 'count' : counter.most_common(1)[0][1]}

def parseTaskClockLine(line : str):
    splits = line.strip().split(None)
    if len(splits) > 0:
        jsonData['cummulative_time_spen_in_ms'] = splits[0]
    if len(splits) > 4:
        jsonData['avg_cpu_cores_used'] = splits[4]

def parseInsnPerCycle(line:str):
    splits = line.strip().split(None)
    if len(splits) > 3:
        jsonData['instruction_per_cycle'] = splits[3]
        # print(splits)
        print(jsonData)

def calculateUserSpaceTimeSpent(line : str , space : str):
    splits = line.strip().split(None)
    jsonData[f'{space}_space_time_spent_in_ms'] = float(splits[0]) * 1000

def calculateBranchMisses(line : str):
   splits = line.strip().split()
   jsonData['total_branch_misses'] = {'count' : splits[0] , 'percent' : splits[3]}

def totalBranches(line : str):
    splits = line.strip().split()
    jsonData['total_number_of_branches'] = splits[0]

def genCpuStats():
    with open(statFile , 'r') as file:
        for line in file:
            if line.__contains__('task-clock'):
                parseTaskClockLine(line)
            elif line.__contains__('insn per cycle'):
                parseInsnPerCycle(line)
            elif line.__contains__('user'):
                calculateUserSpaceTimeSpent(line , 'user')
            elif line.__contains__('sys'):
                calculateUserSpaceTimeSpent(line , 'kernel')
            elif line.__contains__('branch-misses'):
                calculateBranchMisses(line)
            elif line.__contains__('branches'):
                totalBranches(line)

# find the specifc time with time elapsed
# Split the time 
# the first part is the total seconds ran by the program
def findTotalTimeRan():
    with open(statFile) as file:
        for line in file:
            if not line.__contains__('time elapsed'):
                continue
            splits = line.strip().split(None)
            jsonData['total_time_ran_in_ms'] = float(splits[0])* 1000
            return float(splits[0])
        return 0

def calculateMostCalledFunctionsTimings(totalTimeRan : float, topFunctions : list[DataRecord]):
    hotFunctions = []
    for record in topFunctions:
        currentRecordRanTime = (totalTimeRan * record.overhead) / 100
        currentRecordRanTime = currentRecordRanTime * 1000
        hotFunctions.append({ 'name' : record.symbol , 'time' : currentRecordRanTime })
    jsonData['top_functions_timings'] = hotFunctions

# user and kernel space timing calculation
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

    jsonData['user_space_time_spent_percentage'] = f'{userSpacePercentage}%'
    jsonData['kernel_space_time_spent_percentage'] = f'{kernelSpacePercentage}%'

def writeOutput(queryNumber : int):
    fileName = f'stats_{queryNumber}.json'
    with open(f'stats_{queryNumber}.json' , 'w') as file:
        json.dump(jsonData , file , indent=4)
    return fileName

def runScript():
    global dataRecords
    global jsonData
    for i in range(1 , 23):
        jsonData = {} 
        jsonData['queryNumber'] = i
        print(f"[INFO] Running query for {i}")
        runQuery(i)
        print('[SUCCESS] Queries ran successfully')
        print('[INFO] Running analysis on the reports generated')

        dataRecords = parseReportFile()
        jsonData['overhead_function'] = dataRecords[0].symbol
        genCpuStats()
        mostCalledFunction()
        calculateMostCalledFunctionsTimings(findTotalTimeRan() , dataRecords[0:3])
        fileName = writeOutput(i)
        print(f'[SUCCESS] Analysis done for query number : {i} stats written to file {fileName}')
        allStats.append(jsonData)

    print('[SUCCESS] Analysis on the queries have been sucessfully completed')

def overAllMostCommonFunction():
    counter = Counter()
    
    for stat in allStats:
        commonFunc = stat['common_function']
        counter[commonFunc['name']] += 1
    commonFunc = counter.most_common(1)[0][0]
    
    overallStats['most_common_function'] = { 'name' : counter.most_common(1)[0][0] , 'count' : counter.most_common(1)[0][1]}

def mostTimeSpentFunction():
    time = 0
    maxFun = ''
    queryNumber = 0
    for stat in allStats:
        for topFunc in stat['top_functions_timings']:
            if topFunc['time'] > time:
                time = topFunc['time']
                maxFun = topFunc['name']
                queryNumber = stat['queryNumber']
    overallStats['max_execution_time_function'] = {'name' : maxFun , 'time' : time , 'queryNumber' : queryNumber}

def mostSpaceSpentQuery():
    userSpace = 0
    kernelSpace = 0
    userSpaceQuery = 1
    kernelSpaceQuery = 1
    index = 1
    for stat in allStats:
        # This gives us with the total time spent on each
        # space across all cores meaning that 
        # It gives us the time spent if the code is executed
        # on a single thread/process and not parellel
        # Hence we get time above the overall time spent
        userSpaceStat = stat['user_space_time_spent_in_ms']
        kernelSpaceStat = stat['kernel_space_time_spent_in_ms']
        if userSpace < userSpaceStat:
            userSpaceQuery = index
            userSpace = userSpaceStat
        if kernelSpace < kernelSpaceStat:
            kernelSpaceQuery = index
            kernelSpace = kernelSpaceStat
        index += 1
    
    overallStats['most_user_space'] = { 'queryNumber' : userSpaceQuery , 'time_spent_in_ms' : userSpace}
    # print(f'Userspace most spent query is {userSpaceQuery} : {userSpace}%')
    overallStats['most_kernel_space'] = { 'queryNumber' : kernelSpaceQuery , 'time_spent_in_ms' : kernelSpace}
    # print(f'Userspace most spent query is {kernelSpaceQuery} : {kernelSpace}%')

def totalTimeRanCalculation():
    min = float('inf')
    maxQuery = 1
    max = float('-inf')
    minQuery = 1

    for i in range(len(allStats)):
        allStats[i]
        print()

    for i in range(len(allStats)):
       if max < allStats[i]['total_time_ran_in_ms']:
           maxQuery = allStats[i]['queryNumber']
           max = allStats[i]['total_time_ran_in_ms']
       if min > allStats[i]['total_time_ran_in_ms']:
           minQuery = allStats[i]['queryNumber']
           min = allStats[i]['total_time_ran_in_ms']
    
    overallStats['max_time_spent_query_number'] = {'queryNumber' : maxQuery , 'time' : max}
    overallStats['min_time_spent_query_number'] = {'queryNumber' : minQuery , 'time':min}    

def writeOverallStat():
    with open('overall.json' , 'w') as file:
        json.dump(overallStats , file , indent=4)


runScript()
overAllMostCommonFunction()
mostTimeSpentFunction()
mostSpaceSpentQuery()
totalTimeRanCalculation()
writeOverallStat()
#genCpuStats()
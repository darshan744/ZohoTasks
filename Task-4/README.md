# TASK 4
- Now it takes a number argument to run the tpch query
- runs perf on the query execution
- Generates stats using `perf stat` and `perf record`
- After that some analysis is done it , it gives us : 
    - Mostly called function
    - Top 3 function's execution time in `ms`
    - Function which used most of the time
    - Time spent on user-space and kernel space
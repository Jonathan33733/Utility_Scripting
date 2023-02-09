# NOS_Assignment

## Important

**Do not** edit unless instructed too: 
- `setup/` directory
- `.gitignore` file

## Instructions

The first thing you need to do is create the content needed for the assignment that deals with running checks on file storage. 

Supply the **numbered** (sb**1501**)part of your username to the command below:

```sh
$ bash setup/buildAssignment <number>
```

> Note: if the numbered part of your username is below 1000, add 1000 to it and supply... ga49 becomes 1049

If by some mistake you delete, move or replace any of the content in `_Directory` you can run the bash script as follows:

```sh
$ bash setup/buildAssignment -r
```
### _Directory

The `_Directory` folder will not be tacked by default. 

This is where you need to point your solution to analyse the contents as part of your assessment.

## Your Tasks

**Summary** 

1. Develop as bash ultilty script in current directory that:
    - Can generate two different versions of UUID{1,2,3,4,5} without the use of built-in UUID generators:
        - Should be able to save to file AND print to terminal.
        - Check if previous UUID exists and see if collision
        - Check when last UUID was generated
    - Categorise content in `_Directory`:
        - For each child directory report how many of each file type there and collective size of each file type
        - For each child directory specify total space used, in human readable format
        - For each child directory report find shortest and largest length of file name
        - Output results to file AND option to return to terminal
    - For all functionality
      - there should be an argument 
      - can run functionality per argument(s)
      - Must be able to record who has logged into system and when, and which script commands have been supplied appended to a log file. 
2. Build a simple `man` page for your script
    -  ensure you have compressed the document and named it with the correct `man` identifier.
3. Throughout ensure you have reference to the PID of your script and PID of any sub commands run!
4. You are encouraged to develop your solutions in a branch off of `main` and make merges where appropriate. **No** penalisation for developing in `main`.
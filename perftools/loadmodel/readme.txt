Load model graphs
With the data in the Excel load model file, some calculations are available as input to a load scenario in eg. Loadrunner.

The goal here is to make some graphs of this data:
* One standard line graph showing the load in terms of number of vusers for each script/type, comparable to the one in Loadrunner Controller. A slight shift in the y-values should help to distinguish the lines.
* A small change of the above: show actual rampup: step function.
* Instead of the line, show dots where an action would occur. The position of the dots is the same as line in the previous graphs.
* Reserve one vertical (y) position for each vuser, group by script/type. Plot a horizontal line segment for each transaction, the length is the expected duration of one iteration, not including pacing.


# gDraw

gDraw is a 2D G-Code drawing program written in Processing 3. 
You can make a drawing with it and print this drawing as a line out of plastic with a 3D printer 
(currently, it supports only Ultimaker G-Code flavor and is only tested on an Ultimaker2).

How to use:

You can draw in two modes, the free mode and the fixed mode. “Free” is nice for organic drawings, 
“fixed” is good for geometric drawings, as it creates always straight lines in a metric grid. 
You can toggle between the two modes either by pushing the button “F” on your keyboard or 
by hitting the free/fixed button in the menu on the left.

You can zoom in and out of the canvas with the mouse wheel.

Interrupt the line by hitting the space bar. The program displays the path of the printhead, 
when it just moves but does not print, as a thin line. Because the printhead might still 
squeeze out small amounts of plastic during those paths and therefore you might want to keep 
control over where the printhead moves exactly.

You can save drawings by hitting the save button and you can load them again by hitting 
the load button. As the current drawing will not be deleted when you load a path, 
you can merge drawings by loading one drawing after another.

Finally, in order to create printable G-Code, you hit the “save G-Code”-button. You have to give 
your file the extension “.gcode” otherwise your printer might not recognize it as a valid G-Code file.

How it works:

G-Code is the “language” that a 3D printer understands. It is a text file, with a list of 
coordinates for X, Y and Z axis, and also for E (the extrusion motor). The printer reads this 
file, moves from coordinate to coordinate and squeezes out plastic as indicated in the value for E.

gDraw is a simple vector drawing program that turns your drawings into G-Code so you can 
print your drawings as lines of plastic.

Disclaimer:

I have an Ultimaker 2, so I wrote the program in such way that it works with my printer. 
If you have a different printer, you might have to adapt the G-Code header in order to make it 
work for you. Have a look in the lines 486-511 of my code. This is where the G-Code header 
for the Ultimaker 2 is written.


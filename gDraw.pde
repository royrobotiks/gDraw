//////////////////////////////////////////////////////////////////////////////////
// gDraw - Version 0.15                                                         //
//                                                                              //
// 2D drawing program for Ultimaker²  3D printer.                               //
// runs in Processing 3.2.3                                                     //
// [download for free from https://processing.org/download/]                    //
//                                                                              //
// Please find a manual for this program at                                     //
// http://www.niklasroy.com/articles/194/gdraw-free-software-for-you            //
//                                                                              //
// Please report bugs to nikl@s-roy.de                                          //
//////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////
// "THE BEER-WARE LICENSE" (Revision 23):                                       //
// <nikl@s-roy.de> wrote this program. As long as you retain this notice you    //
// can do whatever you want with this stuff. If we meet some day, and you think //
// this stuff is worth it, you can buy me a beer in return. Niklas Roy.         //
//////////////////////////////////////////////////////////////////////////////////

PFont font;
PrintWriter output;
 
//----------------------------------- user adjustable variables: 
 
int   drawSpeed=300;               // how fast moves the printhead when drawing
int   nonDrawSpeed=1000;           // how fast moves the printhead when NOT drawing
float eFactor=.6;                  // extrusion factor: how much material is squeezed out per distance
int   canvasSize=1800;             // workspace size (it's square; indicate size in 1/10 of mm here)

//----------------------------------- slightly experimental:

int   shiftXOnLoad=0;              // shifts drawing when loaded (indicated in 1/10 millimeters)
int   shiftYOnLoad=0;        

//----------------------------------- other variables:

float lx1[] = new float[10000];    // drawings are saved as coordinates of lines from lx1,ly1 to lx2,ly2 in arrays
float lx2[] = new float[10000];
float ly1[] = new float[10000];
float ly2[] = new float[10000];
int li=0;                          // current line number (which is also the number of lines in the drawing)
int drawState=0;
boolean star=false;
int gw=10;                         // grid width
float mag=1;                       // magnification
float camx;                        // camera position
float camy;
float x, y;

int pX=0;
int pY=0;
String Estr;
boolean overMenu=false;
boolean pMousePressed=false;
boolean free=false;
boolean debug=false;               // set to true for more info on screen

void setup() {
  fullScreen();
  noSmooth();
  font = loadFont("Consolas-20.vlw");
  textFont(font);
  camx=-canvasSize/2;                //camera position
  camy=-canvasSize/2;
  lx1[0]=canvasSize;
  ly1[0]=canvasSize;
}

void draw() {
  background(0);


  // ---------------------------------------------- camera
  if (mouseX<=250) {
    overMenu=true;
  } else {
    overMenu=false;
  }
  x=mouseX;
  y=mouseY;
  translate(width/2+camx, height/2+camy);
  scale(mag);

  // move camera if mouse hits edge
  if (x<500 && x>250) {
    camx+=(500-x)/10;
  }
  if (x>width-250) {
    camx+=(width-x-250)/10;
  } 
  if (y<150 && x>250) {
    camy+=(150-y)/7;
  }
  if (y>height-150) {
    camy+=(height-y-150)/7;
  }

  // do not lose image

  if (camx>125) {
    camx=125;
  }
  if (camx/mag<-canvasSize+125) {
    camx=(-canvasSize+125)*mag;
  }
  if (camy>0) {
    camy=0;
  }
  if (camy/mag<-canvasSize) {
    camy=-canvasSize*mag;
  }

  x=x-camx-width/2;
  y=y-camy-height/2;
  x=x/mag;
  y=y/mag;


  x=constrain(x, 0, canvasSize);
  y=constrain(y, 0, canvasSize);

  // ---------------------------------------------- draw grid

  for (int i=0; i<=canvasSize; i+=gw) {
    boolean milliline=true;
    stroke(32);
    if (i%50==0) {
      stroke(48);
    }
    if (i%100==0) {
      stroke(64);
      milliline=false;
    }

    if (milliline && free) {
    } else {
      line (i, 0, i, canvasSize);
      line (0, i, canvasSize, i);
    }
  }
  stroke(200);
  noFill();
  rect(0, 0, canvasSize, canvasSize);


  //  ----------------------------------------------  mouse cursor
  if (!free) {
    x=int(x/gw+.5)*gw;
    y=int(y/gw+.5)*gw;
  }
  stroke(128);
  line(-100, y, canvasSize+100, y);
  line(x, -100, x, canvasSize+100);

  // ---------------------------------------------- line states

  if (!free) {
    if (drawState==0 && mousePressed && !pMousePressed && !overMenu) {
      lx1[li]=x;
      ly1[li]=y;
      drawState=1;
    }

    if (drawState==1 && mousePressed &&  !pMousePressed && !overMenu) {
      lx2[li]=x;
      ly2[li]=y;
      if (li<9999) {
        li++;
      }
      lx1[li]=x;
      ly1[li]=y;
    }
  }

  if (free && mousePressed && !pMousePressed) {
    lx1[li]=x;
    ly1[li]=y;
  }
  if (free && mousePressed && pMousePressed) {
    if (dist(lx1[li], ly1[li], x, y)>10) {
      lx2[li]=x;
      ly2[li]=y;
      if (li<9999) {
        li++;
      }
      lx1[li]=x;
      ly1[li]=y;
    }
  }


  //  ---------------------------------------------- draw actual drawing

  for (int i=0; i<li; i++) {
    strokeWeight(8);
    stroke(255, 128);
    line(lx1[i], ly1[i], lx2[i], ly2[i]);

    // show smear
    if ((i+1)<li) {
      strokeWeight(3);
      stroke(255, 64);
      line(lx1[i+1], ly1[i+1], lx2[i], ly2[i]);
    }
  }

  if (drawState>0 && !overMenu) {
    strokeWeight(8);
    stroke(255, 128);
    line(lx1[li], ly1[li], x, y);
  }
  if (drawState==0 && !overMenu) {
    strokeWeight(3);
    stroke(255, 64);
    line(lx1[li], ly1[li], x, y);
  }

  strokeWeight(1);

  //  ----------------------------------------------  menu
  resetMatrix();
  fill(0);
  stroke(128);
  rect(-1, -1, 250, height+2);
  fill(255);
  int line=-30;
  if (button("Reset View", "[1]", line+=40)) {
    resetCam();
  }
  if (button("Free/Fixed", "[f]", line+=40)) {
    freeFixed();
  }
  if (free){
      if (button("Add Waypoint", "[ ]", line+=40)) {
      waypoint();
    }
  }else{
    if (button("Interrupt Line", "[ ]", line+=40)) {
      interrupt();
    }
  }
  if (button("Undo", "[u]", line+=40)) {
    undo();
  }
  if (button("Save drawing", "[s]", line+=40)) {
    saveD();
  }
  if (button("Load drawing", "[l]", line+=40)) {
    loadD();
  }
  if (button("Save G-Code", "[g]", line+=40)) {
    saveG();
  }

  //  //  ----------------------------------------------  debug

  if (debug){
    line+=50;
    textAlign(LEFT);
    text("drawState: "+drawState, 10, line+=30);
    text("li: "+li, 10, line+=30);
    text("x1 "+lx1[li], 10, line+=30);
    text("y1 "+ly1[li], 10, line+=30);
    text("x2 "+lx2[li], 10, line+=30);
    text("y2 "+ly2[li], 10, line+=30);
  }


  pMousePressed=mousePressed;
}


//  ----------------------------------------------  keyboard inputs
void keyPressed() { 

  if (key=='1') { // 1: reset view 
    resetCam();
  }
  if (key==' ') { // space: interrupt line
    if (free){
      waypoint();
    }else{
      interrupt();
    }
  }

  if (key=='u') { // u: undo - delete last line
    undo();
  }
  if (key=='s') { // s: save drawing
    saveD();
  }
  if (key=='l') { // l: load drawing
    loadD();
  }
  if (key=='g') { // g: save G-Code
    saveG();
  }
  if (key=='f') { // f: toggle free/fixed
    freeFixed();
  }
}


//  ---------------------------------------------- toggle between free and fixed mode
void freeFixed() {
  free=!free; // toggle free/fixed
}

//  ---------------------------------------------- mouse wheel magnifier
void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  if (e>0 && mag>.5) {
    mag-=.1;
    camx=camx+x/10;
    camy=camy+y/10;
  }
  if (e<0 && mag<4) {
    mag+=.1;
    camx=camx-x/10;
    camy=camy-y/10;
  }
}


//  ---------------------------------------------- menubutton
boolean button(String bLabel, String bShort, int bLine) {
  boolean mouseOver=false;
  if (mouseX>=10 && mouseX<=240 && mouseY>=bLine && mouseY<=bLine+31) { // mouse over button
    mouseOver=true;
    fill(255, 0, 0);
    if (mousePressed) {
      fill(128);
    }
  } else {
    fill(32);
  }
  rect(10, bLine, 230, 30);

    fill(255);

  textAlign(LEFT);
  text(bLabel, 25, bLine+22);
  textAlign(RIGHT);
  text(bShort, 230, bLine+22);
  if (mousePressed && mouseOver && !pMousePressed) {
    return true; // button clicked
  } else {
    return false; // button not clicked
  }
}

//  ---------------------------------------------- reset camera
void resetCam() {
  // 1: reset camera
  mag=1;
  camx=-canvasSize/2; //camera position
  camy=-canvasSize/2;
}

//  ---------------------------------------------- undo last line
void undo() {
  if (li>0) {
    li--;
  }
    if (li==0) {
    lx1[0]=canvasSize;
    ly1[0]=canvasSize;
  }
}

//------ interrupt draw line
void interrupt() {
  drawState=0;
}

//------ add waypoint
void waypoint() {
  lx1[li]=x;
  ly1[li]=y;
  lx2[li]=x;
  ly2[li]=y;
  if (li<9999){li++;}
  lx1[li]=x;
  ly1[li]=y;
}

//  ---------------------------------------------- load drawing // filepath
void loadD() {
  //------ open filesystem; choose filename
  selectInput("Select a file to load drawing:", "dlSelected");
}

//  ---------------------------------------------- load drawing

void dlSelected(File selection) {

  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("load drawing...");
    String line;
    BufferedReader reader;
    reader = createReader(selection.getAbsolutePath());
    try {
      line = reader.readLine();
    } 
    catch (IOException e) {
      e.printStackTrace();
      line = null;
    }
    int lines=int(line);
    println ("number of lines: "+lines);
    for (int i=0; i<lines; i++) {
      try {
        line = reader.readLine();
      } 
      catch (IOException e) {
        e.printStackTrace();
        line = null;
      }
      println(line);
      String[] val = splitTokens(line, ",");

      lx1[li]=int(val[0])+shiftXOnLoad;
      ly1[li]=int(val[1])+shiftYOnLoad;
      lx2[li]=int(val[2])+shiftXOnLoad;
      ly2[li]=int(val[3])+shiftYOnLoad;
      li++;
      lx1[li]=lx2[li-1];
      ly1[li]=ly2[li-1];
    }
  }
  drawState=0;
}

//  ---------------------------------------------- save drawing // filepath
void saveD() {
  //------ open filesystem; choose filename
  selectOutput("Select a file to save drawing:", "dSelected");
}

//  ---------------------------------------------- save drawing

void dSelected(File selection) {

  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("saving drawing...");
    output = createWriter(selection.getAbsolutePath()); 
    output.println(li); // number of coordinates
    //------ coordinates:
    for (int i=0; i<=li; i++) {
      output.println(  
        int(lx1[i])+","+
        int(ly1[i])+","+
        int(lx2[i])+","+
        int(ly2[i])
        );
    }
    output.flush(); // Writes the remaining data to the file
    output.close(); // Finishes the file
  }
}

//  ---------------------------------------------- save G-Code // filepath
void saveG() {  

  //------ open filesystem; choose filename
  selectOutput("Select a file to write G-Code:", "gSelected");
}


//  ---------------------------------------------- save G-Code

void gSelected(File selection) {

  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("saving file G-Code...");
    output = createWriter(selection.getAbsolutePath()); 

    //------ gcode header:

    output.println(";FLAVOR:UltiGCode"); 
    output.println(";TIME:1"); 
    output.println(";MATERIAL:1"); 
    output.println(";MATERIAL2:0"); 
    output.println(";Layer count: 1"); 
    output.println(";LAYER:0"); 
    output.println(""); 
    output.println("M107"); 
    output.println(";fan off"); 
    output.println("G10"); 
    output.println(";retract filament according to settings of M207"); 
    output.println("G0 F4320 X22.1 Y22.1 Z.3"); 
    output.println(";Coordinated Movement X Y Z E"); 
    output.println(""); 
    output.println(";TYPE:WALL-INNER"); 
    output.println(""); 
    output.println("G11"); 
    output.println(";retract recover filament according to settings of M208"); 
    output.println("G1 F900 E25");
    output.println("G1 F900 E40");

    output.println("G1 X80");
    output.println("G1 Y27");
    output.println("G1 X30");
    output.println("");
    output.println("");

    //------ coordinates:
    float posX1;
    float posY1;
    float posX2;
    float posY2;
    float e=40;
    for (int i=0; i<li; i++) {

      posX1=(canvasSize-lx1[i])/10+25;
      posY1=(canvasSize-ly1[i])/10+30;
      posX2=(canvasSize-lx2[i])/10+25;
      posY2=(canvasSize-ly2[i])/10+30;

      pX=int(posX2);
      pY=int(posY2);

      String X1str = nf(posX1, 4, 1);
      String Y1str = nf(posY1, 4, 1);        
      String X2str = nf(posX2, 4, 1);
      String Y2str = nf(posY2, 4, 1);

      X1str = X1str.replace(",", ".");
      Y1str = Y1str.replace(",", ".");        
      X2str = X2str.replace(",", ".");
      Y2str = Y2str.replace(",", ".");
      e=e+(dist(posX1, posY1, posX2, posY2)*eFactor);
      Estr = nf(e, 7, 3);
      Estr = Estr.replace(".", "");
      Estr = Estr.replace(",", ".");
      output.println("G0 F"+nonDrawSpeed+" X"+X1str+" Y"+Y1str);
      output.println("G1 Z1");
      output.println("G1 F"+drawSpeed+"  X"+X2str+" Y"+Y2str+" E"+Estr);
    }

    //------ end of gcode:

    output.println("");
    output.println("");
    output.println("; nozzle cools down for the following 14 coordinates:");

    output.println("G0 F900 E"+(e-5)); // retract
    output.println("G0 F4800 X25.0  Y17.0"); 
    output.println("G1 X25.0  Y14.0");      
    output.println("G1 X25.0  Y17.0"); 
    output.println("G1 X25.0  Y14.0");      
    output.println("G1 X25.0  Y17.0"); 
    output.println("G1 X25.0  Y14.0");      
    output.println("G1 X25.0  Y17.0"); 
    output.println("G1 X25.0  Y14.0");      
    output.println("G1 X25.0  Y17.0"); 
    output.println("G1 X25.0  Y14.0");      
    output.println("G1 X25.0  Y17.0"); 
    output.println("G1 X25.0  Y14.0");      
    output.println("G1 X25.0  Y17.0"); 
    output.println("G1 X25.0  Y14.0");      
    output.println("G1 X25.0  Y17.0"); 
    output.println("G1 X25.0  Y14.0");
    output.println("G10");
    output.println(";retract filament according to settings of M207");
    output.println("M107");
    output.println(";fan off");
    output.println("M104 S0");
    output.println(";End of Gcode");
    output.flush(); // Writes the remaining data to the file
    output.close(); // Finishes the file

    println("saved!");
  }
}

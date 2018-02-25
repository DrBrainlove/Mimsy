


import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.util.stream.Stream;
import java.util.stream.IntStream;


// Need to manually import minim
import ddf.minim.*;





//*************************************************************** P3LX OBJECTS
// Top-level, we have a model and a P3LX instance
static GraphModel model;
static MimsyMap mimsyMap;
P3LX lx;

LXPattern[]       patterns;
//LXTransition[]    transitions;
//Effects           effects;
LXEffect[]        effectsArr;


UIBars uiBarsDD;
UIBars uiBarsTL;
UIBars uiBarsTR;

UIMimsyControls uiMimsyControls;
UIMimsyCamera uiMimsyCamera;

UI3dContext uiContext;
UI3dComponent pointCloudDodecahedron;
UI3dComponent pointCloudTetraLeft;
UI3dComponent pointCloudTetraRight;
UI3dComponent uiWalls;
UI3dComponent uiNodes;

// define Muse globals
UIMuseControl uiMuseControl;
// UIMuseHUD uiMuseHUD;
MuseConnect muse;
MuseHUD museHUD;
int MUSE_OSCPORT = 5000;
boolean museEnabled = false;



public BooleanParameter uiOrthoCamera = new BooleanParameter("Ortho");
public BoundedParameter clipNear = new BoundedParameter("Clip Near", 0, 0, 100);
public BoundedParameter clipFar = new BoundedParameter("Clip Far", 100, 0, 100);


// Let's NOT work in inches, but will leave these here for porting
// patterns that do.
final static float INCHES = 25.4;
final static float FEET = 12.0*INCHES;

/** *************************************************************** MAIN SETUP
 * Set up models etc for whole package (Processing thing)
 * Fill out UI elements
 * Connect to output hardware
************************************************************************** **/

public void settings() {
  size(1200, 900, "processing.opengl.PGraphics3D");
  smooth(4);
}

void setup() {

  startMillis = System.currentTimeMillis();
  lastMillis = startMillis;

  //==================================================================== Model
  mimsyMap = new MimsyMap(MIMSY_TYPE);
  model = mimsyMap.buildModel();
  out("Model Name: %s\n", model.layer);
  out("Finished Building Model");

  //==================================================== Initialize sensors
  //initialize the Muse connection
  // TODO: this should gracefully handle lack of Muse OSC input
  muse = new MuseConnect(this, MUSE_OSCPORT);
  museHUD = new MuseHUD(muse);
  out("added Muse OSC parser and HUD");


   try {
    lx = new LXStudio(this, model, false) {
      public void initialize(LXStudio lx, LXStudio.UI ui) {
        //lx.engine.registerComponent("tenereSettings", new Settings(lx, ui));
        lx.registerEffect(BlurEffect.class);
        lx.registerEffect(DesaturationEffect.class);
        // TODO: the UDP output instantiation will go in here!
        out("Initialized LXStudio");
      }

      public void onUIReady(LXStudio lx, LXStudio.UI ui) {
        //ui.preview.setRadius(80*FEET).setPhi(-PI/18).setTheta(PI/12);
        //ui.preview.setCenter(0, model.cy - 2*FEET, 0);
        //ui.preview.addComponent(new UISimulation());       
        ui.preview.addComponent(uiNodes = new UINodes());
        ui.preview.addComponent(uiBarsDD = new UIBars(((GraphModel)model).getLayer(DD)));
        ui.preview.addComponent(uiBarsTL = new UIBars(((GraphModel)model).getLayer(TL)));
        ui.preview.addComponent(uiBarsTR = new UIBars(((GraphModel)model).getLayer(TR)));
        ui.preview.pointCloud.setPointSize(2.0).setVisible(true);
        //ui.preview.pointCloud.setVisible(false); //TODO doesnt work
        uiMimsyControls = (UIMimsyControls) new UIMimsyControls(ui)
          .addToContainer(ui.leftPane.global);
        uiMimsyCamera = (UIMimsyCamera) new UIMimsyCamera(ui) 
          .addToContainer(ui.leftPane.global);
        
        // add Muse UI components
        uiMuseControl = (UIMuseControl) new UIMuseControl(ui, muse, museHUD).setExpanded(true).addToContainer(ui.leftPane.global);        // Narrow angle lens, for a fuller visualization
        ui.preview.perspective.setValue(30);
        ui.preview.radius.setValue(RADIUS * 4.0);

       // uiTreeControls = (UITreeControls) new UITreeControls(ui).addToContainer(ui.leftPane.global);
        out("Initialized LX UI");
      }
    };
  } catch (Exception x) {
    x.printStackTrace();
  }
  //end from tenere


  if (TEST_SYMMETRY) {
    symTest = new SymmetryTest(model);
    symTest.runSymmetryTests();
    exit();
  }


  //==================================================== Output to Controllers
  // create outputs via CortexOutput
  if (OUTPUT) {
    mimsyMap.buildChannelMap(model);
    buildOutputs();
    out("Built output clients");
  }



}

void draw() {
  // Wipe the frame...
  // background(#292929);

  // ...and everything else is handled by P3LX!
  drawFPS();

  // DMK:  Somewhat strongly suspect cubic gamma on APA102 is wild overkill, but we'll check /
  //       add as a config
  // Gamma correction here. Apply a cubic to the brightness
  // for better representation of dynamic range
  //
  /*
  color[] sendColors = lx.getColors();
  float hsb[] = new float[3];
  for (int i = 0; i < sendColors.length; ++i) {
    LXColor.RGBtoHSB(sendColors[i], hsb);
    float b = hsb[2];
    sendColors[i] = lx.hsb(360.*hsb[0], 100.*hsb[1], (b*b)/256.);
  }
  */


}




//************************************************************ AUX SUBROUTINES
//------------------------------------------------------------------ FPS Meter
long simulationNanos = 0;
static long startMillis = System.currentTimeMillis();
static long lastMillis = startMillis;

int FPS_TARGET = 60;
boolean DRAW_FPS = true;
void drawFPS() {
  if (DRAW_FPS) {
    fill(#FFFFFF);
    textSize(9);
    textAlign(LEFT, BASELINE);
    text("FPS: " + ((int) (frameRate*10)) / 10. + " / " + "60" + " (-/+)", 4, height-4);
  }
}

//-------------------------------------------------------------------- Logging

import java.text.SimpleDateFormat;
public static void mark() {
  lastMillis = System.currentTimeMillis();
}


public static void announce(String format, Object... args) {
  String timeStamp = new SimpleDateFormat("HH:mm:ss")
                         .format(new Date());
  //int now = millis();
  long now = System.currentTimeMillis();
  long dif = now - lastMillis;
  String prefix = String.format("%s (%5d ms): ", timeStamp, dif);
  out(prefix + format, args);
  lastMillis = now;
}

public static void out(String format, Object... args) {
  //System.out.format(prefix);
  System.out.format(format, args);
  if (!format.endsWith("\n")) {
    System.out.format("\n");
  }
}

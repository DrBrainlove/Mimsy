/**
*
* MuseConnect
*
* @author: Michael J. Pesavento, Ph.D.
*         PezTek
*         mike@peztek.com
*
* copywrite (c) 2015 PezTek
*
* This software is created and distributed under the
* GNU General Public License v3
* http://www.gnu.org/licenses/gpl.html
*
* --------------------------------------
*
* v0.1 2015.03.21
* v0.2 2015.08.20 updated for brainlove and DBLX
* v0.3 2015.11.15 updated MuseHUD to display metrics
* v0.4 2017.08.21 muse HUD revised for processing3 and p3LX
*
* --------------------------------------
* Requirements:
* requires oscP5 library package for Processing 3
*
* Need to have muse-io installed, get SDK from here:
* https://sites.google.com/a/interaxon.ca/muse-developer-site/download
* Update: package is no longer available on muse website

* Connect the muse device to controlling computer via bluetooth
*
* load muse OSC output in command line with:
*      muse-io --preset 14 --osc osc.udp://localhost:5000
*
*/


import oscP5.*;
import netP5.*;

// turn this on for debugging
boolean verboseMuse = false;

class MuseConnect {

  Object parent; //need to have root Processing object - this - passed to constructor

  OscP5 oscP5;
  NetAddress remoteOSCLocation;

  // default is to connect to data stream on localhost
  private String host = "127.0.0.1";
  private int port;

  public float[] delta_absolute = new float[] {0,0,0,0};
  public float[] theta_absolute = new float[] {0,0,0,0};
  public float[] alpha_absolute = new float[] {0,0,0,0};
  public float[] beta_absolute  = new float[] {0,0,0,0};
  public float[] gamma_absolute = new float[] {0,0,0,0};

  public float[] delta_rel = new float[] {0,0,0,0};
  public float[] theta_rel = new float[] {0,0,0,0};
  public float[] alpha_rel = new float[] {0,0,0,0};
  public float[] beta_rel  = new float[] {0,0,0,0};
  public float[] gamma_rel = new float[] {0,0,0,0};

  public float[] delta_session = new float[] {0,0,0,0};
  public float[] theta_session = new float[] {0,0,0,0};
  public float[] alpha_session = new float[] {0,0,0,0};
  public float[] beta_session  = new float[] {0,0,0,0};
  public float[] gamma_session = new float[] {0,0,0,0};

  public int touching_forehead = 0; //boolean, 1 is on forehead correctly
  public float[] horseshoe = new float[] {3,3,3,3}; // values: 1= good, 2=ok, 3=bad
  public float battery_level = 0; // percent battery remaining.
  public float concentration=0;
  public float mellow = 0;

  public boolean museActive = false; // true if touching_forehead and all horseshoes are 'good'

  public MuseConnect(Object parent) {
    this.parent = parent;
    this.port = 5000;
    oscP5 = new OscP5(parent, port); // read from the muse port
    remoteOSCLocation = new NetAddress(host, port);
    println("Connected to Muse headset");
  }

  public MuseConnect(Object parent, int _port) {
    this.port = _port;
    oscP5 = new OscP5(parent, port); // read from the muse port
    remoteOSCLocation = new NetAddress(host, this.port);
    println("Opened OSC port to Muse headset on " + this.host +":" + this.port);
  }

  public MuseConnect(Object parent, String _host, int _port) {
    this.host = _host;
    this.port = _port;
    oscP5 = new OscP5(parent, port); // read from the muse port
    remoteOSCLocation = new NetAddress(host, this.port);
    println("Opened OSC port to Muse headset on " + this.host +":" + this.port);
  }

  private void loadFromOsc(float[] arr, oscP5.OscMessage msg, int n) {
    // n is the expected number of elements in the message
    for(int i=0; i<n; i++) {
      arr[i] = msg.get(i).floatValue();
    }
  }
  private void loadFromOsc(int[] arr, oscP5.OscMessage msg, int n) {
    // n is the expected number of elements in the message
    for(int i=0; i<n; i++) {
      arr[i] = msg.get(i).intValue();
    }
  }

  public final String arr2str(float[] arr) {
    String s = "";
    for (int i=0; i< arr.length; i++) {
      s += str(arr[i]);
      if (i!=arr.length-1) {
        s += " ";
      }
    }
    return s;
  }

  //return true if all of the sensors are good (1.0)
  public boolean signalIsGood() {
    boolean is_good = true;
    if (this.touching_forehead != 1) {
      this.museActive = false;
      return false;
    }
    for (int i=0; i<this.horseshoe.length; i++) {
      if (this.horseshoe[i] != 1.0) {
        is_good = false;
        break;
      }
    }
    this.museActive = is_good;
    return is_good;
  }

  private float average(float arr[]) {
    float out=0;
    for (int i=0; i<arr.length; i++)
      out+=arr[i];
    return out/arr.length;
  }

  /**
   * only take the average of the middle two sensors, which should be FP1 and FP2
   */
  private float averageFront(float arr[]) {
    if (arr.length != 4)
      throw new RuntimeException("Bandwidth arrays dont have length 4, incorrect input");
    return (arr[1]+arr[2])/2;
  }

  /**
   * only take the average of the outer two sensors, which should be TP9 and TP10
   */
  private float averageTemporal(float arr[]) {
    if (arr.length != 4)
      throw new RuntimeException("Bandwidth arrays dont have length 4, incorrect input");
    return (arr[0]+arr[3])/2;
  }

  // select a single method to flatten the 4 sensor array for output in the getX() methods
  private float flattenSensor(float[] arr) {
    // return arr[1]; // just use front left (FP1) for now
    return averageFront(arr);
    // return average(arr);
  }


  public float getMellow() {
    return this.mellow;
  }

  public float getConcentration() {
    return this.concentration;
  }

  public float getDelta() {
    return flattenSensor(this.delta_session);
  }

  public float getTheta() {
    return flattenSensor(this.theta_session);
  }

  public float getAlpha() {
    return flattenSensor(this.theta_session);
  }

  public float getBeta() {
    return flattenSensor(this.alpha_session);
  }

  public float getGamma() {
    return flattenSensor(this.gamma_session);
  }



} //end MuseConnect


// globally accessible conversion of array to string
String arr2str(float[] arr) {
  String s = "";
  for (int i=0; i< arr.length; i++) {
    s += str(arr[i]);
    if (i!=arr.length-1) {
      s += " ";
    }
  }
  return s;
}


//*********************************************************************************************
// global function to catch all OSC messages
// NOTE: this will conflict with any other use of oscP5 and definitions of this method!
// future versions will be in pure java to avoid this problem

public void oscEvent(oscP5.OscMessage msg) {

  if(msg.checkAddrPattern("/muse/elements/horseshoe")==true) {
    muse.loadFromOsc(muse.horseshoe, msg, 4);
    if (verboseMuse) println("reading signal quality: " + arr2str(muse.horseshoe));
  }
  else if(msg.checkAddrPattern("/muse/batt")==true) {
    muse.battery_level = msg.get(0).intValue() / 100;
    if (verboseMuse) println("******* received battery level: " + str(muse.battery_level));
  }

  else if(msg.checkAddrPattern("/muse/elements/touching_forehead")==true) {
    muse.touching_forehead = msg.get(0).intValue();
  }
  //*************************
  // catch and report absolute bandwidth values
  else if(msg.checkAddrPattern("/muse/elements/delta_absolute")==true) {
    muse.loadFromOsc(muse.delta_absolute, msg, 4);
    if (verboseMuse) println("received /muse/elements/delta_absolute: " + arr2str(muse.delta_absolute));
  }
  else if(msg.checkAddrPattern("/muse/elements/theta_absolute")==true) {
    muse.loadFromOsc(muse.theta_absolute, msg, 4);
    if (verboseMuse) println("received /muse/elements/theta_absolute: " + arr2str(muse.theta_absolute));
  }
  else if(msg.checkAddrPattern("/muse/elements/alpha_absolute")==true) {
    muse.loadFromOsc(muse.alpha_absolute, msg, 4);
    if (verboseMuse) println("received /muse/elements/alpha_absolute: "+ arr2str(muse.alpha_absolute));
  }
  else if(msg.checkAddrPattern("/muse/elements/beta_absolute")==true) {
    muse.loadFromOsc(muse.beta_absolute, msg, 4);
    if (verboseMuse) println("received /muse/elements/beta_absolute: " + arr2str(muse.beta_absolute));
  }
  else if(msg.checkAddrPattern("/muse/elements/gamma_absolute")==true) {
    muse.loadFromOsc(muse.gamma_absolute, msg, 4);
    if (verboseMuse) println("received /muse/elements/gamma_absolute: " + arr2str(muse.gamma_absolute));
  }
  //*************************
  // catch and report session scores
  else if(msg.checkAddrPattern("/muse/elements/delta_session_score")==true) {
    muse.loadFromOsc(muse.delta_session, msg, 4);
    if (verboseMuse) println("received /muse/elements/delta_session_score: " + arr2str(muse.delta_session));
  }
  else if(msg.checkAddrPattern("/muse/elements/theta_session_score")==true) {
    muse.loadFromOsc(muse.theta_session, msg, 4);
    if (verboseMuse) println("received /muse/elements/theta_session_score: " + arr2str(muse.theta_session));
  }
  else if(msg.checkAddrPattern("/muse/elements/alpha_session_score")==true) {
    muse.loadFromOsc(muse.alpha_session, msg, 4);
    if (verboseMuse) println("received /muse/elements/alpha_session_score: "+ arr2str(muse.alpha_session));
  }
  else if(msg.checkAddrPattern("/muse/elements/beta_session_score")==true) {
    muse.loadFromOsc(muse.beta_session, msg, 4);
    if (verboseMuse) println("received /muse/elements/beta_session_score: " + arr2str(muse.beta_session));
  }
  else if(msg.checkAddrPattern("/muse/elements/gamma_session_score")==true) {
    muse.loadFromOsc(muse.gamma_session, msg, 4);
    if (verboseMuse) println("received /muse/elements/gamma_session_score: " + arr2str(muse.gamma_session));
  }
  //*************************
  // catch and report relative bandwidth values
  else if(msg.checkAddrPattern("/muse/elements/delta_relative")==true) {
    muse.loadFromOsc(muse.delta_rel, msg, 4);
    if (verboseMuse) println("received /muse/elements/delta_relative: " + arr2str(muse.delta_rel));
  }
  else if(msg.checkAddrPattern("/muse/elements/theta_relative")==true) {
    muse.loadFromOsc(muse.theta_rel, msg, 4);
    if (verboseMuse) println("received /muse/elements/theta_relative: " + arr2str(muse.theta_rel));
  }
  else if(msg.checkAddrPattern("/muse/elements/alpha_relative")==true) {
    muse.loadFromOsc(muse.alpha_rel, msg, 4);
    if (verboseMuse) println("received /muse/elements/alpha_relative: "+ arr2str(muse.alpha_rel));
  }
  else if(msg.checkAddrPattern("/muse/elements/beta_relative")==true) {
    muse.loadFromOsc(muse.beta_rel, msg, 4);
    if (verboseMuse) println("received /muse/elements/beta_relative: " + arr2str(muse.beta_rel));
  }
  else if(msg.checkAddrPattern("/muse/elements/gamma_relative")==true) {
    muse.loadFromOsc(muse.gamma_rel, msg, 4);
    if (verboseMuse) println("received /muse/elements/gamma_relative: " + arr2str(muse.gamma_rel));
  }

  // concentration and mellow metrics
  else if(msg.checkAddrPattern("/muse/elements/experimental/concentration")==true) {
    muse.concentration = msg.get(0).floatValue();
    if (verboseMuse) println("received /muse/elements/experimental/concentration: " + muse.concentration);
  }
  else if(msg.checkAddrPattern("/muse/elements/experimental/mellow")==true) {
    muse.mellow = msg.get(0).floatValue();
    if (verboseMuse) println("received /muse/elements/experimental/mellow: " +muse.mellow);
  }

} // end oscEvent()





//============================================================================
//============================================================================

class MuseHUD {
  /*
  * Displays the connection quality and battery of a Muse headset.
  * Currently doesnt apppear on the screen, should eventually dynamically
  * adjust position to be in lower left corner
  * This is using Processing primitives, not the LX framework for a UI.
  * Could definitely use a revamp
  */
  MuseConnect muse; //have reference to muse object

  public final int WIDTH = 180; // this can change with the UI
  public final int HEIGHT = 160;
  public final int VOFFSET = -10;
  public final int HEAD_CENTER_H = HEIGHT - 30;
  public final int HEAD_CENTER_W = WIDTH - 40;

  public final int SENSOR_W = 8;
  public final int SENSOR_H = 10;

  public final int GRAPHBASE = 90;
  public final int GRAPHHEIGHT = 80;
  public final int BARWIDTH = 8;


  // colors for muse horseshoe HUD
  // colorMode(RGB, 255);
  private color morange = 0;
  private color mgreen = 0;
  private color mblue = 0;
  private color mred = 0;
  private color morangel = 0;
  private color mgreenl = 0;
  private color mbluel = 0;
  private color mredl = 0;

  public MuseHUD(MuseConnect muse) {
    this.muse = muse;
    if (muse == null) {
      println("Muse object has not been instantiated yet");
    }

    // set up horseshoe colors
    colorMode(RGB, 255);
    morange = color(204,102,0);
    mgreen = color(102, 204, 0);
    mblue = color(0, 102, 204);
    mred = color(204, 0, 102);
    morangel = color(233, 187, 142);
    mgreenl = color(187, 233, 142);
    mbluel = color(142, 187, 233);
    mredl = color(233, 142, 187);

  }

  private int barHeight(int maxHeight, float value) {
    if (value > 1.0) {
      value = 1;
    }
    return int(floor( - (maxHeight * value)));
  }

  private void updateHUD(PGraphics image) {
    colorMode(RGB, 255);
    int backColor = 50; //dark gray
    int foreColor = 200; // not quite white
    fill(foreColor);
    image.fill(backColor);
    image.ellipseMode(CENTER);
    image.ellipse(HEAD_CENTER_W, HEAD_CENTER_H, 45, 50); //head
    // println("Muse state: " + str(muse.touching_forehead) + " " + str(muse.horseshoe[0]) + " " + str(muse.horseshoe[1]) + " " + str(muse.horseshoe[2]) + " " + str(muse.horseshoe[3]));

    // draw the center contact impedance
    image.stroke(0);
    image.strokeWeight(2);
    if (muse.touching_forehead==1)  image.fill(0);
    else image.fill(backColor);
    image.ellipse(HEAD_CENTER_W, HEAD_CENTER_H - 18, SENSOR_H-2, SENSOR_W-2); //on_forehead

    if (muse.touching_forehead==1) {
      // horseshoe values: 1= good, 2=ok, 3=bad
      // left temporal
      image.stroke(morange);

      if (muse.horseshoe[0]==1) {  image.fill(morange); }
      else if(muse.horseshoe[0]==2) { image.fill(morangel); }
      else { image.fill(backColor); }
      image.ellipse(HEAD_CENTER_W - 12, HEAD_CENTER_H + 12, SENSOR_W, SENSOR_H); // TP9

      // left frontal
      image.stroke(mgreen);
      if (muse.horseshoe[1]==1) {  image.fill(mgreen); }
      else if(muse.horseshoe[1]==2) { image.fill(mgreenl); }
      else { image.fill(backColor); }
      image.ellipse(HEAD_CENTER_W - 15, HEAD_CENTER_H - 8, SENSOR_W, SENSOR_H); //FP1

      // right frontal
      image.stroke(mblue);
      if (muse.horseshoe[2]==1) {  image.fill(mblue); }
      else if(muse.horseshoe[2]==2) { image.fill(mbluel); }
      else { image.fill(backColor); }
      image.ellipse(HEAD_CENTER_W + 15, HEAD_CENTER_H - 8, SENSOR_W, SENSOR_H); //FP2

      // right temporal
      image.stroke(mred);
      if (muse.horseshoe[3]==1) {  image.fill(mred); }
      else if(muse.horseshoe[3]==2) { image.fill(mredl); }
      else { image.fill(backColor); }
      image.ellipse(HEAD_CENTER_W + 12, HEAD_CENTER_H + 12, SENSOR_W, SENSOR_H); //TP10
    }
    else {
      // we probably dont have the headset on, no point in trying to color the rest
      image.stroke(0);
      image.fill(backColor);
      image.ellipse(HEAD_CENTER_W - 12, HEAD_CENTER_H + 12, SENSOR_W, SENSOR_H); // TP9
      image.ellipse(HEAD_CENTER_W - 15, HEAD_CENTER_H - 8, SENSOR_W, SENSOR_H); //FP1
      image.ellipse(HEAD_CENTER_W + 15, HEAD_CENTER_H - 8, SENSOR_W, SENSOR_H); //FP2
      image.ellipse(HEAD_CENTER_W + 12, HEAD_CENTER_H + 12, SENSOR_W, SENSOR_H); //TP10
    }

    int battery = int(muse.battery_level);
    String battstr = "batt: " + str(battery) + "%";
    color battfill = color(255); //white for default
    if (muse.touching_forehead==0) {
      battfill = color(0,0,0); // disabled battery
    }
    else if (battery < 10) {
      battfill = color(255, 0, 0); // red battery warning
    }
    else if (battery < 20) {
      battfill = color(255,230,0); // yellow battery warning
    }
    image.stroke(battfill);
    image.fill(battfill);
    image.textSize(14);
    image.textAlign(LEFT);
    image.text(battstr, 30, HEIGHT-25);

    // plot the graphs
    image.stroke(0);
    image.strokeWeight(1);
    image.line(10, GRAPHBASE, 130, GRAPHBASE);
    image.line(50, GRAPHBASE, 50, GRAPHBASE-GRAPHHEIGHT);
    textSize(10);
    image.fill(200);
    image.text("M C       D T A B G", 18, GRAPHBASE+12);
    // image.text("M C      \u03B4 \u03B8 \u03B1 \u03B2 \u03B3", 13, GRAPHBASE);

    if (muse.signalIsGood()) { // (true)
      // println(muse.getMellow(), muse.getConcentration());
      image.stroke(0);
      image.fill(7, 145, 178); //blue
      image.rect(15, GRAPHBASE, BARWIDTH, barHeight(GRAPHHEIGHT, muse.getMellow()));
      image.fill(178, 85,0); //orange
      image.rect(28, GRAPHBASE, BARWIDTH, barHeight(GRAPHHEIGHT, muse.getConcentration()));

      image.fill(43, 131, 186); //blue
      image.rect(60, GRAPHBASE, BARWIDTH, barHeight(GRAPHHEIGHT, muse.getDelta()));
      image.fill(171, 221, 164); //green
      image.rect(72, GRAPHBASE, BARWIDTH, barHeight(GRAPHHEIGHT, muse.getTheta()));
      image.fill(253, 174, 97); //orange
      image.rect(84, GRAPHBASE, BARWIDTH, barHeight(GRAPHHEIGHT, muse.getAlpha()));
      image.fill(215, 25, 28); //red
      image.rect(96, GRAPHBASE, BARWIDTH, barHeight(GRAPHHEIGHT, muse.getBeta()));
      image.fill(255, 255, 191); //offwhite
      image.rect(108, GRAPHBASE, BARWIDTH, barHeight(GRAPHHEIGHT, muse.getGamma()));

    }

    image.endDraw();
  }


  // use this version if drawing in someone else's buffer
  public void drawHUD(PGraphics buffer) {
    updateHUD(buffer);
  }
}






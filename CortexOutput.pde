/*
 * Motor cortex:
 * Create output to the LEDs via OSC packets to BeagleBone Black
 * Each BBB pushes up to 24 channels of <=512 pixels per channel
 *
 * @author mjp 2015.08.08
 */


import java.io.IOException;
import java.io.OutputStream;
import java.net.ConnectException;
import java.net.InetSocketAddress;
import java.net.Socket;
import heronarts.lx.LX;
import java.util.*;

private final String ControllerIPs[] = {
  //"192.168.1.85",
  //"192.168.1.81",
  "192.168.1.87",
  // "192.168.1.86",
};

//public ArrayList<int[]> channelMap;


/* ********** Physical Limits on Channels ********************************** */
int nPixPerChannel = 342; // OPC server is set to 512 pix per channel
//int nChannelPerBoard = 5;
//int nChannelPerBoard = 45;
int nChannelPerBoard = 45;

/* ********** Create an array for each board mapping each pixel to a channel */

int[] concatenateChannels(int boardNum) {
    // expects boardNum to be indexed starting at *1*
    System.out.format("Cortex #%d: %s\n", boardNum, ControllerIPs[boardNum-1]);
    int[] pixIndex = new int[nPixPerChannel*nChannelPerBoard];
    int boardOffset = (boardNum-1) * nChannelPerBoard; 

    for (int i=boardOffset; i<boardOffset+nChannelPerBoard; i++) {
        int[] channelIx = channelMap.get(i);
        System.out.format("adding channel %d, %d pix\n", i, channelIx.length);
        for(int j=0; j<channelIx.length; j++) {
            //println( i * nPixPerChannel - boardOffset*nPixPerChannel + j);
            pixIndex[i * nPixPerChannel - boardOffset*nPixPerChannel + j] = channelIx[j];
        }
    }    
    return pixIndex;
}

/* ********** Final routine to set up the output ****************************/
void buildOutputs() {
    //for (int i = 1; i < ControllerIPs.length; i++) {
    //    lx.addOutput(new CortexOutput(lx ,ControllerIPs[i-1], i, concatenateChannels(i)));
    //}
    //lx.addOutput(new CortexOutput(lx ,"192.168.1.85", 1, concatenateChannels(1)));
    //lx.addOutput(new CortexOutput(lx ,"192.168.1.81", 2, concatenateChannels(2)));
    lx.addOutput(new CortexOutput(lx, "192.168.1.87", 1, concatenateChannels(1)));
    //lx.addOutput(new CortexOutput(lx ,"192.168.1.86", 3, concatenateChannels(3)));
}

/* ********** List of Output Boards for UI **********************************/
ArrayList<CortexOutput> cortexList = new ArrayList<CortexOutput>();


public class CortexOutput extends LXOutput {
  // constants for creating OPC header
  static final int HEADER_LEN = 4;
  static final int BYTES_PER_PIXEL = 3;
  static final int INDEX_CHANNEL = 0;
  static final int INDEX_COMMAND = 1;
  static final int INDEX_DATA_LEN_MSB = 2;
  static final int INDEX_DATA_LEN_LSB = 3;
  static final int INDEX_DATA = 4;
  static final int OFFSET_R = 0;
  static final int OFFSET_G = 1;
  static final int OFFSET_B = 2;

  static final int COMMAND_SET_PIXEL_COLORS = 0;

  static final int PORT = 7890; //the standard OPC port

  Socket socket;
  OutputStream output;
  String host;
  int port = 7890;

  public int boardNum;
  public int channelNum; 
  public byte[] packetData;

  private final int[] pointIndices;

  CortexOutput(LX lx, String _host, int _boardNum, int[] _pointIndices) {
    super(lx);
    this.host = _host;
    this.boardNum = _boardNum;
    this.pointIndices = _pointIndices;
    this.socket = null;
    this.output = null;
    enabled.setValue(true);

    cortexList.add(this);

    int dataLength = BYTES_PER_PIXEL*nPixPerChannel*nChannelPerBoard;
    this.packetData = new byte[HEADER_LEN + dataLength];
    this.packetData[INDEX_CHANNEL] = 0;
    this.packetData[INDEX_COMMAND] = COMMAND_SET_PIXEL_COLORS;
    this.packetData[INDEX_DATA_LEN_MSB] = (byte)(dataLength >>> 8);
    this.packetData[INDEX_DATA_LEN_LSB] = (byte)(dataLength & 0xFF);

    this.connect();

  }


  public boolean isConnected() {
    return (this.output != null);
  }

  private void connect() {
    // if (this.socket == null) {
    if (this.output == null) {
      try {https://docs.google.com/document/d/1dLYE5T73vIV1aaOHn3hhgKB0X57BxKOBDICkeJl_48o/edit#
        this.socket = new Socket();
        this.socket.connect(new InetSocketAddress(this.host, this.port), 100);
        // this.socket.setTcpNoDelay(true); // disable on SugarCubes
        this.output = this.socket.getOutputStream();
        didConnect();
      } 
      catch (ConnectException cx) { 
        dispose(cx);
      } 
      catch (IOException iox) { 
        dispose(iox);
      }
    }
  }

  protected void didConnect() {
//    println("Connected to OPC server: " + host + " for channel " + channelNum);
  }
  
  protected void closeChannel() {
    try {
      this.output.close();
      this.socket.close();
    }
    catch (IOException e) {
      println("tried closing a channel and fucked up");
    }    
  }
  
  public void dispose() {
    if (output != null) {
      closeChannel();
    }
    this.socket = null;
    this.output = null;
  }

  protected void dispose(Exception x) {
    if (output != null)  println("Disconnected from OPC server");
    this.socket = null;
    this.output = null;
    didDispose(x);
  }

  protected void didDispose(Exception x) {
//    println("Failed to connect to OPC server " + host);
//    println("disposed");
  }

  // @Override
  protected void onSend(int[] colors) {
    if (packetData == null || packetData.length == 0) return;
    float hsb[] = new float[3];

    for(int i=0; i<colors.length; i++){
      // TODO MJP: this might not work as expected, if we are dimming the global color array for each datagram that is sent
      LXColor.RGBtoHSB(colors[i], hsb);
      float b = hsb[2];
      colors[i] = lx.hsb(360.*hsb[0], 100.*hsb[1], 100*(b*(float)GLOBAL_BRIGHTNESS));
    }

    //connect();
    
    if (isConnected()) {
      try {
        this.output.write(getPacketData(colors));
      } 
      catch (IOException iox) {
        dispose(iox);
      }
    }
    
  }

  // @Override
  protected byte[] getPacketData(int[] colors) {
    //System.out.format(" ---- Packet Pixels: %8d", colors.length);
    for (int i = 0; i < this.pointIndices.length; ++i) {
      int dataOffset = INDEX_DATA + i * BYTES_PER_PIXEL;
      int pointIndex = this.pointIndices[i]; 
      int c = colors[pointIndex];
      this.packetData[dataOffset + OFFSET_R] = (byte) (0xFF & (c >> 16));
      this.packetData[dataOffset + OFFSET_G] = (byte) (0xFF & (c >> 8));
      this.packetData[dataOffset + OFFSET_B] = (byte) (0xFF & c);
    }
    // all other values in packetData should be 0 by default
    return this.packetData;
  }
}




////---------------------------------------------------------------------------------------------
//// add UI components for the hardware, allowing enable/disable

//class UIOutput extends UIWindow {
// UIOutput(UI ui, float x, float y, float w, float h) {
//   super(ui, "OUTPUT", x, y, w, h);
//   float yPos = UIWindow.TITLE_LABEL_HEIGHT - 2;
//   List<UIItemList.Item> items = new ArrayList<UIItemList.Item>();
//   items.add(new OutputItem());

//   new UIItemList.BasicList(ui, 1, yPos, width-2, 260)
//   .setItems(items)
//   .addToContainer(this);
// }

// class OutputItem extends UIItemList.AbstractItem {
//   OutputItem() {
//     for (CortexOutput ch : cortexList) {
//       ch.enabled.addListener(new LXParameterListener() {
//         public void onParameterChanged(LXParameter parameter) { 
//           redraw();
//         }
//       }
//       );
//     }
//   } 
//   String getLabel() { 
//     return "ALL CHANNELS";
//   }
//   boolean isSelected() { 
//     // jut check the first one, since they either should all be on or all be off
//     return cortexList.get(0).enabled.isOn();
//   }
//   void onMousePressed() { 
//     for (CortexOutput ch : cortexList) { 
//       ch.enabled.toggle();
//       if (ch.enabled.isOn()) {
//         ch.connect();
//       }
//       else {
////          ch.closeChannel();
//         ch.dispose();
//       }
//     }
//   } // end onMousePressed
// }
  
//}

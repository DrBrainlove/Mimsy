import heronarts.lx.color.*;
import java.awt.Color;

public class LutPalette {

    // a list of 16 colors that can be interpolated out to a 256 color LUT
    private int base_colors[];

    public int lut[] = new int[256];
    public int length;

    /// Approximate "black body radiation" palette
    /// Recommend that you use values 0-240 rather than
    /// the usual 0-255, as the last 15 colors will be
    /// 'wrapping around' from the hot end to the cold end,
    /// which looks wrong.
    final int heat_base_colors[] = new int[]{
        0xFF000000,
        0xFF330000, 0xFF660000, 0xFF990000, 0xFFCC0000, 0xFFFF0000,
        0xFFFF3300, 0xFFFF6600, 0xFFFF9900, 0xFFFFCC00, 0xFFFFFF00,
        0xFFFFFF33, 0xFFFFFF66, 0xFFFFFF99, 0xFFFFFFCC, 0xFFFFFFFF
    };

    // NOTE: can easily make a blue map for this as well
    // TODO: these palette base colors should be put in their own class
    final int blue_heat_base_colors[] = new int[]{
        0xFF000000,
        0xFF000033, 0xFF000066, 0xFF000099, 0xFF0000CC, 0xFF0000FF,
        0xFF0033FF, 0xFF0066FF, 0xFF0099FF, 0xFF00CCFF, 0xFF00FFFF,
        0xFF33FFFF, 0xFF66FFFF, 0xFF99FFFF, 0xFFCCFFFF, 0xFFFFFFFF
    };


    public LutPalette(String lut_name) {
        base_colors = new int[16]; //unused?
        switch(lut_name) {
            case "heat":
                System.out.format("Loading 'heat' lut\n");
                base_colors = heat_base_colors;
                break;
            default:
                System.out.format("No known palette: %s", lut_name);
                break;
        }
        // load the lut from the target base_colors
        load_lut(base_colors);
        length = 256;
    }

    private void load_lut(int base_colors[]) {
        // set up our interpolated palette
        for (int base_ix=0; base_ix<16; base_ix++) {

            // Between two base colors, we iterate over 16 steps
            for (int i=0; i<16; i++) {
                int lut_index = (base_ix * 16) + i;
                lut[lut_index] = LXColor.lerp(
                    base_colors[base_ix],
                    base_colors[(base_ix+1) % 16],
                    (double)(i / 16.0) );
                //System.out.format("set LUT [%d]=0x%08X\n", lut_index, lut[lut_index]);
            }
        }
    }

    // Lookup color int from given value key
    public int get_color(int value) {
        // System.out.format("[%d]=0x%08X\n", value, lut[value]);
        if (value>=lut.length) {
            value = lut.length-1;
            System.out.format("clipping to 255");
        }
        else if (value<0)
            value = 0;

        return lut[value];
    }


}
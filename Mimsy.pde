/*
** The Phage presents
**    Mimsy
**
**        _---~~(~~-_.
**      _{        )   )
**    ,   ) -~~- ( ,-' )_
**   (  `-,_..`., )-- '_,)
**  ( ` _)  (  -~( -_ `,  }
**  (_-  _  ~_-~~~~`,  ,' )
**    `~ -^(    __;-,((()))
**          ~~~~ {_ -_(())
**                 `\  }
**                   { }
**
** Authors:
**   Alex Scouras
**   Alex Maki-Jokela
**   Mike Pesavento
**     + pattern designers
**
** @date: 2015.12.26 DBL2
** @date: 2017.01.15 Mimsy
**/

//****************************************************** USER FRIENDLY GLOBALS

//static final String MIMSY_TYPE = "MiniMim";
static final String MIMSY_TYPE = "ArtCar";

static final double GLOBAL_BRIGHTNESS = 1.0;

static final int UI_LIGHT_HUE        =  0;
static final int UI_LIGHT_SATURATION =  0; // white
static final int UI_LIGHT_BRIGHTNESS = 50; // half bright

//---------------- Mimsy Physical Parameters
static float RADIUS = 1000.0;
//static float RADIUS = 144.0;
static int DODECAHEDRON_BAR_THICKNESS = 10;
static int TETRAHEDRON_BAR_THICKNESS =  5;

static int BAR_DETAIL =  5;
static int BAR_RADIUS = 10;

//---------------- Which Components to Draw
static boolean DRAW_DODECAHEDRON = true;
static boolean DRAW_TETRA_LEFT   = true;
static boolean DRAW_TETRA_RIGHT  = true;
static boolean DRAW_FRABJOUS     = false; // not implemented
static boolean DRAW_CUBIC        = false; // not implemented


//---------------- Output Hardware
//String OUTPUT = "BeagleBone";
//String OUTPUT = null;
static boolean OUTPUT = true;
//static boolean OUTPUT = false;



//---------------- Symmetry Validation
boolean TEST_SYMMETRY = false;
SymmetryTest symTest;

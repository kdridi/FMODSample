#import "common.h"
#import <Foundation/NSString.h>
#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioSession.h>

const Common_Button BTN_IDS[] = {BTN_ACTION1, BTN_UP, BTN_ACTION2, BTN_LEFT, BTN_MORE, BTN_RIGHT, BTN_ACTION3, BTN_DOWN, BTN_ACTION4};
const unsigned int BTN_COUNT = sizeof(BTN_IDS) / sizeof(BTN_IDS[0]);
const unsigned int BTN_COUNT_PER_ROW = 3;

@interface ViewController : UIViewController
    @property (strong, nonatomic) UILabel *textDisplay;
@end

@interface AppDelegate : UIResponder <UIApplicationDelegate>
    @property (strong, nonatomic) UIWindow *window;
    @property (strong, nonatomic) ViewController *viewController;
@end

NSMutableString *gOutputBuffer;
uint32_t gButtons;
uint32_t gButtonsDown;
uint32_t gButtonsPress;
bool gSuspendState;

void interruptionListenerCallback(void *inUserData, UInt32 interruptionState)
{
    if (interruptionState == kAudioSessionBeginInterruption)
    {
        gSuspendState = true;
    }
    else if (interruptionState == kAudioSessionEndInterruption)
    {
        UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
        AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
        AudioSessionSetActive(true);

        gSuspendState = false;
    }
}

void Common_Init(void **extraDriverData)
{
    gSuspendState = false;
    gOutputBuffer = [NSMutableString stringWithCapacity:(NUM_COLUMNS * NUM_ROWS)];

    AudioSessionInitialize(NULL, NULL, interruptionListenerCallback, NULL);
}

void Common_Close()
{

}

void Common_Update()
{
    ViewController *controller = (ViewController *)[[[UIApplication sharedApplication] keyWindow] rootViewController];
    [controller performSelectorOnMainThread:@selector(update) withObject:nil waitUntilDone:YES];
}

void Common_Sleep(unsigned int ms)
{
    [NSThread sleepForTimeInterval:(ms / 1000.0f)];
}

void Common_Exit(int returnCode)
{
    exit(-1);
}

void Common_DrawText(const char *text)
{   
    [gOutputBuffer appendFormat:@"%s\n", text];
}

bool Common_BtnPress(Common_Button btn)
{
    return ((gButtonsPress & (1 << btn)) != 0);
}

bool Common_BtnDown(Common_Button btn)
{
    return ((gButtonsDown & (1 << btn)) != 0);
}

const char *Common_BtnStr(Common_Button btn)
{
    switch (btn)
    {
        case BTN_ACTION1: return "A";
        case BTN_ACTION2: return "B";
        case BTN_ACTION3: return "C";
        case BTN_ACTION4: return "D";
        case BTN_UP:      return "Up";
        case BTN_DOWN:    return "Down";
        case BTN_LEFT:    return "Left";
        case BTN_RIGHT:   return "Right";
        case BTN_MORE:    return "E";
        case BTN_QUIT:    return "Home";
    }
}

const char *Common_MediaPath(const char *fileName)
{
    return [[NSString stringWithFormat:@"%@/media/%s", [[NSBundle mainBundle] resourcePath], fileName] UTF8String];
}

void Common_LoadFileMemory(const char *name, void **buff, int *length)
{
    FILE *file = fopen(name, "rb");

    fseek(file, 0, SEEK_END);
    long len = ftell(file);
    fseek(file, 0, SEEK_SET);

    void *mem = malloc(len);
    fread(mem, 1, len, file);

    fclose(file);

    *buff = mem;
    *length = len;
}

void Common_UnloadFileMemory(void *buff)
{
    free(buff);
}

bool Common_SuspendState()
{
    return gSuspendState;
}


@implementation ViewController
- (void)viewDidLoad
{
    [super viewDidLoad];

    const CGRect appFrame = [[UIScreen mainScreen] applicationFrame];

    self.textDisplay = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, appFrame.size.width, appFrame.size.height)] autorelease];
    [self.textDisplay setNumberOfLines:0];
    [self.textDisplay setBackgroundColor:[UIColor blackColor]];
    [self.textDisplay setTextColor:[UIColor whiteColor]];
    [self.textDisplay setFont:[UIFont fontWithName:@"CourierNewPS-BoldMT" size:10]];

    [self.view addSubview:self.textDisplay];

    for (unsigned int i = 0; i < BTN_COUNT; i++)
    {
        const float BTN_SPACER = 2;
        const float BTN_WIDTH = (appFrame.size.width - ((BTN_COUNT_PER_ROW - 1) * BTN_SPACER)) / BTN_COUNT_PER_ROW;
        const float BTN_HEIGHT = 42; // iOS human interface guidelines minimum tappable size is 44x44
        const float BTN_X = (i % BTN_COUNT_PER_ROW) * (BTN_WIDTH + BTN_SPACER);
        const float BTN_Y = appFrame.size.height - (((BTN_COUNT / BTN_COUNT_PER_ROW) - (i / BTN_COUNT_PER_ROW)) * (BTN_HEIGHT + BTN_SPACER));

        UIButton *button = [[[UIButton alloc] initWithFrame:CGRectMake(BTN_X, BTN_Y, BTN_WIDTH, BTN_HEIGHT)] autorelease];
        [button setTitle:[NSString stringWithUTF8String:Common_BtnStr(BTN_IDS[i])] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor colorWithRed:134.0f/255.0f green:145.0f/255.0f blue:158.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor colorWithRed:207.0f/255.0f green:188.0f/255.0f blue:105.0f/255.0f alpha:1.0f] forState:UIControlStateHighlighted];
        [button setBackgroundColor:[UIColor colorWithRed:64.0f/255.0f green:85.0f/255.0f blue:90.0f/255.0f alpha:1.0f]];
        [button setTag:BTN_IDS[i]];
        [button addTarget:self action:@selector(buttonDown:) forControlEvents:UIControlEventTouchDown];
        [button addTarget:self action:@selector(buttonUp:) forControlEvents:UIControlEventTouchUpInside];
        [button.titleLabel setFont:[UIFont boldSystemFontOfSize:12]];
        
        [self.view addSubview:button];
    }

    [self performSelectorInBackground:@selector(threadMain:) withObject:nil];
}

- (void)dealloc
{
    [_textDisplay release];
    [super dealloc];
}

- (void)update
{
    [self.textDisplay setText:gOutputBuffer];
    [self.textDisplay sizeToFit];
    [gOutputBuffer setString:@""];

    gButtonsPress = (gButtonsDown ^ gButtons) & gButtons;
    gButtonsDown = gButtons;
}

int FMOD_Main();
- (void)threadMain:(id)arg
{
    @autoreleasepool
    {
        FMOD_Main();
    }
}

- (void)buttonDown:(id)sender
{
    gButtons |= (1 << [sender tag]);
}

- (void)buttonUp:(id)sender
{
    gButtons &= ~(1 << [sender tag]);
}
@end


@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    self.viewController = [[[ViewController alloc] init] autorelease];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];

    return YES;
}

- (void)dealloc
{
    [_window release];
    [_viewController release];
    [super dealloc];
}
@end


int main(int argc, char *argv[])
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}

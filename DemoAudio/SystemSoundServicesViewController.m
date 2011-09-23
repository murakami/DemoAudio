//
//  SystemSoundServicesViewController.m
//  DemoAudio
//
//  Created by 村上 幸雄 on 11/09/20.
//  Copyright 2011年 ビッツ有限会社. All rights reserved.
//

#import "SystemSoundServicesViewController.h"

static void MyAudioServicesSystemSoundCompletionProc(SystemSoundID ssID, void *clientData)
{
    DBGMSG(@"%s", __func__);
    SystemSoundServicesViewController   *systemSoundServicesViewController
        = (SystemSoundServicesViewController *)clientData;
    if (systemSoundServicesViewController.loopSwitch.on) {
        AudioServicesPlaySystemSound(systemSoundServicesViewController.systemSoundID);
    }
    else {
        systemSoundServicesViewController.isPlay = NO;
    }
}

@interface SystemSoundServicesViewController ()
@end

@implementation SystemSoundServicesViewController

@synthesize isPlay = __isPlay;
@synthesize systemSoundID = __systemSoundID;
@synthesize loopSwitch = __loopSwitch;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    DBGMSG(@"%s", __func__);
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.isPlay = NO;
        self.systemSoundID = 0;
    }
    return self;
}

- (void)dealloc
{
    self.isPlay = NO;
    self.systemSoundID = 0;
    self.loopSwitch = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    DBGMSG(@"%s", __func__);
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    DBGMSG(@"%s", __func__);
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    NSString    *path = [[NSBundle mainBundle] pathForResource:@"StarTrek-intercom" ofType:@"aif"];
    NSURL       *fileURL = [NSURL fileURLWithPath:path];
    AudioServicesCreateSystemSoundID((CFURLRef)fileURL, &__systemSoundID);
    AudioServicesAddSystemSoundCompletion(self.systemSoundID,
                                          NULL,
                                          NULL,
                                          MyAudioServicesSystemSoundCompletionProc,
                                          self);
    [self.loopSwitch setOn:NO animated:NO];
}

- (void)viewDidUnload
{
    DBGMSG(@"%s", __func__);
    self.isPlay = NO;
    AudioServicesDisposeSystemSoundID(__systemSoundID);
    self.systemSoundID = 0;
    self.loopSwitch = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)play:(id)sender
{
    DBGMSG(@"%s, %@", __func__, sender);
    if (self.isPlay)    return;
    self.isPlay = YES;
    AudioServicesPlaySystemSound(self.systemSoundID);
}

@end

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
}

@interface SystemSoundServicesViewController ()
@end

@implementation SystemSoundServicesViewController

@synthesize systemSoundID;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    NSString    *path = [[NSBundle mainBundle] pathForResource:@"tap" ofType:@"aif"];
    NSURL       *fileURL = [NSURL fileURLWithPath:path];
    AudioServicesCreateSystemSoundID((CFURLRef)fileURL, &systemSoundID);
    AudioServicesAddSystemSoundCompletion(self.systemSoundID,
                                          NULL,
                                          NULL,
                                          MyAudioServicesSystemSoundCompletionProc,
                                          NULL);
}

- (void)viewDidUnload
{
    AudioServicesDisposeSystemSoundID(systemSoundID);
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
    DBGMSG(@"%s", __func__);
    AudioServicesPlaySystemSound(self.systemSoundID);
}

@end

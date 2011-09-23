//
//  AVFoundationViewController.m
//  DemoAudio
//
//  Created by 村上 幸雄 on 11/09/20.
//  Copyright 2011年 ビッツ有限会社. All rights reserved.
//

#import "AVFoundationViewController.h"

@interface AVFoundationViewController ()
@end

@implementation AVFoundationViewController

@synthesize recordingURL = _recordingURL;
@synthesize recorder = _recorder;
@synthesize player = _player;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    DBGMSG(@"%s", __func__);
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    self.recordingURL = nil;
    self.recorder.delegate = nil;
    self.recorder = nil;
    self.player.delegate = nil;
    self.player = nil;
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
    
    NSArray     *filePaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString    *documentDir = [filePaths objectAtIndex:0];
    NSString    *path = [documentDir stringByAppendingPathComponent:@"demoaudio.caf"];
    self.recordingURL = [NSURL fileURLWithPath:path];
 
    NSError     *error = nil;
    _recorder = [[AVAudioRecorder alloc] initWithURL:self.recordingURL settings:nil error:&error];
    if (error) {
        DBGMSG(@"recorder error = %@", error);
    }
    self.recorder.delegate = self;

    error = nil;
    _player = [[AVAudioPlayer alloc] initWithContentsOfURL:self.recordingURL error:&error];
    if (error) {
        DBGMSG(@"player error = %@", error);
    }
    self.player.delegate = self;
}

- (void)viewDidUnload
{
    DBGMSG(@"%s", __func__);
    
    self.recordingURL = nil;
    self.recorder.delegate = nil;
    self.recorder = nil;
    self.player.delegate = nil;
    self.player = nil;
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)record:(id)sender
{
    [self.recorder recordForDuration:4.0];
}

- (IBAction)play:(id)sender
{
    [self.player play];
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    DBGMSG(@"%s", __func__);
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    DBGMSG(@"%s", __func__);
}

@end
